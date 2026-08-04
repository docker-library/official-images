<!--

********************************************************************************

WARNING:

    DO NOT EDIT "mediawiki/README.md"

    IT IS AUTO-GENERATED

    (from the other files in "mediawiki/" combined with a set of templates)

********************************************************************************

-->

# Quick reference

-	**Maintained by**:  
	[MediaWiki community & Docker Community](https://github.com/wikimedia/mediawiki-docker)

-	**Where to get help**:  
	[the Docker Community Slack](https://dockr.ly/comm-slack), [Server Fault](https://serverfault.com/help/on-topic), [Unix & Linux](https://unix.stackexchange.com/help/on-topic), or [Stack Overflow](https://stackoverflow.com/help/on-topic)

# Supported tags and respective `Dockerfile` links

-	[`1.46.0`, `1.46`, `latest`, `stable`](https://github.com/wikimedia/mediawiki-docker/blob/9001094c3c889d6ea56e71e3b3ccef73d5135feb/1.46/apache/Dockerfile)

-	[`1.46.0-fpm`, `1.46-fpm`, `stable-fpm`](https://github.com/wikimedia/mediawiki-docker/blob/9001094c3c889d6ea56e71e3b3ccef73d5135feb/1.46/fpm/Dockerfile)

-	[`1.46.0-fpm-alpine`, `1.46-fpm-alpine`, `stable-fpm-alpine`](https://github.com/wikimedia/mediawiki-docker/blob/9001094c3c889d6ea56e71e3b3ccef73d5135feb/1.46/fpm-alpine/Dockerfile)

-	[`1.45.4`, `1.45`](https://github.com/wikimedia/mediawiki-docker/blob/9001094c3c889d6ea56e71e3b3ccef73d5135feb/1.45/apache/Dockerfile)

-	[`1.45.4-fpm`, `1.45-fpm`](https://github.com/wikimedia/mediawiki-docker/blob/9001094c3c889d6ea56e71e3b3ccef73d5135feb/1.45/fpm/Dockerfile)

-	[`1.45.4-fpm-alpine`, `1.45-fpm-alpine`](https://github.com/wikimedia/mediawiki-docker/blob/9001094c3c889d6ea56e71e3b3ccef73d5135feb/1.45/fpm-alpine/Dockerfile)

-	[`1.43.9`, `1.43`, `lts`](https://github.com/wikimedia/mediawiki-docker/blob/9001094c3c889d6ea56e71e3b3ccef73d5135feb/1.43/apache/Dockerfile)

-	[`1.43.9-fpm`, `1.43-fpm`, `lts-fpm`](https://github.com/wikimedia/mediawiki-docker/blob/9001094c3c889d6ea56e71e3b3ccef73d5135feb/1.43/fpm/Dockerfile)

-	[`1.43.9-fpm-alpine`, `1.43-fpm-alpine`, `lts-fpm-alpine`](https://github.com/wikimedia/mediawiki-docker/blob/9001094c3c889d6ea56e71e3b3ccef73d5135feb/1.43/fpm-alpine/Dockerfile)

# Quick reference (cont.)

-	**Where to file issues**:  
	[https://phabricator.wikimedia.org/project/view/3094/](https://phabricator.wikimedia.org/project/view/3094/)

-	**Supported architectures**: ([more info](https://github.com/docker-library/official-images#architectures-other-than-amd64))  
	[`amd64`](https://hub.docker.com/r/amd64/mediawiki/), [`arm32v5`](https://hub.docker.com/r/arm32v5/mediawiki/), [`arm32v6`](https://hub.docker.com/r/arm32v6/mediawiki/), [`arm32v7`](https://hub.docker.com/r/arm32v7/mediawiki/), [`arm64v8`](https://hub.docker.com/r/arm64v8/mediawiki/), [`i386`](https://hub.docker.com/r/i386/mediawiki/), [`ppc64le`](https://hub.docker.com/r/ppc64le/mediawiki/)

-	**Published image artifact details**:  
	[repo-info repo's `repos/mediawiki/` directory](https://github.com/docker-library/repo-info/blob/master/repos/mediawiki) ([history](https://github.com/docker-library/repo-info/commits/master/repos/mediawiki))  
	(image metadata, transfer size, etc)

-	**Image updates**:  
	[official-images repo's `library/mediawiki` label](https://github.com/docker-library/official-images/issues?q=label%3Alibrary%2Fmediawiki)  
	[official-images repo's `library/mediawiki` file](https://github.com/docker-library/official-images/blob/master/library/mediawiki) ([history](https://github.com/docker-library/official-images/commits/master/library/mediawiki))

-	**Source of this description**:  
	[docs repo's `mediawiki/` directory](https://github.com/docker-library/docs/tree/master/mediawiki) ([history](https://github.com/docker-library/docs/commits/master/mediawiki))

# What is MediaWiki?

MediaWiki is free and open-source wiki software. Originally developed by Magnus Manske and improved by Lee Daniel Crocker, it runs on many websites, including Wikipedia, Wiktionary and Wikimedia Commons. It is written in the PHP programming language and stores the contents into a database. Like WordPress, which is based on a similar licensing and architecture, it has become the dominant software in its category.

> [wikipedia.org/wiki/MediaWiki](https://en.wikipedia.org/wiki/MediaWiki)

![logo](https://raw.githubusercontent.com/docker-library/docs/27b797857efd9253c0981c09696f579a167062d4/mediawiki/logo.svg?sanitize=true)

# How to use this image

The basic pattern for starting a `mediawiki` instance is:

```console
$ docker run --name some-mediawiki -d mediawiki
```

If you'd like to be able to access the instance from the host without the container's IP, standard port mappings can be used:

```console
$ docker run --name some-mediawiki -p 8080:80 -d mediawiki
```

Then, access it via `http://localhost:8080` or `http://host-ip:8080` in a browser.

There are multiple database types supported by this image, most easily used via standard container linking. In the default configuration, SQLite can be used to avoid a second container and write to flat-files. More detailed instructions for different (more production-ready) database types follow.

When first accessing the webserver provided by this image, it will go through a brief setup process. The details provided below are specifically for the "Set up database" step of that configuration process.

## MySQL

```console
$ docker run --name some-mediawiki --link some-mysql:mysql -d mediawiki
```

-	Database type: `MySQL, MariaDB, or equivalent`
-	Database name/username/password: `<details for accessing your MySQL instance>` (`MYSQL_USER`, `MYSQL_PASSWORD`, `MYSQL_DATABASE`; see environment variables in the description for [`mariadb`](https://hub.docker.com/_/mariadb/))
-	ADVANCED OPTIONS; Database host: `some-mysql` (for using the `/etc/hosts` entry added by `--link` to access the linked container's MySQL instance)

## Volumes

By default, this image does not include any volumes.

The paths `/var/www/html/images` and `/var/www/html/LocalSettings.php` are things that generally ought to be volumes, but do not explicitly have a `VOLUME` declaration in this image because volumes cannot be removed.

```console
$ docker run --rm mediawiki tar -cC /var/www/html/sites . | tar -xC /path/on/host/sites
```

## ... via [`docker compose`](https://github.com/docker/compose)

Example `compose.yaml` for `mediawiki`:

```yaml
# MediaWiki with MariaDB
#
# Access via "http://localhost:8080"
services:
  mediawiki:
    image: mediawiki
    restart: always
    ports:
      - 8080:80
    links:
      - database
    volumes:
      - images:/var/www/html/images
      # After initial setup, download LocalSettings.php to the same directory as
      # this yaml and uncomment the following line and use compose to restart
      # the mediawiki service
      # - ./LocalSettings.php:/var/www/html/LocalSettings.php
  database: # <- This key defines the name of the database during setup
    image: mariadb
    restart: always
    environment:
      # @see https://phabricator.wikimedia.org/source/mediawiki/browse/master/includes/DefaultSettings.php
      MYSQL_DATABASE: my_wiki
      MYSQL_USER: wikiuser
      MYSQL_PASSWORD: example
      MYSQL_RANDOM_ROOT_PASSWORD: 'yes'
    volumes:
      - db:/var/lib/mysql

volumes:
  images:
  db:
```

Run `docker compose up`, wait for it to initialize completely, and visit `http://localhost:8080` or `http://host-ip:8080` (as appropriate).

## Adding additional libraries / extensions

This image does not provide any additional PHP extensions or other libraries, even if they are required by popular plugins. There are an infinite number of possible plugins, and they potentially require any extension PHP supports. Including every PHP extension that exists would dramatically increase the image size.

If you need additional PHP extensions, you'll need to create your own image `FROM` this one. The [documentation of the `php` image](https://github.com/docker-library/docs/blob/31280550a3c7104fef824450753844d2f3d917be/php/README.md#how-to-install-more-php-extensions) explains how to compile additional extensions.

The following Docker Hub features can help with the task of keeping your dependent images up-to-date:

-	[Automated Builds](https://docs.docker.com/docker-hub/builds/) let Docker Hub automatically build your Dockerfile each time you push changes to it.

# Image Variants

The `mediawiki` images come in many flavors, each designed for a specific use case.

## `mediawiki:<version>`

This is the defacto image. If you are unsure about what your needs are, you probably want to use this one. It is designed to be used both as a throw away container (mount your source code and start the container to start your app), as well as the base to build other images off of.

## `mediawiki:<version>-alpine`

This image is based on the popular [Alpine Linux project](https://alpinelinux.org), available in [the `alpine` official image](https://hub.docker.com/_/alpine). Alpine Linux is much smaller than most distribution base images (~5MB), and thus leads to much slimmer images in general.

This variant is useful when final image size being as small as possible is your primary concern. The main caveat to note is that it does use [musl libc](https://musl.libc.org) instead of [glibc and friends](https://www.etalabs.net/compare_libcs.html), so software will often run into issues depending on the depth of their libc requirements/assumptions. See [this Hacker News comment thread](https://news.ycombinator.com/item?id=10782897) for more discussion of the issues that might arise and some pro/con comparisons of using Alpine-based images.

To minimize image size, it's uncommon for additional related tools (such as `git` or `bash`) to be included in Alpine-based images. Using this image as a base, add the things you need in your own Dockerfile (see the [`alpine` image description](https://hub.docker.com/_/alpine/) for examples of how to install packages if you are unfamiliar).

# License

View [license information](https://phabricator.wikimedia.org/source/mediawiki/browse/master/COPYING) for the software contained in this image.

As with all Docker images, these likely also contain other software which may be under other licenses (such as Bash, etc from the base distribution, along with any direct or indirect dependencies of the primary software being contained).

Some additional license information which was able to be auto-detected might be found in [the `repo-info` repository's `mediawiki/` directory](https://github.com/docker-library/repo-info/tree/master/repos/mediawiki).

As for any pre-built image usage, it is the image user's responsibility to ensure that any use of this image complies with any relevant licenses for all software contained within.
