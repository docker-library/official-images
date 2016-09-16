# Docker Official Images

[![Build Status](https://travis-ci.org/docker-library/official-images.svg?branch=master)](https://travis-ci.org/docker-library/official-images)

## Architectures other than amd64?

Work is in-progress in the Docker Engine and Registry to properly support multiple architectures (see [docker/docker#15866](https://github.com/docker/docker/issues/15866)). While this work is ongoing, **temporary**, experimental builds of the official images for the following architectures are happening somewhat incrementally (with a strong bias towards images necessary for Docker's own CI to help hasten proper multiarch support upstream) via CI.

-	ARMv5 (`armel`): https://hub.docker.com/u/armel/
-	ARMv7 (`armhf`): https://hub.docker.com/u/armhf/
-	ARMv8 (`arm64`): https://hub.docker.com/u/aarch64/
-	POWER8 (`ppc64le`): https://hub.docker.com/u/ppc64le/
-	System z (`s390x`): https://hub.docker.com/u/s390x/
-	x86/i686 (`i386`): https://hub.docker.com/u/i386/

If you are curious about how these images are built or have issues with them, please direct all comments to [issues on the `tianon/jenkins-groovy` repo](https://github.com/tianon/jenkins-groovy/issues) for now.

## Contributing to the standard library

Thank you for your interest in the Docker official images project! We strive to make these instructions as simple and straightforward as possible, but if you find yourself lost, don't hesitate to seek us out on Freenode IRC in channel `#docker-library` or by creating a GitHub issue here.

Be sure to familiarize yourself with [Official Repositories on Docker Hub](https://docs.docker.com/docker-hub/official_repos/) and the [Best practices for writing Dockerfiles](https://docs.docker.com/articles/dockerfile_best-practices/) in the Docker documentation. These will be the foundation of the review process performed by the official images maintainers. If you'd like the review process to go more smoothly, please ensure that your `Dockerfile`s adhere to all the points mentioned there, as well as [below](README.md#review-guidelines), before submitting a pull request.

Also, the Hub descriptions for these images are currently stored separately in the [`docker-library/docs` repository](https://github.com/docker-library/docs), whose [`README.md` file](https://github.com/docker-library/docs/blob/master/README.md) explains more about how it's structured and how to contribute to it. Please be prepared to submit a PR there as well, pending acceptance of your image here.

### Review Guidelines

Because the official images are intended to be learning tools for those new to Docker as well as the base images for advanced users to build their production releases, we review each proposed `Dockerfile` to ensure that it meets a minimum standard for quality and maintainability. While some of that standard is hard to define (due to subjectivity), as much as possible is defined here, while also adhering to the "Best Practices" where appropriate.

A checklist which may be used by the maintainers during review can be found in [`NEW-IMAGE-CHECKLIST.md`](NEW-IMAGE-CHECKLIST.md).

#### Maintainership

Version bumps and security fixes should be attended to in a timely manner.

If you do not represent upstream and upstream becomes interested in maintaining the image, steps should be taken to ensure a smooth transition of image maintainership over to upstream.

For upstreams interested in taking over maintainership of an existing repository, the first step is to get involved in the existing repository. Making comments on issues, proposing changes, and making yourself known within the "image community" (even if that "community" is just the current maintainer) are all important places to start to ensure that the transition is unsurprising to existing contributors and users.

When taking over an existing repository, please ensure that the entire Git history of the original repository is kept in the new upstream-maintained repository to make sure the review process isn't stalled during the transition. This is most easily accomplished by forking the new from the existing repository, but can also be accomplished by fetching the commits directly from the original and pushing them into the new repo (ie, `git fetch https://github.com/jsmith/example.git master`, `git rebase FETCH_HEAD`, `git push -f`). On github, an alternative is to move ownership of the git repository. This can be accomplished without giving either group admin access to the other owner's repository:

-	create temporary intermediary organization
	-	[docker-library-transitioner](https://github.com/docker-library-transitioner) is available for this purpose if you would like our help
-	give old and new owners admin access to intermediary organization
-	old owner transfers repo ownership to intermediary organization
-	new owner transfers repo ownership to its new home
	-	recommend that old owner does not fork new repo back into the old organization to ensure that github redirects will just work

#### Repeatability

Rebuilding the same `Dockerfile` should result in the same version of the image being packaged, even if the second build happens several versions later, or the build should fail outright, such that an inadvertent rebuild of a `Dockerfile` tagged as `0.1.0` doesn't end up containing `0.2.3`. For example, if using `apt` to install the main program for the image, be sure to pin it to a specific version (ex: `... apt-get install -y my-package=0.1.0 ...`). For dependent packages installed by `apt` there is not usually a need to pin them to a version.

No official images can be derived from, or depend on, non-official images with the following notable exceptions:

-	[`FROM scratch`](https://hub.docker.com/_/scratch/)
-	[`FROM microsoft/windowsservercore`](https://hub.docker.com/r/microsoft/windowsservercore/)
-	[`FROM microsoft/nanoserver`](https://hub.docker.com/r/microsoft/nanoserver/)

#### Consistency

All official images should provide a consistent interface. A beginning user should be able to `docker run official-image bash` without needing to learn about `--entrypoint`. It is also nice for advanced users to take advantage of entrypoint, so that they can `docker run official-image --arg1 --arg2` without having to specify the binary to execute.

1.	If the startup process does not need arguments, just use `CMD`:

	```Dockerfile
	CMD ["irb"]
	```

2.	If there is initialization that needs to be done on start, like creating the initial database, use an `ENTRYPOINT` along with `CMD`:

	```Dockerfile
	ENTRYPOINT ["/docker-entrypoint.sh"]
	CMD ["postgres"]
	```

	1.	Ensure that `docker run official-image bash` works too. The easiest way is to check for the expected command and if it is something else, just `exec "$@"` (run whatever was passed, properly keeping the arguments escaped).

		```bash
		#!/bin/bash
		set -e

		# this if will check if the first argument is a flag
		# but only works if all arguments require a hyphenated flag
		# -v; -SL; -f arg; etc will work, but not arg1 arg2
		if [ "${1:0:1}" = '-' ]; then
		    set -- mongod "$@"
		fi

		# check for the expected command
		if [ "$1" = 'mongod' ]; then
		    # init db stuff....
		    # use gosu to drop to a non-root user
		    exec gosu mongod "$@"
		fi

		# else default to run whatever the user wanted like "bash"
		exec "$@"
		```

3.	If the image only contains the main executable and its linked libraries (ie no shell) then it is fine to use the executable as the `ENTRYPOINT`, since that is the only thing that can run:

	```Dockerfile
	ENTRYPOINT ["swarm"]
	CMD ["--help"]
	```

	The most common indicator of whether this is appropriate is that the image `Dockerfile` starts with [`scratch`](https://registry.hub.docker.com/_/scratch/) (`FROM scratch`).

#### Clarity

Try to make the `Dockerfile` easy to understand/read. It may be tempting, for the sake of brevity, to put complicated initialization details into a standalone script and merely add a `RUN` command in the `Dockerfile`. However, this causes the resulting `Dockerfile` to be overly opaque, and such `Dockerfile`s are unlikely to pass review. Instead, it it recommended to put all the commands for initialization into the `Dockerfile` as appropriate `RUN` or `ENV` command combinations. To find good examples, look at the current official images.

Some examples at the time of writing:

-	[php](https://github.com/docker-library/php/blob/b4aeb948e2e240c732d78890ff03285b16e8edda/5.6/Dockerfile)
-	[python](https://github.com/docker-library/python/blob/3e5826ad0c6e29f07f6dc7ff8f30b4c54385d1bb/3.4/Dockerfile)
-	[ruby:2.2](https://github.com/docker-library/ruby/blob/e34b201a0f0b49818fc8373f6a9148e13d546bdf/2.2/Dockerfile)

#### init

Following the Docker guidelines it is highly recommended that the resulting image be just one concern per container; predominantly this means just one process per container, so there is no need for a full init system. There are two situations where an init-like process would be helpful for the container. The first being signal handling. If the process launched does not handle `SIGTERM` by exiting, it will not be killed since it is PID 1 in the container (see "NOTE" at the end of the [Foreground section](https://docs.docker.com/reference/run/#foreground) in the docker docs). The second situation would be zombie reaping. If the process spawns child processes and does not properly reap them it will lead to a full process table, which can prevent the whole system from spawning any new processes. For both of these concerns we recommend [tini](https://github.com/krallin/tini). It is incredibly small, has minimal external dependencies, fills each of these roles, and does only the necessary parts of reaping and signal forwarding.

Here is a snippet of a Dockerfile to add in tini (be sure to use it in `CMD` or `ENTRYPOINT` as appropriate):

```Dockerfile
# grab tini for signal processing and zombie killing
ENV TINI_VERSION v0.9.0
RUN set -x \
	&& curl -fSL "https://github.com/krallin/tini/releases/download/$TINI_VERSION/tini" -o /usr/local/bin/tini \
	&& curl -fSL "https://github.com/krallin/tini/releases/download/$TINI_VERSION/tini.asc" -o /usr/local/bin/tini.asc \
	&& export GNUPGHOME="$(mktemp -d)" \
	&& gpg --keyserver ha.pool.sks-keyservers.net --recv-keys 6380DC428747F6C393FEACA59A84159D7001A4E5 \
	&& gpg --batch --verify /usr/local/bin/tini.asc /usr/local/bin/tini \
	&& rm -r "$GNUPGHOME" /usr/local/bin/tini.asc \
	&& chmod +x /usr/local/bin/tini \
	&& tini -h
```

#### Cacheability

This is one place that experience ends up trumping documentation for the path to enlightenment, but the following tips might help:

-	Avoid `COPY`/`ADD` whenever possible, but when necessary, be as specific as possible (ie, `COPY one-file.sh /somewhere/` instead of `COPY . /somewhere`).

	The reason for this is that the cache for `COPY` instructions considers file `mtime` changes to be a cache bust, which can make the cache behavior of `COPY` unpredictable sometimes, especially when `.git` is part of what needs to be `COPY`ed (for example).

-	Ensure that lines which are less likely to change come before lines that are more likely to change (with the caveat that each line should generate an image that still runs successfully without assumptions of later lines).

	For example, the line that contains the software version number (`ENV MYSOFTWARE_VERSION 4.2`) should come after a line that sets up the APT repository `.list` file (`RUN echo 'deb http://example.com/mysoftware/debian some-suite main' > /etc/apt/sources.list.d/mysoftware.list`).

#### Security

##### Image Build

The `Dockerfile` should be written to help mitigate man-in-the-middle attacks during build: using https where possible; importing PGP keys with the full fingerprint in the Dockerfile to check package signing; embedding checksums directly in the `Dockerfile` if PGP signing is not provided. When importing PGP keys, we recommend using the [high-availability server pool](https://sks-keyservers.net/overview-of-pools.php#pool_ha) from sks-keyservers (`ha.pool.sks-keyservers.net`). Here are a few good and bad examples:

-	**Bad**: *download the file over http with no verification.*

	```Dockerfile
	RUN curl -fSL "http://julialang.s3.amazonaws.com/bin/linux/x64/${JULIA_VERSION%[.-]*}/julia-${JULIA_VERSION}-linux-x86_64.tar.gz" | tar ... \
	    # install
	```

-	**Good**: *download the file over https, but still no verification.*

	```Dockerfile
	RUN curl -fSL "https://julialang.s3.amazonaws.com/bin/linux/x64/${JULIA_VERSION%[.-]*}/julia-${JULIA_VERSION}-linux-x86_64.tar.gz" | tar ... \
	    # install
	```

-	**Better**: *embed the checksum into the Dockerfile. It would be better to use https here too, if it is available.*

	```Dockerfile
	ENV RUBY_DOWNLOAD_SHA256 5ffc0f317e429e6b29d4a98ac521c3ce65481bfd22a8cf845fa02a7b113d9b44
	RUN curl -fSL -o ruby.tar.gz "http://cache.ruby-lang.org/pub/ruby/$RUBY_MAJOR/ruby-$RUBY_VERSION.tar.gz" \
	    && echo "$RUBY_DOWNLOAD_SHA256 *ruby.tar.gz" | sha256sum -c - \
	    # install
	```

-	**Best**: *full key fingerprint imported to apt-key which will check signatures when packages are downloaded and installed.*

	```Dockerfile
	RUN apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys 492EAFE8CD016A07919F1D2B9ECBEC467F0CEB10
	RUN echo "deb http://repo.mongodb.org/apt/debian wheezy/mongodb-org/$MONGO_MAJOR main" > /etc/apt/sources.list.d/mongodb-org.list
	RUN apt-get update \
	    && apt-get install -y mongodb-org=$MONGO_VERSION \
	    && rm -rf /var/lib/apt/lists/* \
	    # ...
	```

	(As a side note, `rm -rf /var/lib/apt/lists/*` is *roughly* the opposite of `apt-get update` -- it ensures that the layer doesn't include the extra ~8MB of APT package list data, and enforces [appropriate `apt-get update` usage](https://docs.docker.com/engine/articles/dockerfile_best-practices/#apt-get).)

-	**Alternate Best**: *full key fingerprint import, download over https, verify PGP signature of download.*

	```Dockerfile
	# gpg: key F73C700D: public key "Larry Hastings <larry@hastings.org>" imported
	RUN curl -fSL "https://www.python.org/ftp/python/$PYTHON_VERSION/Python-$PYTHON_VERSION.tar.xz" -o python.tar.xz \
	    && curl -fSL "https://www.python.org/ftp/python/$PYTHON_VERSION/Python-$PYTHON_VERSION.tar.xz.asc" -o python.tar.xz.asc \
	    && export GNUPGHOME="$(mktemp -d)" \
	    && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys 97FC712E4C024BBEA48A61ED3A5CA953F73C700D \
	    && gpg --batch --verify python.tar.xz.asc python.tar.xz \
	    && rm -r "$GNUPGHOME" python.tar.xz.asc \
	    # install
	```

##### Runtime Configuration

By default, Docker containers are executed with reduced privileges: whitelisted Linux capabilities, Control Groups, and a default Seccomp profile (1.10+ w/ host support). Software running in a container may require additional privileges in order to function correctly, and there are a number of command line options to customize container execution. See [`docker run` Reference](https://docs.docker.com/engine/reference/run/) and [Seccomp for Docker](https://docs.docker.com/engine/security/seccomp/) for reference.

Official Repositories that require additional privileges should specify the minimal set of command line options for the software to function, and may still be rejected if this introduces significant portability or security issues. In general, `--privileged` is not allowed, but a combination of `--cap-add` and `--device` options may be acceptable. Additionally, `--volume` can be tricky as there are many host filesystem locations that introduce portability/security issues (i.e. X11 socket).

### Commitment

Proposing a new official image should not be undertaken lightly. We expect and require a commitment to maintain your image (including and especially timely updates as appropriate, as noted above).

## Library definition files

The library definition files are plain text files found in the [`library/` directory of the `official-images` repository](https://github.com/docker-library/official-images/tree/master/library). Each library file controls the current "supported" set of image tags that appear on the Docker Hub description. Tags that are removed from a library file do not get removed from the Docker Hub, so that old versions can continue to be available for use, but are not maintained by upstream or the maintainer of the official image. Tags in the library file are only built through an update to that library file or as a result of its base image being updated (ie, an image `FROM debian:jessie` would be rebuilt when `debian:jessie` is built). Only what is in the library file will be rebuilt when a base has updates.

Given this policy, it is worth clarifying a few cases: backfilled versions, release candidates, and continuous integration builds. When a new repository is proposed, it is common to include some older unsupported versions in the initial pull request with the agreement to remove them right after acceptance. Don't confuse this with a comprehensive historical archive which is not the intention. Another common case where the term "supported" is stretched a bit is with release candidates. A release candidate is really just a naming convention for what are expected to be shorter-lived releases, so they are totally acceptable and encouraged. Unlike a release candidate, continuous integration builds which have a fully automated release cycle based on code commits or a regular schedule are not appropriate.

It is highly recommended that you browse some of the existing `library/` file contents (and history to get a feel for how they change over time) before creating a new one to become familiar with the prevailing conventions and further help streamline the review process (so that we can focus on content instead of esoteric formatting or tag usage/naming).

### Filenames

The filename of a definition file will determine the name of the image repository it creates on the Docker Hub. For example, the `library/ubuntu` file will create tags in the `ubuntu` repository.

### Tags and aliases

The tags of a repository should reflect upstream's versions or variations. For example, Ubuntu 14.04 is also known as Ubuntu Trusty Tahr, but often as simply Ubuntu Trusty (especially in usage), so `ubuntu:14.04` (version number) and `ubuntu:trusty` (version name) are appropriate aliases for the same image contents. In Docker, the `latest` tag is a special case, but it's a bit of a misnomer; `latest` really is the "default" tag. When one does `docker run xyz`, Docker interprets that to mean `docker run xyz:latest`. Given that background, no other tag ever contains the string `latest`, since it's not something users are expected or encouraged to actually type out (ie, `xyz:latest` should really be used as simply `xyz`). Put another way, having an alias for the "highest 2.2-series release of XYZ" should be `xyz:2.2`, not `xyz:2.2-latest`. Similarly, if there is an Alpine variant of `xyz:latest`, it should be aliased as `xyz:alpine`, not `xyz:alpine-latest` or `xyz:latest-alpine`.

It is strongly encouraged that version number tags be given aliases which make it easy for the user to stay on the "most recent" release of a particular series. For example, given currently supported XYZ Software versions of 2.3.7 and 2.2.4, suggested aliases would be `Tags: 2.3.7, 2.3, 2, latest` and `Tags: 2.2.4, 2.2`, respectively. In this example, the user can use `xyz:2.2` to easily use the most recent patch release of the 2.2 series, or `xyz:2` if less granularity is needed (Python is a good example of where that's most obviously useful -- `python:2` and `python:3` are very different, and can be thought of as the `latest` tag for each of the major release tracks of Python).

As described above, `latest` is really "default", so the image that it is an alias for should reflect which version or variation of the software users should use if they do not know or do not care which version they use. Using Ubuntu as an example, `ubuntu:latest` points to the most recent LTS release, given that it is what the majority of users should be using if they know they want Ubuntu but do not know or care which version (especially considering it will be the most "stable" and well-supported release at any given time).

### Instruction format

The manifest file format is officially based on [RFC 2822](https://www.ietf.org/rfc/rfc2822.txt), and as such should be familiar to folks who are already familiar with the "headers" of many popular internet protocols/formats such as HTTP or email.

The primary additions are inspired by the way Debian commonly uses 2822 -- namely, lines starting with `#` are ignored and "paragraphs" (or "entries") are separated by a blank line.

The first entry is the "global" metadata for the image. The only required field in the global entry is `Maintainers`, whose value is comma-separated in the format of `Name <email> (@github)` or `Name (@github)`. Any field specified in the global entry will be the default for the rest of the entries/paragraphs and can be overridden in an individual paragraph.

	# this is a comment and will be ignored
	Maintainers: John Smith <jsmith@example.com> (@example-jsmith),
	             Anne Smith <asmith@example.com> (@example-asmith)
	GitRepo: https://github.com/docker-library/wordpress.git
	
	# this is also a comment, and will also be ignored
	
	Tags: 4.1.1, 4.1, 4, latest
	GitCommit: bbef6075afa043cbfe791b8de185105065c02c01
	
	Tags: 2.6.17, 2.6
	GitRepo: https://github.com/docker-library/redis.git
	GitCommit: 062335e0a8d20cab2041f25dfff2fbaf58544471
	Directory: 2.6
	
	Tags: 13.2, harlequin
	GitRepo: https://github.com/openSUSE/docker-containers-build.git
	GitFetch: refs/heads/openSUSE-13.1
	GitCommit: 0d21bc58cd26da2a0a59588affc506b977d6a846
	Directory: docker
	Constraints: !aufs
	Maintainers: Bob Smith (@example-bsmith)

Bashbrew will fetch code out of the Git repository (`GitRepo`) at the commit specified (`GitCommit`). If the commit referenced is not available by fetching `master` of the associated `GitRepo`, it becomes necessary to supply a value for `GitFetch` in order to tell Bashbrew what ref to fetch in order to get the commit necessary.

The built image will be tagged as `<manifest-filename>:<tag>` (ie, `library/golang` with a `Tags` value of `1.6, 1, latest` will create tags of `golang:1.6`, `golang:1`, and `golang:latest`).

Optionally, if `Directory` is present, Bashbrew will look for the `Dockerfile` inside the specified subdirectory instead of at the root (and `Directory` will be used as the ["context" for the build](https://docs.docker.com/reference/builder/) instead of the top-level of the repository).

#### Deprecated format

This is the older, now-deprecated format for library manifest files. Its usage is discouraged (although it is still supported).

	# maintainer: Your Name <your@email.com> (@github.name)
	
	# maintainer: John Smith <jsmith@example.com> (@example-jsmith)
	# maintainer: Anne Smith <asmith@example.com> (@example-asmith)
	
	
	<Tag>: <GitRepo>@<GitCommit>
	
	4.1.1: git://github.com/docker-library/wordpress@bbef6075afa043cbfe791b8de185105065c02c01
	4.1: git://github.com/docker-library/wordpress@bbef6075afa043cbfe791b8de185105065c02c01
	4: git://github.com/docker-library/wordpress@bbef6075afa043cbfe791b8de185105065c02c01
	latest: git://github.com/docker-library/wordpress@bbef6075afa043cbfe791b8de185105065c02c01
	
	
	<Tag>: <GitRepo>@<GitCommit> <Directory>
	
	2.6.17: git://github.com/docker-library/redis@062335e0a8d20cab2041f25dfff2fbaf58544471 2.6
	2.6: git://github.com/docker-library/redis@062335e0a8d20cab2041f25dfff2fbaf58544471 2.6
	
	2.8.19: git://github.com/docker-library/redis@062335e0a8d20cab2041f25dfff2fbaf58544471 2.8
	2.8: git://github.com/docker-library/redis@062335e0a8d20cab2041f25dfff2fbaf58544471 2.8
	2: git://github.com/docker-library/redis@062335e0a8d20cab2041f25dfff2fbaf58544471 2.8
	latest: git://github.com/docker-library/redis@062335e0a8d20cab2041f25dfff2fbaf58544471 2.8
	
	experimental: git://github.com/tianon/dockerfiles@90d86ad63c4a06b7d04d14ad830381b876183b3c debian/experimental

Using Git tags instead of explicit Git commit references is supported for the deprecated format only, but is heavily discouraged. For example, if a Git tag is changed on the referenced repository to point to another commit, **the image will not be rebuilt**. Instead, either create a new tag (or reference an exact commit) and submit a pull request.

### Creating a new repository

-	Create a new file in the `library/` folder. Its name will be the name of your repository on the Hub.
-	Add your tag definitions using the appropriate syntax (see above).
-	Create a pull request adding the file from your forked repository to this one. Please be sure to add details as to what your repository does.

### Adding a new tag in an existing repository (that you're the maintainer of)

-	Add your tag definition using the instruction format documented above.
-	Create a pull request from your Git repository to this one. Please be sure to add details about what's new, if possible.

### Change to a tag in an existing repository (that you're the maintainer of)

-	Update the relevant tag definition using the instruction format documented above.
-	Create a pull request from your Git repository to this one. Please be sure to add details about what's changed, if possible.

## Bashbrew

Bashbrew (`bashbrew`) is a tool for cloning, building, tagging, and pushing the Docker official images. See [`README.md` in the `bashbrew/` subfolder](bashbrew/README.md) for more information.
