<!--

********************************************************************************

WARNING:

    DO NOT EDIT "xwiki/README.md"

    IT IS AUTO-GENERATED

    (from the other files in "xwiki/" combined with a set of templates)

********************************************************************************

-->

# Quick reference

-	**Maintained by**:  
	[the XWiki Community](https://github.com/xwiki-contrib/docker-xwiki)

-	**Where to get help**:  
	[the XWiki Forum](https://dev.xwiki.org/xwiki/bin/view/Community/Discuss) or [the XWiki Chat](https://dev.xwiki.org/xwiki/bin/view/Community/Chat)

# Supported tags and respective `Dockerfile` links

-	[`18`, `18.6`, `18.6.0`, `18-mysql-tomcat`, `18.6-mysql-tomcat`, `18.6.0-mysql-tomcat`, `mysql-tomcat`, `stable-mysql-tomcat`, `stable-mysql`, `stable`, `latest`](https://github.com/xwiki-contrib/docker-xwiki/blob/517b21e4883ea765bfaad6e7c9df7a02df6d9b4d/18/mysql-tomcat/Dockerfile)

-	[`18-postgres-tomcat`, `18.6-postgres-tomcat`, `18.6.0-postgres-tomcat`, `postgres-tomcat`, `stable-postgres-tomcat`, `stable-postgres`](https://github.com/xwiki-contrib/docker-xwiki/blob/517b21e4883ea765bfaad6e7c9df7a02df6d9b4d/18/postgres-tomcat/Dockerfile)

-	[`18-mariadb-tomcat`, `18.6-mariadb-tomcat`, `18.6.0-mariadb-tomcat`, `mariadb-tomcat`, `stable-mariadb-tomcat`, `stable-mariadb`](https://github.com/xwiki-contrib/docker-xwiki/blob/517b21e4883ea765bfaad6e7c9df7a02df6d9b4d/18/mariadb-tomcat/Dockerfile)

-	[`18.4`, `18.4.3`, `18.4-mysql-tomcat`, `18.4.3-mysql-tomcat`](https://github.com/xwiki-contrib/docker-xwiki/blob/9751db0dad201506527d4f6ff99a477825ed0e5b/18.4/mysql-tomcat/Dockerfile)

-	[`18.4-postgres-tomcat`, `18.4.3-postgres-tomcat`](https://github.com/xwiki-contrib/docker-xwiki/blob/9751db0dad201506527d4f6ff99a477825ed0e5b/18.4/postgres-tomcat/Dockerfile)

-	[`18.4-mariadb-tomcat`, `18.4.3-mariadb-tomcat`](https://github.com/xwiki-contrib/docker-xwiki/blob/9751db0dad201506527d4f6ff99a477825ed0e5b/18.4/mariadb-tomcat/Dockerfile)

-	[`17`, `17.10`, `17.10.11`, `17-mysql-tomcat`, `17.10-mysql-tomcat`, `17.10.11-mysql-tomcat`, `lts-mysql-tomcat`, `lts-mysql`, `lts`](https://github.com/xwiki-contrib/docker-xwiki/blob/89319b583acff4b148accae09182132eead71ded/17/mysql-tomcat/Dockerfile)

-	[`17-postgres-tomcat`, `17.10-postgres-tomcat`, `17.10.11-postgres-tomcat`, `lts-postgres-tomcat`, `lts-postgres`](https://github.com/xwiki-contrib/docker-xwiki/blob/89319b583acff4b148accae09182132eead71ded/17/postgres-tomcat/Dockerfile)

-	[`17-mariadb-tomcat`, `17.10-mariadb-tomcat`, `17.10.11-mariadb-tomcat`, `lts-mariadb-tomcat`, `lts-mariadb`](https://github.com/xwiki-contrib/docker-xwiki/blob/89319b583acff4b148accae09182132eead71ded/17/mariadb-tomcat/Dockerfile)

-	[`16`, `16.10`, `16.10.18`, `16-mysql-tomcat`, `16.10-mysql-tomcat`, `16.10.18-mysql-tomcat`](https://github.com/xwiki-contrib/docker-xwiki/blob/5f36889e1ddb59ea5fd856997fa4a47b83f641ba/16/mysql-tomcat/Dockerfile)

-	[`16-postgres-tomcat`, `16.10-postgres-tomcat`, `16.10.18-postgres-tomcat`](https://github.com/xwiki-contrib/docker-xwiki/blob/5f36889e1ddb59ea5fd856997fa4a47b83f641ba/16/postgres-tomcat/Dockerfile)

-	[`16-mariadb-tomcat`, `16.10-mariadb-tomcat`, `16.10.18-mariadb-tomcat`](https://github.com/xwiki-contrib/docker-xwiki/blob/5f36889e1ddb59ea5fd856997fa4a47b83f641ba/16/mariadb-tomcat/Dockerfile)

# Quick reference (cont.)

-	**Where to file issues**:  
	[the XWiki Docker JIRA project](https://jira.xwiki.org/browse/XDOCKER)

-	**Supported architectures**: ([more info](https://github.com/docker-library/official-images#architectures-other-than-amd64))  
	[`amd64`](https://hub.docker.com/r/amd64/xwiki/), [`arm64v8`](https://hub.docker.com/r/arm64v8/xwiki/)

-	**Published image artifact details**:  
	[repo-info repo's `repos/xwiki/` directory](https://github.com/docker-library/repo-info/blob/master/repos/xwiki) ([history](https://github.com/docker-library/repo-info/commits/master/repos/xwiki))  
	(image metadata, transfer size, etc)

-	**Image updates**:  
	[official-images repo's `library/xwiki` label](https://github.com/docker-library/official-images/issues?q=label%3Alibrary%2Fxwiki)  
	[official-images repo's `library/xwiki` file](https://github.com/docker-library/official-images/blob/master/library/xwiki) ([history](https://github.com/docker-library/official-images/commits/master/library/xwiki))

-	**Source of this description**:  
	[docs repo's `xwiki/` directory](https://github.com/docker-library/docs/tree/master/xwiki) ([history](https://github.com/docker-library/docs/commits/master/xwiki))

# What is XWiki

[XWiki](https://xwiki.org) is a free wiki software platform written in Java with a design emphasis on extensibility. XWiki is an enterprise wiki. It includes WYSIWYG editing, OpenDocument based document import/export, semantic annotations and tagging, and advanced permissions management.

As an application wiki, XWiki allows for the storing of structured data and the execution of server side script within the wiki interface. Scripting languages including Velocity, Groovy, Python, Ruby and PHP can be written directly into wiki pages using wiki macros. User-created data structures can be defined in wiki documents and instances of those structures can be attached to wiki documents, stored in a database, and queried using either Hibernate query language or XWiki's own query language.

[XWiki.org's extension wiki](https://extensions.xwiki.org) is home to XWiki extensions ranging from [code snippets](https://snippets.xwiki.org) which can be pasted into wiki pages to loadable core modules. Many of XWiki's features are provided by extensions which are bundled with it.

![logo](https://raw.githubusercontent.com/docker-library/docs/6fb07a8dacbad5cc548b87e4c267823a4aa98660/xwiki/logo.png)

# Usage

Please check the [documentation](https://www.xwiki.org/xwiki/bin/view/documentation/xs/admin/installation/methods/install-xwiki-docker/) to learn how to use the XWiki Docker images.

# License

XWiki is licensed under the [LGPL 2.1](https://github.com/xwiki/xwiki-docker/blob/master/LICENSE).

The Dockerfile repository is also licensed under the [LGPL 2.1](https://github.com/xwiki/xwiki-docker/blob/master/LICENSE).

As with all Docker images, these likely also contain other software which may be under other licenses (such as Bash, etc from the base distribution, along with any direct or indirect dependencies of the primary software being contained).

Some additional license information which was able to be auto-detected might be found in [the `repo-info` repository's `xwiki/` directory](https://github.com/docker-library/repo-info/tree/master/repos/xwiki).

As for any pre-built image usage, it is the image user's responsibility to ensure that any use of this image complies with any relevant licenses for all software contained within.
