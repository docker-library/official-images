<!--

********************************************************************************

WARNING:

    DO NOT EDIT "silverpeas/README.md"

    IT IS AUTO-GENERATED

    (from the other files in "silverpeas/" combined with a set of templates)

********************************************************************************

-->

# Quick reference

-	**Maintained by**:  
	[Silverpeas](https://github.com/Silverpeas/docker-silverpeas-prod)

-	**Where to get help**:  
	[the Silverpeas user mailing list](https://groups.google.com/forum/#!forum/silverpeas-users)

# Supported tags and respective `Dockerfile` links

-	[`6.4.7`, `6.4`, `latest`](https://github.com/Silverpeas/docker-silverpeas-prod/blob/143ba37b837ac7ac3f455d7cc4d873ada394e770/Dockerfile)

-	[`6.3.6`, `6.3`](https://github.com/Silverpeas/docker-silverpeas-prod/blob/fb25885d1cd43172693b3acf79e9fac056a9db34/Dockerfile)

# Quick reference (cont.)

-	**Where to file issues**:  
	[https://github.com/Silverpeas/docker-silverpeas-prod/issues](https://github.com/Silverpeas/docker-silverpeas-prod/issues?q=)

-	**Supported architectures**: ([more info](https://github.com/docker-library/official-images#architectures-other-than-amd64))  
	[`amd64`](https://hub.docker.com/r/amd64/silverpeas/)

-	**Published image artifact details**:  
	[repo-info repo's `repos/silverpeas/` directory](https://github.com/docker-library/repo-info/blob/master/repos/silverpeas) ([history](https://github.com/docker-library/repo-info/commits/master/repos/silverpeas))  
	(image metadata, transfer size, etc)

-	**Image updates**:  
	[official-images repo's `library/silverpeas` label](https://github.com/docker-library/official-images/issues?q=label%3Alibrary%2Fsilverpeas)  
	[official-images repo's `library/silverpeas` file](https://github.com/docker-library/official-images/blob/master/library/silverpeas) ([history](https://github.com/docker-library/official-images/commits/master/library/silverpeas))

-	**Source of this description**:  
	[docs repo's `silverpeas/` directory](https://github.com/docker-library/docs/tree/master/silverpeas) ([history](https://github.com/docker-library/docs/commits/master/silverpeas))

# What is Silverpeas

[Silverpeas](https://www.silverpeas.org) is a Collaborative and Social-Networking Portal built to facilitate and to leverage the collaboration, the knowledge-sharing and the feedback of persons, teams and organizations.

Accessible from a simple web browser or from a smartphone, Silverpeas is used every days by ourselves. With about 30 ready-to-use applications and with its conversional and relational functions, it makes possible for users to work together, share their knowledge and good practices, and in general to improve their reciprocal empathy, therefore their willingness to collaborate.

Silverpeas is usually used as an intranet and extranet platform dedicated to collaboration and information sharing.

![logo](https://raw.githubusercontent.com/docker-library/docs/f0d096186294d86320e52224d7c8dabf450c17eb/silverpeas/logo.png)

# How to use this image

Docker images of Silverpeas require one of the following database system in order to be used:

-	the open-source, powerful and recommended PostgreSQL database system,
-	the Microsoft SQLServer database system,
-	the Oracle database system.

The Silverpeas images support actually only the two first database systems; because of the non-free licensing issues with the Oracle JDBC drivers, Silverpeas cannot include these drivers by default and consequently it cannot use transparently an Oracle database system as a persistence backend.

For the same reasons, the Docker images of Silverpeas aren't shipped with the Oracle JVM but with OpenJDK. Silverpeas uses the Wildfly application server as runtime.

The Silverpeas images use the following environment variables to set the database access parameters:

-	`DB_SERVERTYPE` to specify the database system to use with Silverpeas: POSTGRESQL for PostgreSQL, MSSQL for Microsoft SQLServer, ORACLE for Oracle. By default, it is set to POSTGRESQL.
-	`DB_SERVER` to specify the IP address or the name of the host on which the database system is running. By default, it is set to `database`, so that any container running a database can be linked to the Silverpeas container with this name.
-	`DB_NAME` to specify the database to use with Silverpeas. By default, it is set to `Silverpeas`.
-	`DB_USER` to specify the user identifier to use by Silverpeas to access the database. By default, it is set to `silverpeas` (it is recommended to dedicate a user account in the database for each application).
-	`DB_PASSWORD` to specify the password associated with the user identifier above.

These environment variables can be also defined as properties into the Silverpeas global configuration file `config.properties` (see below).

## Start a Silverpeas instance with a database from a Docker container

In [Docker Hub](https://hub.docker.com/), no Docker images of Microsoft SQLServer are currently available, but you will find a lot of images of PostgreSQL. For example, with an [official PostgreSQL docker image](https://hub.docker.com/_/postgres/), you can start a PostgreSQL instance initialized with a superuser `postgres` with as password `mysecretpassword`:

```console
$ docker run --name postgresql -d \
    -e POSTGRES_PASSWORD="mysecretpassword" \
    -v postgresql-data:/var/lib/postgresql/data \
    postgres:12.3
```

We recommend strongly to mount the directory with the database file on the host so the data won't be lost when upgrading PostgreSQL to a newer version (a Data Volume Container can be used instead). For any information how to start a PostgreSQL container, you can refer its [documentation](https://hub.docker.com/_/postgres/).

Once the database system is running, a database for Silverpeas has to be created and a user with administrative rights on this database (and only on this database) should be added; it is recommended for a security reason to create a dedicated user account in the database for each application and therefore for Silverpeas. In this document, and by default, a database `Silverpeas` and a user `silverpeas` for that database are created. For example:

```console
$ docker exec -it postgresql psql -U postgres
psql (12.3 (Debian 12.3-1.pgdg100+1))
Type "help" for help.

postgres=# create database "Silverpeas";
CREATE DATABASE
postgres=# create user silverpeas with password 'thesilverpeaspassword';
CREATE ROLE
postgres=# grant all privileges on database "Silverpeas" to silverpeas;
GRANT
postgres=# \q
$
```

### Start a Silverpeas instance with the default configuration

Finally, a Silverpeas instance can be started by specifying the required database access parameters with the environment variables. In the example, the database is named `Silverpeas` and the priviledged user is `silverpeas` with as password `thesilverpeaspassword`:

```console
$ docker run --name silverpeas -p 8080:8000 -d \
    -e DB_NAME="Silverpeas" \
    -e DB_USER="silverpeas" \
    -e DB_PASSWORD="thesilverpeaspassword" \
    -v silverpeas-log:/opt/silverpeas/log \
    -v silverpeas-data:/opt/silverpeas/data \
    --link postgresql:database \
    silverpeas
```

By default, `database` is the default hostname used by Silverpeas for its persistence backend. So, as the PostgreSQL database is linked here under the alias `database`, we don't have to explicitly indicate its hostname with the `DB_SERVER` environment variable. The Silverpeas images expose the 8000 port and here this port is mapped to the 8080 port of the host.

Silverpeas is then accessible at [http://localhost:8080/silverpeas](http://localhost:8080/silverpeas). You can sign in Silverpeas with the administrator account `SilverAdmin` and with as password `SilverAdmin`. Don't forget to change the password of the administrator account.

By default, some volumes are created inside the container, so that we can access them in the host. (Refers the [Docker Documentation](https://docs.docker.com/engine/tutorials/dockervolumes/#locating-a-volume) to locate them.) Among them `/opt/silverpeas/log` and `/opt/silverpeas/data`: the first volume contains the logs produced by Silverpeas whereas the second volume contains all the data that are created and managed by the users in Silverpeas. Because the latter has already a directories structure created at image creation, a host directory cannot be mounted into the container at `opt/silverpeas/data` without losing the volume's content (the mount point overlays the pre-existing content of the volume). In our example, in order to easily locate the two volumes, we label them explicitly with respectively the labels `silverpeas-log` and `silverpeas-data`. (Using a [Data Volume Container](https://docs.docker.com/engine/userguide/containers/dockervolumes/) to map `/opt/silverpeas/log` and `/opt/silverpeas/data` is a better solution.)

Silverpeas takes some time to start, so we recommend you to glance at the logs the complete starting of Silverpeas (see the section about the logs).

### Start a Silverpeas instance with a finer configuration

The Silverpeas global configuration is defined in the `/opt/silverpeas/configuration/config.properties` file whose a sample can be found [here](https://raw.githubusercontent.com/Silverpeas/Silverpeas-Distribution/master/src/main/dist/configuration/sample_config.properties) or in the container directory `/opt/silverpeas/configuration/`. You can explicitly create the `config.properties` file with, additionally to the database access parameters (don't forget in that case to specify the `DB_SERVER` property with as value `database`), your peculiar configuration parameters and then start a Silverpeas instance with this configuration file:

```console
$ docker run --name silverpeas -p 8080:8000 -d \
    -v /etc/silverpeas/config.properties:/opt/silverpeas/configuration/config.properties
    -v silverpeas-log:/opt/silverpeas/log \
    -v silverpeas-data:/opt/silverpeas/data \
    --link postgresql:database \
    silverpeas
```

where `/etc/silverpeas/config.properties` is your own configuration file on the host. For security reason, we strongly recommend to set explicitly the administrator's credentials with the properties `SILVERPEAS_ADMIN_LOGIN` and `SILVERPEAS_ADMIN_PASSWORD` in the `config.properties` file. (Don't forget to set also the administrator email address with the property `SILVERPEAS_ADMIN_EMAIL`.)

Below an example of such a configuration file:

	SILVERPEAS_ADMIN_LOGIN=SilverAdmin
	SILVERPEAS_ADMIN_PASSWORD=theadministratorpassword
	SILVERPEAS_ADMIN_EMAIM=admin@foo.com
	
	DB_SERVERTYPE=POSTGRESQL
	DB_SERVER=database
	DB_NAME=Silverpeas
	DB_USER=silverpeas
	DB_PASSWORD=thesilverpeaspassword
	
	CONVERTER_HOST=libreoffice
	CONVERTER_PORT=8997
	
	SMTP_SERVER=smtp.foo.com
	SMTP_AUTHENTICATION=true
	SMTP_DEBUG=false
	SMTP_PORT=465
	SMTP_USER=silverpeas
	SMTP_PASSWORD=thesmtpsilverpeaspassword
	SMTP_SECURE=true

## Start a Silverpeas instance with a database on the host

For a database system running on the host (or on a remote host) with 192.168.1.14 as IP address, you have to specify this host both to the container at starting and to Silverpeas by defining it into its global configuration file:

```console
$ docker run --name silverpeas -p 8080:8000 -d \
    --add-host=database:192.168.1.14 \
    -v /etc/silverpeas/config.properties:/opt/silverpeas/configuration/config.properties \
    -v silverpeas-log:/opt/silverpeas/log \
    -v silverpeas-data:/opt/silverpeas/data \
    silverpeas
```

where `database` is the hostname referred by the `DB_SERVER` parameter in your `/etc/silverpeas/config.properties` file as the host running the database system and that is mapped here to the actual IP address of this host. The hostname is added in the `/etc/hosts` file in the container.

For a PostgreSQL database system, some configurations are required in order to be accessed from the Silverpeas container:

-	In the file `postgresql.conf`, edit the parameter `listen_addresses` to add the address of the PostgreSQL host (`192.168.1.14` in our example)

	listen_addresses = 'localhost,192.168.1.14'

-	In the file `pg_hba.conf`, add an entry for the Docker subnetwork

	host all all 172.17.0.0/16 md5

-	Don't forget to restart PostgreSQL for the changes to be taken into account.

# Using a Data Volume Container

The data produced by Silverpeas mean to be persistent, available to the next versions of Silverpeas, and they have to be accessible to other containers like the one running LibreOffice. For doing, the Docker team recommends to use a Data Volume Container.

In Silverpeas, there are four types of data produced by the application:

-	the logging stored in `/opt/silverpeas/log`,
-	the user data and those produced by Silverpeas from the user data in `/opt/silverpeas/data`,
-	the workflows created by the workflow editor in `/opt/silverpeas/xmlcomponents/workflows`.

Beside these directories, according to your specific needs, custom configuration scripts can be added in the directories `/opt/silverpeas/configuration/jboss` and `/opt/silverpeas/configuration/silverpeas`.

The directories `/opt/silverpeas/log`, `/opt/silverpeas/data`, and `/opt/silverpeas/xmlcomponents/workflows` are all defined as volumes in the Docker image.

All these different kind of data have to be consistent for a given state of Silverpeas; they form a coherent whole set. Then, defining a Data Volume Container to gather all of these volumes is a better solution over multiple shared-storage volume definitions. You can, with a such Data Volume Container, backup, restore or migrate more easily the full set of the data of Silverpeas.

To define a Data Volume Container for Silverpeas, for example:

```console
$ docker create --name silverpeas-store \
    -v silverpeas-data:/opt/silverpeas/data \
    -v silverpeas-log:/opt/silverpeas/log \
    -v silverpeas-workflows:/opt/silverpeas/xmlcomponents/workflows \
    -v /etc/silverpeas/config.properties:/opt/silverpeas/configuration/config.properties \
    silverpeas \
    /bin/true
```

Then to mount the volumes in the Silverpeas container:

```console
$ docker run --name silverpeas -p 8080:8000 -d \
    --link postgresql:database \
    --volumes-from silverpeas-store \
    silverpeas
```

If you have to customize the settings of Silverpeas or add, for example, a new database definition, then specify these settings with the Data Volume Container, so that they will be available to the next versions of Silverpeas which will be then configured correctly like your previous Silverpeas installation:

```console
$ docker create --name silverpeas-store \
    -v silverpeas-data:/opt/silverpeas/data \
    -v silverpeas-log:/opt/silverpeas/log \
    -v silverpeas-properties:/opt/silverpeas/properties \
    -v /etc/silverpeas/config.properties:/opt/silverpeas/configuration/config.properties \
    -v /etc/silverpeas/CustomerSettings.xml:/opt/silverpeas/configuration/silverpeas/CustomerSettings.xml \
    -v /etc/silverpeas/my-datasource.cli:/opt/silverpeas/configuration/jboss/my-datasource.cli \
    silverpeas \
    /bin/true
```

# Logs

You can follow the activity of Silverpeas by watching the logs generated in the mounted `/opt/silverpeas/log` directory.

The output of Wildfly is redirected into the container standard output and so it can be watched as following:

```console
$ docker logs -f silverpeas
```

Silverpeas takes some time to start, so we recommend you to glance at the logs for the complete starting of Silverpeas.

# License

View [license information](https://www.silverpeas.org/legal/licensing_gnu_affero.html) for the software contained in this image.

Silverpeas uses FLOSS softwares. These are (in a non exhaustive list):

-	Libraries under the MIT license like JQuery and Angular JS.
-	Libraries and applications under the Apache 2.0 license like the Apache Commons libraries and the Image Magick tool.
-	Libraries and applications under the GPL/LGPL license like SWFTools, FlexPaper Flash GPL, LibreOffice, OpenJDK.

As with all Docker images, these likely also contain other software which may be under other licenses (such as Bash, etc from the base distribution, along with any direct or indirect dependencies of the primary software being contained).

Some additional license information which was able to be auto-detected might be found in [the `repo-info` repository's `silverpeas/` directory](https://github.com/docker-library/repo-info/tree/master/repos/silverpeas).

As for any pre-built image usage, it is the image user's responsibility to ensure that any use of this image complies with any relevant licenses for all software contained within.
