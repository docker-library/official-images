<!--

********************************************************************************

WARNING:

    DO NOT EDIT "redmine/README.md"

    IT IS AUTO-GENERATED

    (from the other files in "redmine/" combined with a set of templates)

********************************************************************************

-->

# Quick reference

-	**Maintained by**:  
	[the Docker Community](https://github.com/docker-library/redmine)

-	**Where to get help**:  
	[the Docker Community Slack](https://dockr.ly/comm-slack), [Server Fault](https://serverfault.com/help/on-topic), [Unix & Linux](https://unix.stackexchange.com/help/on-topic), or [Stack Overflow](https://stackoverflow.com/help/on-topic)

# Supported tags and respective `Dockerfile` links

-	[`7.0.0`, `7.0`, `7`, `latest`, `7.0.0-trixie`, `7.0-trixie`, `7-trixie`, `trixie`](https://github.com/docker-library/redmine/blob/f772dee7158856abee669c717bb258f1ad43bce9/7.0/trixie/Dockerfile)

-	[`7.0.0-bookworm`, `7.0-bookworm`, `7-bookworm`, `bookworm`](https://github.com/docker-library/redmine/blob/f772dee7158856abee669c717bb258f1ad43bce9/7.0/bookworm/Dockerfile)

-	[`7.0.0-alpine3.24`, `7.0-alpine3.24`, `7-alpine3.24`, `alpine3.24`, `7.0.0-alpine`, `7.0-alpine`, `7-alpine`, `alpine`](https://github.com/docker-library/redmine/blob/f772dee7158856abee669c717bb258f1ad43bce9/7.0/alpine3.24/Dockerfile)

-	[`7.0.0-alpine3.23`, `7.0-alpine3.23`, `7-alpine3.23`, `alpine3.23`](https://github.com/docker-library/redmine/blob/f772dee7158856abee669c717bb258f1ad43bce9/7.0/alpine3.23/Dockerfile)

-	[`6.1.3`, `6.1`, `6`, `6.1.3-trixie`, `6.1-trixie`, `6-trixie`](https://github.com/docker-library/redmine/blob/4e7d7ad67b47d3a0d9d1d22379141a8be0fae2ee/6.1/trixie/Dockerfile)

-	[`6.1.3-bookworm`, `6.1-bookworm`, `6-bookworm`](https://github.com/docker-library/redmine/blob/f772dee7158856abee669c717bb258f1ad43bce9/6.1/bookworm/Dockerfile)

-	[`6.1.3-alpine3.24`, `6.1-alpine3.24`, `6-alpine3.24`, `6.1.3-alpine`, `6.1-alpine`, `6-alpine`](https://github.com/docker-library/redmine/blob/f772dee7158856abee669c717bb258f1ad43bce9/6.1/alpine3.24/Dockerfile)

-	[`6.1.3-alpine3.23`, `6.1-alpine3.23`, `6-alpine3.23`](https://github.com/docker-library/redmine/blob/f772dee7158856abee669c717bb258f1ad43bce9/6.1/alpine3.23/Dockerfile)

-	[`6.0.10`, `6.0`, `6.0.10-trixie`, `6.0-trixie`](https://github.com/docker-library/redmine/blob/4e7d7ad67b47d3a0d9d1d22379141a8be0fae2ee/6.0/trixie/Dockerfile)

-	[`6.0.10-bookworm`, `6.0-bookworm`](https://github.com/docker-library/redmine/blob/4e7d7ad67b47d3a0d9d1d22379141a8be0fae2ee/6.0/bookworm/Dockerfile)

-	[`6.0.10-alpine3.24`, `6.0-alpine3.24`, `6.0.10-alpine`, `6.0-alpine`](https://github.com/docker-library/redmine/blob/f772dee7158856abee669c717bb258f1ad43bce9/6.0/alpine3.24/Dockerfile)

-	[`6.0.10-alpine3.23`, `6.0-alpine3.23`](https://github.com/docker-library/redmine/blob/f772dee7158856abee669c717bb258f1ad43bce9/6.0/alpine3.23/Dockerfile)

# Quick reference (cont.)

-	**Where to file issues**:  
	[https://github.com/docker-library/redmine/issues](https://github.com/docker-library/redmine/issues?q=)

-	**Supported architectures**: ([more info](https://github.com/docker-library/official-images#architectures-other-than-amd64))  
	[`amd64`](https://hub.docker.com/r/amd64/redmine/), [`arm32v5`](https://hub.docker.com/r/arm32v5/redmine/), [`arm32v6`](https://hub.docker.com/r/arm32v6/redmine/), [`arm32v7`](https://hub.docker.com/r/arm32v7/redmine/), [`arm64v8`](https://hub.docker.com/r/arm64v8/redmine/), [`i386`](https://hub.docker.com/r/i386/redmine/), [`ppc64le`](https://hub.docker.com/r/ppc64le/redmine/), [`riscv64`](https://hub.docker.com/r/riscv64/redmine/), [`s390x`](https://hub.docker.com/r/s390x/redmine/)

-	**Published image artifact details**:  
	[repo-info repo's `repos/redmine/` directory](https://github.com/docker-library/repo-info/blob/master/repos/redmine) ([history](https://github.com/docker-library/repo-info/commits/master/repos/redmine))  
	(image metadata, transfer size, etc)

-	**Image updates**:  
	[official-images repo's `library/redmine` label](https://github.com/docker-library/official-images/issues?q=label%3Alibrary%2Fredmine)  
	[official-images repo's `library/redmine` file](https://github.com/docker-library/official-images/blob/master/library/redmine) ([history](https://github.com/docker-library/official-images/commits/master/library/redmine))

-	**Source of this description**:  
	[docs repo's `redmine/` directory](https://github.com/docker-library/docs/tree/master/redmine) ([history](https://github.com/docker-library/docs/commits/master/redmine))

# What is Redmine?

Redmine is a free and open source, web-based project management and issue tracking tool. It allows users to manage multiple projects and associated subprojects. It features per project wikis and forums, time tracking, and flexible role based access control. It includes a calendar and Gantt charts to aid visual representation of projects and their deadlines. Redmine integrates with various version control systems and includes a repository browser and diff viewer.

> [wikipedia.org/wiki/Redmine](https://en.wikipedia.org/wiki/Redmine)

![logo](https://raw.githubusercontent.com/docker-library/docs/969091c4c590befe236a71d4a7bce5823fff020d/redmine/logo.png)

# How to use this image

## Run Redmine with SQLite3

This is the simplest setup; just run redmine.

```console
$ docker run -d --name some-redmine redmine
```

> not for multi-user production use ([redmine wiki](http://www.redmine.org/projects/redmine/wiki/RedmineInstall#Supported-database-back-ends))

## Run Redmine with a Database Container

Running Redmine with a database server is the recommended way.

1.	start a database container

	-	PostgreSQL

		```console
		$ docker run -d --name some-postgres --network some-network -e POSTGRES_PASSWORD=secret -e POSTGRES_USER=redmine postgres
		```

	-	MySQL (replace `-e REDMINE_DB_POSTGRES=some-postgres` with `-e REDMINE_DB_MYSQL=some-mysql` when running Redmine)

		```console
		$ docker run -d --name some-mysql --network some-network -e MYSQL_USER=redmine -e MYSQL_PASSWORD=secret -e MYSQL_DATABASE=redmine -e MYSQL_RANDOM_ROOT_PASSWORD=1 mysql:5.7
		```

2.	start redmine

	```console
	$ docker run -d --name some-redmine --network some-network -e REDMINE_DB_POSTGRES=some-postgres -e REDMINE_DB_USERNAME=redmine -e REDMINE_DB_PASSWORD=secret redmine
	```

## ... via [`docker compose`](https://github.com/docker/compose)

Example `compose.yaml` for `redmine`:

```yaml
services:

  redmine:
    image: redmine
    restart: always
    ports:
      - 8080:3000
    environment:
      REDMINE_DB_MYSQL: db
      REDMINE_DB_PASSWORD: example
      REDMINE_SECRET_KEY_BASE: supersecretkey

  db:
    image: mysql:8.0
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: example
      MYSQL_DATABASE: redmine
```

Run `docker compose up`, wait for it to initialize completely, and visit `http://localhost:8080` or `http://host-ip:8080` (as appropriate).

## Accessing the Application

Currently, the default user and password from upstream is admin/admin ([logging into the application](https://www.redmine.org/projects/redmine/wiki/RedmineInstall#Step-10-Logging-into-the-application)).

## Where to Store Data

Important note: There are several ways to store data used by applications that run in Docker containers. We encourage users of the `redmine` images to familiarize themselves with the options available, including:

-	Let Docker manage the storage of your files [by writing the files to disk on the host system using its own internal volume management](https://docs.docker.com/storage/volumes/). This is the default and is easy and fairly transparent to the user. The downside is that the files may be hard to locate for tools and applications that run directly on the host system, i.e. outside containers.
-	Create a data directory on the host system (outside the container) and [mount this to a directory visible from inside the container](https://docs.docker.com/storage/bind-mounts/). This places the database files in a known location on the host system, and makes it easy for tools and applications on the host system to access the files. The downside is that the user needs to make sure that the directory exists, and that e.g. directory permissions and other security mechanisms on the host system are set up correctly.

The Docker documentation is a good starting point for understanding the different storage options and variations, and there are multiple blogs and forum postings that discuss and give advice in this area. We will simply show the basic procedure here for the latter option above:

1.	Create a data directory on a suitable volume on your host system, e.g. `/my/own/datadir`.
2.	Start your `redmine` container like this:

	```console
	$ docker run -d --name some-redmine -v /my/own/datadir:/usr/src/redmine/files --link some-postgres:postgres redmine
	```

The `-v /my/own/datadir:/usr/src/redmine/files` part of the command mounts the `/my/own/datadir` directory from the underlying host system as `/usr/src/redmine/files` inside the container, where Redmine will store uploaded files.

## Port Mapping

If you'd like to be able to access the instance from the host without the container's IP, standard port mappings can be used. Just add `-p 3000:3000` to the `docker run` arguments and then access either `http://localhost:3000` or `http://host-ip:3000` in a browser.

## Environment Variables

When you start the `redmine` image, you can adjust the configuration of the instance by passing one or more environment variables on the `docker run` command line.

### `REDMINE_DB_MYSQL`, `REDMINE_DB_POSTGRES`, or `REDMINE_DB_SQLSERVER`

These variables allow you to set the hostname or IP address of the MySQL, PostgreSQL, or Microsoft SQL host, respectively. These values are mutually exclusive so it is undefined behavior if any two are set. If no variable is set, the image will fall back to using SQLite.

### `REDMINE_DB_PORT`

This variable allows you to specify a custom database connection port. If unspecified, it will default to the regular connection ports: 3306 for MySQL, 5432 for PostgreSQL, and empty string for SQLite.

### `REDMINE_DB_USERNAME`

This variable sets the user that Redmine and any rake tasks use to connect to the specified database. If unspecified, it will default to `root` for MySQL, `postgres` for PostgreSQL, or `redmine` for SQLite.

### `REDMINE_DB_PASSWORD`

This variable sets the password that the specified user will use in connecting to the database. There is no default value.

### `REDMINE_DB_DATABASE`

This variable sets the database that Redmine will use in the specified database server. If not specified, it will default to `redmine` for MySQL, the value of `REDMINE_DB_USERNAME` for PostgreSQL, or `sqlite/redmine.db` for SQLite.

### `REDMINE_DB_ENCODING`

This variable sets the character encoding to use when connecting to the database server. If unspecified, it will use the default for the `mysql2` library ([`UTF-8`](https://github.com/brianmario/mysql2/tree/18673e8d8663a56213a980212e1092c2220faa92#mysql2---a-modern-simple-and-very-fast-mysql-library-for-ruby---binding-to-libmysql)) for MySQL, `utf8` for PostgreSQL, or `utf8` for SQLite.

### `REDMINE_NO_DB_MIGRATE`

This variable allows you to control if `rake db:migrate` is run on container start. Just set the variable to a non-empty string like `1` or `true` and the migrate script will not automatically run on container start.

`db:migrate` will also not run if you start your image with something other than the default `CMD`, like `bash`. See the current `docker-entrypoint.sh` in your image for details.

### `REDMINE_PLUGINS_MIGRATE`

This variable allows you to control if `rake redmine:plugins:migrate` is run on container start. Just set the variable to a non-empty string like `1` or `true` and the migrate script will be automatically run on every container start. It will be run after `db:migrate`.

`redmine:plugins:migrate` will not run if you start your image with something other than the default `CMD`, like `bash`. See the current `docker-entrypoint.sh` in your image for details.

### `SECRET_KEY_BASE`

This is a general Rails environment variable. This variable is useful when using loadbalanced replicas to maintain session connections. It is "used by Rails to encode cookies storing session data thus preventing their tampering. Generating a new secret token invalidates all existing sessions after restart" ([session store](https://www.redmine.org/projects/redmine/wiki/RedmineInstall#Step-5-Session-store-secret-generation)). If you do not set this variable, then the `secret_key_base` value will be generated using `rake generate_secret_token`.

For backwards compatibility, the deprecated, Docker-specific `REDMINE_SECRET_KEY_BASE` variable will automatically fill the `SECRET_KEY_BASE` environment variable. Users should migrate their deployments to use the `SECRET_KEY_BASE` variable directly.

## Running as an arbitrary user

You can use the [`--user`](https://docs.docker.com/engine/reference/run/#user) flag to `docker run` and give it a `username:group` or `UID:GID`, the user doesn't need to exist in the container.

## Docker Secrets

As an alternative to passing sensitive information via environment variables, `_FILE` may be appended to the previously listed environment variables, causing the initialization script to load the values for those variables from files present in the container. In particular, this can be used to load passwords from Docker secrets stored in `/run/secrets/<secret_name>` files. For example:

```console
$ docker run -d --name some-redmine -e REDMINE_DB_MYSQL_FILE=/run/secrets/mysql-host -e REDMINE_DB_PASSWORD_FILE=/run/secrets/mysql-root redmine:tag
```

Currently, this is only supported for `REDMINE_DB_MYSQL`, `REDMINE_DB_POSTGRES`, `REDMINE_DB_PORT`, `REDMINE_DB_USERNAME`, `REDMINE_DB_PASSWORD`, `REDMINE_DB_DATABASE`, `REDMINE_DB_ENCODING`, and `REDMINE_SECRET_KEY_BASE`.

# Image Variants

The `redmine` images come in many flavors, each designed for a specific use case.

## `redmine:<version>`

This is the defacto image. If you are unsure about what your needs are, you probably want to use this one. It is designed to be used both as a throw away container (mount your source code and start the container to start your app), as well as the base to build other images off of.

Some of these tags may have names like bookworm or trixie in them. These are the suite code names for releases of [Debian](https://wiki.debian.org/DebianReleases) and indicate which release the image is based on. If your image needs to install any additional packages beyond what comes with the image, you'll likely want to specify one of these explicitly to minimize breakage when there are new releases of Debian.

## `redmine:<version>-alpine`

This image is based on the popular [Alpine Linux project](https://alpinelinux.org), available in [the `alpine` official image](https://hub.docker.com/_/alpine). Alpine Linux is much smaller than most distribution base images (~5MB), and thus leads to much slimmer images in general.

This variant is useful when final image size being as small as possible is your primary concern. The main caveat to note is that it does use [musl libc](https://musl.libc.org) instead of [glibc and friends](https://www.etalabs.net/compare_libcs.html), so software will often run into issues depending on the depth of their libc requirements/assumptions. See [this Hacker News comment thread](https://news.ycombinator.com/item?id=10782897) for more discussion of the issues that might arise and some pro/con comparisons of using Alpine-based images.

To minimize image size, it's uncommon for additional related tools (such as `git` or `bash`) to be included in Alpine-based images. Using this image as a base, add the things you need in your own Dockerfile (see the [`alpine` image description](https://hub.docker.com/_/alpine/) for examples of how to install packages if you are unfamiliar).

# License

[Redmine](https://www.redmine.org/projects/redmine/wiki) is open source and released under the terms of the [GNU General Public License v2](https://www.gnu.org/licenses/old-licenses/gpl-2.0.html) (GPL).

As with all Docker images, these likely also contain other software which may be under other licenses (such as Bash, etc from the base distribution, along with any direct or indirect dependencies of the primary software being contained).

Some additional license information which was able to be auto-detected might be found in [the `repo-info` repository's `redmine/` directory](https://github.com/docker-library/repo-info/tree/master/repos/redmine).

As for any pre-built image usage, it is the image user's responsibility to ensure that any use of this image complies with any relevant licenses for all software contained within.
