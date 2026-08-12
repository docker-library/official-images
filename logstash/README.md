<!--

********************************************************************************

WARNING:

    DO NOT EDIT "logstash/README.md"

    IT IS AUTO-GENERATED

    (from the other files in "logstash/" combined with a set of templates)

********************************************************************************

-->

# Quick reference

-	**Maintained by**:  
	[the Elastic Team](https://github.com/elastic/logstash)

-	**Where to get help**:  
	the [Logstash Discuss Forums](https://discuss.elastic.co/c/logstash) and the [Elastic community](https://www.elastic.co/community).

# Supported tags and respective `Dockerfile` links

-	[`8.19.20`](https://github.com/elastic/dockerfiles/blob/65e33330fd4152f5bc6c4f85c098de67401e1fa5/logstash/Dockerfile)

-	[`9.4.5`](https://github.com/elastic/dockerfiles/blob/f157a1e5cea700c6504440331c5cf9999062a98c/logstash/Dockerfile)

-	[`9.5.1`](https://github.com/elastic/dockerfiles/blob/86e440e4ee31becb836575af98ef7c5a94134724/logstash/Dockerfile)

# Quick reference (cont.)

-	**Where to file issues**:  
	For issues with Logstash Docker Image or Logstash: https://github.com/elastic/logstash/issues

-	**Supported architectures**: ([more info](https://github.com/docker-library/official-images#architectures-other-than-amd64))  
	[`amd64`](https://hub.docker.com/r/amd64/logstash/), [`arm64v8`](https://hub.docker.com/r/arm64v8/logstash/)

-	**Published image artifact details**:  
	[repo-info repo's `repos/logstash/` directory](https://github.com/docker-library/repo-info/blob/master/repos/logstash) ([history](https://github.com/docker-library/repo-info/commits/master/repos/logstash))  
	(image metadata, transfer size, etc)

-	**Image updates**:  
	[official-images repo's `library/logstash` label](https://github.com/docker-library/official-images/issues?q=label%3Alibrary%2Flogstash)  
	[official-images repo's `library/logstash` file](https://github.com/docker-library/official-images/blob/master/library/logstash) ([history](https://github.com/docker-library/official-images/commits/master/library/logstash))

-	**Source of this description**:  
	[docs repo's `logstash/` directory](https://github.com/docker-library/docs/tree/master/logstash) ([history](https://github.com/docker-library/docs/commits/master/logstash))

# What is Logstash?

Logstash is an open source data collection engine with real-time pipelining capabilities. Logstash can dynamically unify data from disparate sources and normalize the data into destinations of your choice.

Collection is accomplished via a number of configurable input plugins including raw socket/packet communication, file tailing and several message bus clients. Once an input plugin has collected data it can be processed by any number of filters which modify and annotate the event data. Finally, events are routed to output plugins which can forward the events to a variety of external programs including Elasticsearch, local files and several message bus implementations.

> For more information about Logstash, please visit [www.elastic.co/products/logstash](https://www.elastic.co/products/logstash)

![logo](https://raw.githubusercontent.com/docker-library/docs/0ec96bc990cb13028308932386c3820d0de5d3c1/logstash/logo.png)

# About This Image

This default distribution is governed by the Elastic License and includes the [full set of free features](https://www.elastic.co/subscriptions).

View the detailed release notes [here](https://www.elastic.co/guide/en/logstash/current/releasenotes.html).

Not the version you're looking for? View all supported [past releases](https://www.docker.elastic.co).

# How to use this image

**Note:** Pulling an image requires using a specific version number tag. The `latest` tag is not supported.

For Logstash versions prior to 6.4.0, a full list of images, tags, and documentation can be found at [docker.elastic.co](https://www.docker.elastic.co/).

For full Logstash documentation see [here](https://www.elastic.co/guide/en/logstash/current/index.html).

For instructions specifically related to running the Docker image, see [this section](https://www.elastic.co/guide/en/logstash/current/docker-config.html) of the Logstash documentation.

# License

View [license information](https://github.com/elastic/logstash/blob/6.4/licenses/ELASTIC-LICENSE.txt) for the software contained in this image.

As with all Docker images, these likely also contain other software which may be under other licenses (such as Bash, etc from the base distribution, along with any direct or indirect dependencies of the primary software being contained).

Some additional license information which was able to be auto-detected might be found in [the `repo-info` repository's `logstash/` directory](https://github.com/docker-library/repo-info/tree/master/repos/logstash).

As for any pre-built image usage, it is the image user's responsibility to ensure that any use of this image complies with any relevant licenses for all software contained within.
