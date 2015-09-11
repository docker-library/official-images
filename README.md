# Docker Official Images

[![Build Status](https://travis-ci.org/docker-library/official-images.svg?branch=master)](https://travis-ci.org/docker-library/official-images)

## Contributing to the standard library

Thank you for your interest in the Docker official images project! We strive to make these instructions as simple and straightforward as possible, but if you find yourself lost, don't hesitate to seek us out on Freenode IRC in channel `#docker-library` or by creating a GitHub issue here.

Be sure to familiarize yourself with [Official Repositories on Docker Hub](https://docs.docker.com/docker-hub/official_repos/) and the [Best practices for writing Dockerfiles](https://docs.docker.com/articles/dockerfile_best-practices/) in the Docker documentation. These will be the foundation of the review process performed by the official images maintainers. If you'd like the review process to go more smoothly, please ensure that your `Dockerfile`s adhere to all the points mentioned there, as well as [below](README.md#review-guidelines), before submitting a pull request.

Also, the Hub descriptions for these images are currently stored separately in the [`docker-library/docs` repository](https://github.com/docker-library/docs), whose [`README.md` file](https://github.com/docker-library/docs/blob/master/README.md) explains more about how it's structured and how to contribute to it. Please be prepared to submit a PR there as well, pending acceptance of your image here.

### Review Guidelines

Because the official images are intended to be learning tools for those new to Docker as well as the base images for advanced users to build their production releases, we review each proposed `Dockerfile` to ensure that it meets a minimum standard for quality and maintainability. While some of that standard is hard to define (due to subjectivity), as much as possible is defined here, while also adhering to the "Best Practices" where appropriate.

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

```dockerfile
# grab tini for signal processing and zombie killing
RUN set -x \
	&& curl -fSL "https://github.com/krallin/tini/releases/download/v0.5.0/tini" -o /usr/local/bin/tini \
	&& chmod +x /usr/local/bin/tini \
	&& tini -h
```

**NOTE**: if [docker/docker#11529](https://github.com/docker/docker/issues/11529) gets solved, then `tini` would no longer be needed for reaping zombies.

#### Cacheability

This is one place that experience ends up trumping documentation for the path to enlightenment, but the following tips might help:

-	Avoid `COPY`/`ADD` whenever possible, but when necessary, be as specific as possible (ie, `COPY one-file.sh /somewhere/` instead of `COPY . /somewhere`).

	The reason for this is that the cache for `COPY` instructions considers file `mtime` changes to be a cache bust, which can make the cache behavior of `COPY` unpredictable sometimes, especially when `.git` is part of what needs to be `COPY`ed (for example).

-	Ensure that lines which are less likely to change come before lines that are more likely to change (with the caveat that each line should generate an image that still runs successfully without assumptions of later lines).

	For example, the line that contains the software version number (`ENV MYSOFTWARE_VERSION 4.2`) should come after a line that sets up the APT repository `.list` file (`RUN echo 'deb http://example.com/mysoftware/debian some-suite main' > /etc/apt/sources.list.d/mysoftware.list`).

#### Security

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

	(As a side note, `rm -rf /var/lib/apt/lists/*` is *roughly* the opposite of `apt-get update` -- it ensures that the layer doesn't include the extra ~8MB of APT package list data, and enforces [appropriate `apt-get update` usage](https://docs.docker.com/articles/dockerfile_best-practices/#run).)

-	**Alternate Best**: *full key fingerprint import, download over https, verify gpg signature of download.*

	```Dockerfile
	# gpg: key F73C700D: public key "Larry Hastings <larry@hastings.org>" imported
	RUN gpg --keyserver ha.pool.sks-keyservers.net --recv-keys 97FC712E4C024BBEA48A61ED3A5CA953F73C700D
	RUN curl -fSL "https://www.python.org/ftp/python/$PYTHON_VERSION/Python-$PYTHON_VERSION.tar.xz" -o python.tar.xz \
	    && curl -fSL "https://www.python.org/ftp/python/$PYTHON_VERSION/Python-$PYTHON_VERSION.tar.xz.asc" -o python.tar.xz.asc \
	    && gpg --verify python.tar.xz.asc \
	    # install
	```

### Commitment

Proposing a new official image should not be undertaken lightly. We expect and require a commitment to maintain your image (including and especially timely updates as appropriate, as noted above).

## Library definition files

The library definition files are plain text files found in the [`library/` directory of the `official-images` repository](https://github.com/docker-library/official-images/tree/master/library). Each library file controls the current "supported" set of image tags that appear on the Docker Hub description. Tags that are removed from a library file do not get removed from the Docker Hub, so that old versions can continue to be available for use, but are not maintained by upstream or the maintainer of the official image. Tags in the library file are only built through an update to that library file or as a result of its base image being updated (ie, an image `FROM debian:jessie` would be rebuilt when `debian:jessie` is built). Only what is in the library file will be rebuilt when a base has updates.

It is highly recommended that you browse some of the existing `library/` file contents (and history to get a feel for how they change over time) before creating a new one to become familiar with the prevailing conventions and further help streamline the review process (so that we can focus on content instead of esoteric formatting or tag usage/naming).

### Filenames

The filename of a definition file will determine the name of the image repository it creates on the Docker Hub. For example, the `library/ubuntu` file will create tags in the `ubuntu` repository.

### Instruction format

	<docker-tag>: <git-url>@<git-commit-id>
	
	4.1.1: git://github.com/docker-library/wordpress@bbef6075afa043cbfe791b8de185105065c02c01
	4.1: git://github.com/docker-library/wordpress@bbef6075afa043cbfe791b8de185105065c02c01
	4: git://github.com/docker-library/wordpress@bbef6075afa043cbfe791b8de185105065c02c01
	latest: git://github.com/docker-library/wordpress@bbef6075afa043cbfe791b8de185105065c02c01
	
	
	<docker-tag>: <git-url>@<git-commit-id> <dockerfile-dir>
	
	2.6.17: git://github.com/docker-library/redis@062335e0a8d20cab2041f25dfff2fbaf58544471 2.6
	2.6: git://github.com/docker-library/redis@062335e0a8d20cab2041f25dfff2fbaf58544471 2.6
	
	2.8.19: git://github.com/docker-library/redis@062335e0a8d20cab2041f25dfff2fbaf58544471 2.8
	2.8: git://github.com/docker-library/redis@062335e0a8d20cab2041f25dfff2fbaf58544471 2.8
	2: git://github.com/docker-library/redis@062335e0a8d20cab2041f25dfff2fbaf58544471 2.8
	latest: git://github.com/docker-library/redis@062335e0a8d20cab2041f25dfff2fbaf58544471 2.8
	
	experimental: git://github.com/tianon/dockerfiles@90d86ad63c4a06b7d04d14ad830381b876183b3c debian/experimental

Bashbrew will fetch code out of the Git repository at the commit specified here. The generated image will be tagged as `<manifest-filename>:<docker-tag>`.

Using Git tags instead of explicit Git commit references is supported, but heavily discouraged. For example, if a Git tag is changed on the referenced repository to point to another commit, **the image will not be rebuilt**. Instead, either create a new tag (or reference an exact commit) and submit a pull request.

Optionally, if `<dockerfile-dir>` is present, Bashbrew will look for the `Dockerfile` inside the specified subdirectory instead of at the root (and `<dockerfile-dir>` will be used as the ["context" for the build](https://docs.docker.com/reference/builder/)).

### Creating a new repository

-	Create a new file in the `library/` folder. Its name will be the name of your repository on the Hub.
-	Add your tag definitions using the appropriate syntax (see above).
-	Add a line similar to the following to the top of the file:

		# maintainer: Your Name <your@email.com> (@github.name)

-	Create a pull request adding the file from your forked repository to this one. Please be sure to add details as to what your repository does.

### Adding a new tag in an existing repository (that you're the maintainer of)

-	Add your tag definition using the instruction format documented above.
-	Create a pull request from your Git repository to this one. Please be sure to add details about what's new, if possible.
-	In the pull request comments, feel free to prod the repository's maintainers (found in the relevant `MAINTAINERS` file) using GitHub's @-mentions.

### Change to a tag in an existing repository (that you're the maintainer of)

-	Update the relevant tag definition using the instruction format documented above.
-	Create a pull request from your Git repository to this one. Please be sure to add details about what's changed, if possible.
-	In the pull request comments, feel free to prod the repository's maintainers (found in the relevant `MAINTAINERS` file) using GitHub's @-mentions.

## Bashbrew

Bashbrew is a set of bash scripts for cloning, building, tagging, and pushing the Docker official images. See [`README.md` in the `bashbrew/` subfolder](bashbrew/README.md) for more information.
