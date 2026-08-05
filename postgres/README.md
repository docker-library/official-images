<!--

********************************************************************************

WARNING:

    DO NOT EDIT "postgres/README.md"

    IT IS AUTO-GENERATED

    (from the other files in "postgres/" combined with a set of templates)

********************************************************************************

-->

# Quick reference

-	**Maintained by**:  
	[the PostgreSQL Docker Community](https://github.com/docker-library/postgres)

-	**Where to get help**:  
	[the Docker Community Slack](https://dockr.ly/comm-slack), [Server Fault](https://serverfault.com/help/on-topic), [Unix & Linux](https://unix.stackexchange.com/help/on-topic), or [Stack Overflow](https://stackoverflow.com/help/on-topic)

# Supported tags and respective `Dockerfile` links

-	[`19beta2`, `19beta2-trixie`](https://github.com/docker-library/postgres/blob/62a714f93cc32220de46fd12235c9d509e3b1ad6/19/trixie/Dockerfile)

-	[`19beta2-bookworm`](https://github.com/docker-library/postgres/blob/62a714f93cc32220de46fd12235c9d509e3b1ad6/19/bookworm/Dockerfile)

-	[`19beta2-alpine3.24`, `19beta2-alpine`](https://github.com/docker-library/postgres/blob/62a714f93cc32220de46fd12235c9d509e3b1ad6/19/alpine3.24/Dockerfile)

-	[`19beta2-alpine3.23`](https://github.com/docker-library/postgres/blob/62a714f93cc32220de46fd12235c9d509e3b1ad6/19/alpine3.23/Dockerfile)

-	[`18.4`, `18`, `latest`, `18.4-trixie`, `18-trixie`, `trixie`](https://github.com/docker-library/postgres/blob/d71f5241e97ebf5c6e6e37e3043ab542132550f2/18/trixie/Dockerfile)

-	[`18.4-bookworm`, `18-bookworm`, `bookworm`](https://github.com/docker-library/postgres/blob/4f9ced003ba58a854656ba150d146243d27ae3ac/18/bookworm/Dockerfile)

-	[`18.4-alpine3.24`, `18-alpine3.24`, `alpine3.24`, `18.4-alpine`, `18-alpine`, `alpine`](https://github.com/docker-library/postgres/blob/4f9ced003ba58a854656ba150d146243d27ae3ac/18/alpine3.24/Dockerfile)

-	[`18.4-alpine3.23`, `18-alpine3.23`, `alpine3.23`](https://github.com/docker-library/postgres/blob/4f9ced003ba58a854656ba150d146243d27ae3ac/18/alpine3.23/Dockerfile)

-	[`17.10`, `17`, `17.10-trixie`, `17-trixie`](https://github.com/docker-library/postgres/blob/9e3449a57a973a64db74f4d773247d4c049bba68/17/trixie/Dockerfile)

-	[`17.10-bookworm`, `17-bookworm`](https://github.com/docker-library/postgres/blob/4f9ced003ba58a854656ba150d146243d27ae3ac/17/bookworm/Dockerfile)

-	[`17.10-alpine3.24`, `17-alpine3.24`, `17.10-alpine`, `17-alpine`](https://github.com/docker-library/postgres/blob/4f9ced003ba58a854656ba150d146243d27ae3ac/17/alpine3.24/Dockerfile)

-	[`17.10-alpine3.23`, `17-alpine3.23`](https://github.com/docker-library/postgres/blob/4f9ced003ba58a854656ba150d146243d27ae3ac/17/alpine3.23/Dockerfile)

-	[`16.14`, `16`, `16.14-trixie`, `16-trixie`](https://github.com/docker-library/postgres/blob/f64ed48c36df300966bcbe72fee53af745045579/16/trixie/Dockerfile)

-	[`16.14-bookworm`, `16-bookworm`](https://github.com/docker-library/postgres/blob/4f9ced003ba58a854656ba150d146243d27ae3ac/16/bookworm/Dockerfile)

-	[`16.14-alpine3.24`, `16-alpine3.24`, `16.14-alpine`, `16-alpine`](https://github.com/docker-library/postgres/blob/4f9ced003ba58a854656ba150d146243d27ae3ac/16/alpine3.24/Dockerfile)

-	[`16.14-alpine3.23`, `16-alpine3.23`](https://github.com/docker-library/postgres/blob/4f9ced003ba58a854656ba150d146243d27ae3ac/16/alpine3.23/Dockerfile)

-	[`15.18`, `15`, `15.18-trixie`, `15-trixie`](https://github.com/docker-library/postgres/blob/4fd4a0af49c8eafd82e823b632515ca44c93c688/15/trixie/Dockerfile)

-	[`15.18-bookworm`, `15-bookworm`](https://github.com/docker-library/postgres/blob/4f9ced003ba58a854656ba150d146243d27ae3ac/15/bookworm/Dockerfile)

-	[`15.18-alpine3.24`, `15-alpine3.24`, `15.18-alpine`, `15-alpine`](https://github.com/docker-library/postgres/blob/4f9ced003ba58a854656ba150d146243d27ae3ac/15/alpine3.24/Dockerfile)

-	[`15.18-alpine3.23`, `15-alpine3.23`](https://github.com/docker-library/postgres/blob/4f9ced003ba58a854656ba150d146243d27ae3ac/15/alpine3.23/Dockerfile)

-	[`14.23`, `14`, `14.23-trixie`, `14-trixie`](https://github.com/docker-library/postgres/blob/7b2e3e89bb08d483b9d913986ec93c01a51edb39/14/trixie/Dockerfile)

-	[`14.23-bookworm`, `14-bookworm`](https://github.com/docker-library/postgres/blob/4f9ced003ba58a854656ba150d146243d27ae3ac/14/bookworm/Dockerfile)

-	[`14.23-alpine3.24`, `14-alpine3.24`, `14.23-alpine`, `14-alpine`](https://github.com/docker-library/postgres/blob/4f9ced003ba58a854656ba150d146243d27ae3ac/14/alpine3.24/Dockerfile)

-	[`14.23-alpine3.23`, `14-alpine3.23`](https://github.com/docker-library/postgres/blob/4f9ced003ba58a854656ba150d146243d27ae3ac/14/alpine3.23/Dockerfile)

# Quick reference (cont.)

-	**Where to file issues**:  
	[https://github.com/docker-library/postgres/issues](https://github.com/docker-library/postgres/issues?q=)

-	**Supported architectures**: ([more info](https://github.com/docker-library/official-images#architectures-other-than-amd64))  
	[`amd64`](https://hub.docker.com/r/amd64/postgres/), [`arm32v5`](https://hub.docker.com/r/arm32v5/postgres/), [`arm32v6`](https://hub.docker.com/r/arm32v6/postgres/), [`arm32v7`](https://hub.docker.com/r/arm32v7/postgres/), [`arm64v8`](https://hub.docker.com/r/arm64v8/postgres/), [`i386`](https://hub.docker.com/r/i386/postgres/), [`ppc64le`](https://hub.docker.com/r/ppc64le/postgres/), [`riscv64`](https://hub.docker.com/r/riscv64/postgres/), [`s390x`](https://hub.docker.com/r/s390x/postgres/)

-	**Published image artifact details**:  
	[repo-info repo's `repos/postgres/` directory](https://github.com/docker-library/repo-info/blob/master/repos/postgres) ([history](https://github.com/docker-library/repo-info/commits/master/repos/postgres))  
	(image metadata, transfer size, etc)

-	**Image updates**:  
	[official-images repo's `library/postgres` label](https://github.com/docker-library/official-images/issues?q=label%3Alibrary%2Fpostgres)  
	[official-images repo's `library/postgres` file](https://github.com/docker-library/official-images/blob/master/library/postgres) ([history](https://github.com/docker-library/official-images/commits/master/library/postgres))

-	**Source of this description**:  
	[docs repo's `postgres/` directory](https://github.com/docker-library/docs/tree/master/postgres) ([history](https://github.com/docker-library/docs/commits/master/postgres))

# What is PostgreSQL?

PostgreSQL, often simply "Postgres", is an object-relational database management system (ORDBMS) with an emphasis on extensibility and standards-compliance. As a database server, its primary function is to store data, securely and supporting best practices, and retrieve it later, as requested by other software applications, be it those on the same computer or those running on another computer across a network (including the Internet). It can handle workloads ranging from small single-machine applications to large Internet-facing applications with many concurrent users. Recent versions also provide replication of the database itself for security and scalability.

PostgreSQL implements the majority of the SQL:2011 standard, is ACID-compliant and transactional (including most DDL statements) avoiding locking issues using multiversion concurrency control (MVCC), provides immunity to dirty reads and full serializability; handles complex SQL queries using many indexing methods that are not available in other databases; has updateable views and materialized views, triggers, foreign keys; supports functions and stored procedures, and other expandability, and has a large number of extensions written by third parties. In addition to the possibility of working with the major proprietary and open source databases, PostgreSQL supports migration from them, by its extensive standard SQL support and available migration tools. And if proprietary extensions had been used, by its extensibility that can emulate many through some built-in and third-party open source compatibility extensions, such as for Oracle.

> [wikipedia.org/wiki/PostgreSQL](https://en.wikipedia.org/wiki/PostgreSQL)

![logo](https://raw.githubusercontent.com/docker-library/docs/01c12653951b2fe592c1f93a13b4e289ada0e3a1/postgres/logo.png)

# How to use this image

## start a postgres instance

```console
$ docker run --name some-postgres -e POSTGRES_PASSWORD=mysecretpassword -d postgres
```

The default `postgres` user and database are created in the entrypoint with `initdb`.

> The postgres database is a default database meant for use by users, utilities and third party applications.
>
> [postgresql.org/docs](https://www.postgresql.org/docs/14/app-initdb.html)

## ... or via `psql`

```console
$ docker run -it --rm --network some-network postgres psql -h some-postgres -U postgres
psql (14.3)
Type "help" for help.

postgres=# SELECT 1;
 ?column? 
----------
        1
(1 row)
```

## ... via [`docker compose`](https://github.com/docker/compose)

Example `compose.yaml` for `postgres`:

```yaml
# Use postgres/example user/password credentials

services:

  db:
    image: postgres
    restart: always
    # set shared memory limit when using docker compose
    shm_size: 128mb
    # or set shared memory limit when deploy via swarm stack
    #volumes:
    #  - type: tmpfs
    #    target: /dev/shm
    #    tmpfs:
    #      size: 134217728 # 128*2^20 bytes = 128Mb
    environment:
      POSTGRES_PASSWORD: example

  adminer:
    image: adminer
    restart: always
    ports:
      - 8080:8080
```

Run `docker compose up`, wait for it to initialize completely, and visit `http://localhost:8080` or `http://host-ip:8080` (as appropriate).

# How to extend this image

There are many ways to extend the `postgres` image. Without trying to support every possible use case, here are just a few that we have found useful.

## Environment Variables

The PostgreSQL image uses several environment variables which are easy to miss. The only variable required is `POSTGRES_PASSWORD`, the rest are optional.

**Warning**: the Docker specific variables will only have an effect if you start the container with a data directory that is empty; any pre-existing database will be left untouched on container startup.

### `POSTGRES_PASSWORD`

This environment variable is required for you to use the PostgreSQL image. It must not be empty or undefined. This environment variable sets the superuser password for PostgreSQL. The default superuser is defined by the `POSTGRES_USER` environment variable.

**Note 1:** The PostgreSQL image sets up `trust` authentication locally so you may notice a password is not required when connecting from `localhost` (inside the same container). However, a password will be required if connecting from a different host/container.

**Note 2:** This variable defines the superuser password in the PostgreSQL instance, as set by the `initdb` script during initial container startup. It has no effect on the `PGPASSWORD` environment variable that may be used by the `psql` client at runtime, as described at [https://www.postgresql.org/docs/14/libpq-envars.html](https://www.postgresql.org/docs/14/libpq-envars.html). `PGPASSWORD`, if used, will be specified as a separate environment variable.

### `POSTGRES_USER`

This optional environment variable is used in conjunction with `POSTGRES_PASSWORD` to set a user and its password. This variable will create the specified user with superuser power and a database with the same name. If it is not specified, then the default user of `postgres` will be used.

Be aware that if this parameter is specified, PostgreSQL will still show `The files belonging to this database system will be owned by user "postgres"` during initialization. This refers to the Linux system user (from `/etc/passwd` in the image) that the `postgres` daemon runs as, and as such is unrelated to the `POSTGRES_USER` option. See the section titled "Arbitrary `--user` Notes" for more details.

### `POSTGRES_DB`

This optional environment variable can be used to define a different name for the default database that is created when the image is first started. If it is not specified, then the value of `POSTGRES_USER` will be used.

### `POSTGRES_INITDB_ARGS`

This optional environment variable can be used to send arguments to `postgres initdb`. The value is a space separated string of arguments as `postgres initdb` would expect them. This is useful for adding functionality like data page checksums: `-e POSTGRES_INITDB_ARGS="--data-checksums"`.

### `POSTGRES_INITDB_WALDIR`

This optional environment variable can be used to define another location for the Postgres transaction log. By default the transaction log is stored in a subdirectory of the main Postgres data folder (`PGDATA`). Sometimes it can be desireable to store the transaction log in a different directory which may be backed by storage with different performance or reliability characteristics.

**Note:** on PostgreSQL 9.x, this variable is `POSTGRES_INITDB_XLOGDIR` (reflecting [the changed name of the `--xlogdir` flag to `--waldir` in PostgreSQL 10+](https://wiki.postgresql.org/wiki/New_in_postgres_10#Renaming_of_.22xlog.22_to_.22wal.22_Globally_.28and_location.2Flsn.29)).

### `POSTGRES_HOST_AUTH_METHOD`

This optional variable can be used to control the `auth-method` for `host` connections for `all` databases, `all` users, and `all` addresses. If unspecified then [`scram-sha-256` password authentication](https://www.postgresql.org/docs/14/auth-password.html) is used (in 14+; `md5` in older releases). On an uninitialized database, this will populate `pg_hba.conf` via this approximate line:

```console
echo "host all all all $POSTGRES_HOST_AUTH_METHOD" >> pg_hba.conf
```

See the PostgreSQL documentation on [`pg_hba.conf`](https://www.postgresql.org/docs/14/auth-pg-hba-conf.html) for more information about possible values and their meanings.

**Note 1:** It is not recommended to use `trust` since it allows anyone to connect without a password, even if one is set (like via `POSTGRES_PASSWORD`). For more information see the PostgreSQL documentation on [*Trust Authentication*](https://www.postgresql.org/docs/14/auth-trust.html).

**Note 2:** If you set `POSTGRES_HOST_AUTH_METHOD` to `trust`, then `POSTGRES_PASSWORD` is not required.

**Note 3:** If you set this to an alternative value (such as `scram-sha-256`), you might need additional `POSTGRES_INITDB_ARGS` for the database to initialize correctly (such as `POSTGRES_INITDB_ARGS=--auth-host=scram-sha-256`).

### `PGDATA`

> **Important Change:** [the `PGDATA` environment variable of the image was changed to be version specific in PostgreSQL 18 and above](https://github.com/docker-library/postgres/pull/1259). For 18 it is `/var/lib/postgresql/18/docker`. Later versions will replace `18` with their respective major version (e.g., `/var/lib/postgresql/19/docker` for PostgreSQL `19.x`). The defined `VOLUME` was changed in 18 and above to `/var/lib/postgresql`. Mounts and volumes should be targeted at the updated location. This will allow users upgrading between PostgreSQL major releases to use the faster `--link` when running `pg_upgrade` and mounting `/var/lib/postgresql`.

Users who wish to opt-in to this change on older releases can do so by setting `PGDATA` explicitly (`--env PGDATA=/var/lib/postgresql/17/docker --volume some-postgres:/var/lib/postgresql`). To migrate pre-existing data, adjust the volume's folder structure appropriately first (moving all database files into a `PG_MAJOR/docker` subdirectory).

> **Important Note:** (for PostgreSQL 17 and below) Mount the data volume at `/var/lib/postgresql/data` and not at `/var/lib/postgresql` because mounts at the latter path WILL NOT PERSIST database data when the container is re-created. The Dockerfile that builds the image declares a volume at `/var/lib/postgresql/data` and if no data volume is mounted at that path then the container runtime will automatically create an [anonymous volume](https://docs.docker.com/engine/storage/#volumes) that is not reused across container re-creations. Data will be written to the anonymous volume rather than your intended data volume and won't persist when the container is deleted and re-created.

This (`PGDATA`) is an environment variable that is not Docker specific. Because the variable is used by the `postgres` server binary (see the [PostgreSQL docs](https://www.postgresql.org/docs/14/app-postgres.html#id-1.9.5.14.7)), the entrypoint script takes it into account.

## Docker Secrets

As an alternative to passing sensitive information via environment variables, `_FILE` may be appended to some of the previously listed environment variables, causing the initialization script to load the values for those variables from files present in the container. In particular, this can be used to load passwords from Docker secrets stored in `/run/secrets/<secret_name>` files. For example:

```console
$ docker run --name some-postgres -e POSTGRES_PASSWORD_FILE=/run/secrets/postgres-passwd -d postgres
```

Currently, this is only supported for `POSTGRES_INITDB_ARGS`, `POSTGRES_PASSWORD`, `POSTGRES_USER`, and `POSTGRES_DB`.

## Initialization scripts

If you would like to do additional initialization in an image derived from this one, add one or more `*.sql`, `*.sql.gz`, or `*.sh` scripts under `/docker-entrypoint-initdb.d` (creating the directory if necessary). After the entrypoint calls `initdb` to create the default `postgres` user and database, it will run any `*.sql` files, run any executable `*.sh` scripts, and source any non-executable `*.sh` scripts found in that directory to do further initialization before starting the service.

**Warning**: scripts in `/docker-entrypoint-initdb.d` are only run if you start the container with a data directory that is empty; any pre-existing database will be left untouched on container startup. One common problem is that if one of your `/docker-entrypoint-initdb.d` scripts fails (which will cause the entrypoint script to exit) and your orchestrator restarts the container with the already initialized data directory, it will not continue on with your scripts.

For example, to add an additional user and database, add the following to `/docker-entrypoint-initdb.d/init-user-db.sh`:

```bash
#!/usr/bin/env bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
	CREATE USER docker;
	CREATE DATABASE docker;
	GRANT ALL PRIVILEGES ON DATABASE docker TO docker;
EOSQL
```

These initialization files will be executed in sorted name order as defined by the current locale, which defaults to `en_US.utf8`. Any `*.sql` files will be executed by `POSTGRES_USER`, which defaults to the `postgres` superuser. It is recommended that any `psql` commands that are run inside of a `*.sh` script be executed as `POSTGRES_USER` by using the `--username "$POSTGRES_USER"` flag. This user will be able to connect without a password due to the presence of `trust` authentication for Unix socket connections made inside the container.

Additionally, as of [docker-library/postgres#253](https://github.com/docker-library/postgres/pull/253), these initialization scripts are run as the `postgres` user (or as the "semi-arbitrary user" specified with the `--user` flag to `docker run`; see the section titled "Arbitrary `--user` Notes" for more details). Also, as of [docker-library/postgres#440](https://github.com/docker-library/postgres/pull/440), the temporary daemon started for these initialization scripts listens only on the Unix socket, so any `psql` usage should drop the hostname portion (see [docker-library/postgres#474 (comment)](https://github.com/docker-library/postgres/issues/474#issuecomment-416914741) for example).

## Database Configuration

There are many ways to set PostgreSQL server configuration. For information on what is available to configure, see the [PostgreSQL docs](https://www.postgresql.org/docs/14/runtime-config.html) for the specific version of PostgreSQL that you are running. Here are a few options for setting configuration:

-	Use a custom config file. Create a config file and get it into the container. If you need a starting place for your config file you can use the sample provided by PostgreSQL which is available in the container at `/usr/share/postgresql/postgresql.conf.sample` (`/usr/local/share/postgresql/postgresql.conf.sample` in Alpine variants).

	-	**Important note:** you must set `listen_addresses = '*'`so that other containers will be able to access postgres.

	```console
	$ # get the default config
	$ docker run -i --rm postgres cat /usr/share/postgresql/postgresql.conf.sample > my-postgres.conf

	$ # customize the config

	$ # run postgres with custom config
	$ docker run -d --name some-postgres -v "$PWD/my-postgres.conf":/etc/postgresql/postgresql.conf -e POSTGRES_PASSWORD=mysecretpassword postgres -c 'config_file=/etc/postgresql/postgresql.conf'
	```

-	Set options directly on the run line. The entrypoint script is made so that any options passed to the docker command will be passed along to the `postgres` server daemon. From the [PostgreSQL docs](https://www.postgresql.org/docs/14/app-postgres.html#id-1.9.5.14.6.3) we see that any option available in a `.conf` file can be set via `-c`.

	```console
	$ docker run -d --name some-postgres -e POSTGRES_PASSWORD=mysecretpassword postgres -c shared_buffers=256MB -c max_connections=200
	```

## Locale Customization

You can extend the Debian-based images with a simple `Dockerfile` to set a different locale. The following example will set the default locale to `de_DE.utf8`:

```dockerfile
FROM postgres:14.3
RUN localedef -i de_DE -c -f UTF-8 -A /usr/share/locale/locale.alias de_DE.UTF-8
ENV LANG de_DE.utf8
```

Since database initialization only happens on container startup, this allows us to set the language before it is created.

Also of note, Alpine-based variants starting with Postgres 15 support [ICU locales](https://www.postgresql.org/docs/15/locale.html#id-1.6.11.3.7). Previous Postgres versions based on alpine do *not* support locales; see ["Character sets and locale" in the musl documentation](https://wiki.musl-libc.org/functional-differences-from-glibc.html#Character-sets-and-locale) for more details.

You can set locales in the Alpine-based images with `POSTGRES_INITDB_ARGS` to set a different locale. The following example will set the default locale for a newly initialized database to `de_DE.utf8`:

```console
$ docker run -d -e LANG=de_DE.utf8 -e POSTGRES_INITDB_ARGS="--locale-provider=icu --icu-locale=de-DE" -e POSTGRES_PASSWORD=mysecretpassword postgres:15-alpine 
```

## Additional Extensions

When using the default (Debian-based) variants, installing additional extensions (such as PostGIS) should be as simple as installing the relevant packages (see [github.com/postgis/docker-postgis](https://github.com/postgis/docker-postgis/blob/81a0b55/14-3.2/Dockerfile) for a concrete example).

When using the Alpine variants, any postgres extension not listed in [postgres-contrib](https://www.postgresql.org/docs/14/contrib.html) will need to be compiled in your own image (again, see [github.com/postgis/docker-postgis](https://github.com/postgis/docker-postgis/blob/81a0b55/14-3.2/alpine/Dockerfile) for a concrete example).

# Arbitrary `--user` Notes

As of [docker-library/postgres#253](https://github.com/docker-library/postgres/pull/253), this image supports running as a (mostly) arbitrary user via `--user` on `docker run`. As of [docker-library/postgres#1018](https://github.com/docker-library/postgres/pull/1018), this is also the case for the Alpine variants.

The main caveat to note is that `postgres` doesn't care what UID it runs as (as long as the owner of `PGDATA` matches), but `initdb` *does* care (and needs the user to exist in `/etc/passwd`):

```console
$ docker run -it --rm --user www-data -e POSTGRES_PASSWORD=mysecretpassword postgres
The files belonging to this database system will be owned by user "www-data".
...

$ docker run -it --rm --user 1000:1000 -e POSTGRES_PASSWORD=mysecretpassword postgres
initdb: could not look up effective user ID 1000: user does not exist
```

The three easiest ways to get around this:

1.	allow the image to use [the `nss_wrapper` library](https://cwrap.org/nss_wrapper.html) to "fake" `/etc/passwd` contents for you (see [docker-library/postgres#448](https://github.com/docker-library/postgres/pull/448) for more details)

2.	bind-mount `/etc/passwd` read-only from the host (if the UID you desire is a valid user on your host):

	```console
	$ docker run -it --rm --user "$(id -u):$(id -g)" -v /etc/passwd:/etc/passwd:ro -e POSTGRES_PASSWORD=mysecretpassword postgres
	The files belonging to this database system will be owned by user "jsmith".
	...
	```

3.	initialize the target directory separately from the final runtime (with a `chown` in between):

	```console
	$ docker volume create pg
	$ docker run -it --rm -v pg:/var/lib/postgresql -e POSTGRES_PASSWORD=mysecretpassword postgres
	The files belonging to this database system will be owned by user "postgres".
	...
	( once it's finished initializing successfully and is waiting for connections, stop it )
	$ docker run -it --rm -v pg:/var/lib/postgresql bash chown -R 1000:1000 /var/lib/postgresql
	$ docker run -it --rm --user 1000:1000 -v pg:/var/lib/postgresql postgres
	LOG:  database system was shut down at 2017-01-20 00:03:23 UTC
	LOG:  MultiXact member wraparound protections are now enabled
	LOG:  autovacuum launcher started
	LOG:  database system is ready to accept connections
	```

# Caveats

If there is no database when `postgres` starts in a container, then `postgres` will create the default database for you. While this is the expected behavior of `postgres`, this means that it will not accept incoming connections during that time. This may cause issues when using automation tools, such as `docker compose`, that start several containers simultaneously.

Also note that the default `/dev/shm` size for containers is 64MB. If the shared memory is exhausted you will encounter `ERROR:  could not resize shared memory segment . . . : No space left on device`. You will want to pass [`--shm-size=256MB`](https://docs.docker.com/engine/reference/run/#runtime-constraints-on-resources) for example to `docker run`, or alternatively in [`docker compose`](https://docs.docker.com/compose/compose-file/05-services/#shm_size).

## Where to Store Data

**Important note:** There are several ways to store data used by applications that run in Docker containers. We encourage users of the `postgres` images to familiarize themselves with the options available, including:

-	Let Docker manage the storage of your database data [by writing the database files to disk on the host system using its own internal volume management](https://docs.docker.com/storage/volumes/). This is the default and is easy and fairly transparent to the user. The downside is that the files may be hard to locate for tools and applications that run directly on the host system, i.e. outside containers.
-	Create a data directory on the host system (outside the container) and [mount this to a directory visible from inside the container](https://docs.docker.com/storage/bind-mounts/). This places the database files in a known location on the host system, and makes it easy for tools and applications on the host system to access the files. The downside is that the user needs to make sure that the directory exists, and that e.g. directory permissions and other security mechanisms on the host system are set up correctly.

The Docker documentation is a good starting point for understanding the different storage options and variations, and there are multiple blogs and forum postings that discuss and give advice in this area. We will simply show the basic procedure here for the latter option above:

1.	Create a data directory on a suitable volume on your host system, e.g. `/my/own/datadir`.
2.	Start your `postgres` container like this:

	```console
	$ docker run --name some-postgres -v /my/own/datadir:/var/lib/postgresql -e POSTGRES_PASSWORD=mysecretpassword -d postgres:tag
	```

The `-v /my/own/datadir:/var/lib/postgresql` part of the command mounts the `/my/own/datadir` directory from the underlying host system as `/var/lib/postgresql` inside the container, where PostgreSQL by default will write its data files.

# Image Variants

The `postgres` images come in many flavors, each designed for a specific use case.

## `postgres:<version>`

This is the defacto image. If you are unsure about what your needs are, you probably want to use this one. It is designed to be used both as a throw away container (mount your source code and start the container to start your app), as well as the base to build other images off of.

Some of these tags may have names like bookworm or trixie in them. These are the suite code names for releases of [Debian](https://wiki.debian.org/DebianReleases) and indicate which release the image is based on. If your image needs to install any additional packages beyond what comes with the image, you'll likely want to specify one of these explicitly to minimize breakage when there are new releases of Debian.

## `postgres:<version>-alpine`

This image is based on the popular [Alpine Linux project](https://alpinelinux.org), available in [the `alpine` official image](https://hub.docker.com/_/alpine). Alpine Linux is much smaller than most distribution base images (~5MB), and thus leads to much slimmer images in general.

This variant is useful when final image size being as small as possible is your primary concern. The main caveat to note is that it does use [musl libc](https://musl.libc.org) instead of [glibc and friends](https://www.etalabs.net/compare_libcs.html), so software will often run into issues depending on the depth of their libc requirements/assumptions. See [this Hacker News comment thread](https://news.ycombinator.com/item?id=10782897) for more discussion of the issues that might arise and some pro/con comparisons of using Alpine-based images.

To minimize image size, it's uncommon for additional related tools (such as `git` or `bash`) to be included in Alpine-based images. Using this image as a base, add the things you need in your own Dockerfile (see the [`alpine` image description](https://hub.docker.com/_/alpine/) for examples of how to install packages if you are unfamiliar).

# License

View [license information](https://www.postgresql.org/about/licence/) for the software contained in this image.

As with all Docker images, these likely also contain other software which may be under other licenses (such as Bash, etc from the base distribution, along with any direct or indirect dependencies of the primary software being contained).

Some additional license information which was able to be auto-detected might be found in [the `repo-info` repository's `postgres/` directory](https://github.com/docker-library/repo-info/tree/master/repos/postgres).

As for any pre-built image usage, it is the image user's responsibility to ensure that any use of this image complies with any relevant licenses for all software contained within.
