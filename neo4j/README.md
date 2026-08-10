<!--

********************************************************************************

WARNING:

    DO NOT EDIT "neo4j/README.md"

    IT IS AUTO-GENERATED

    (from the other files in "neo4j/" combined with a set of templates)

********************************************************************************

-->

# Quick reference

-	**Maintained by**:  
	[Neo4j](https://www.neo4j.com)

-	**Where to get help**:  
	[Neo4j Community Forums](https://community.neo4j.com), [Neo4j Docker Documentation](https://neo4j.com/docs/operations-manual/current/docker/), [Discord](https://discord.gg/neo4j)

# Supported tags and respective `Dockerfile` links

-	[`2026.07.1-community-trixie`, `2026.07-community-trixie`, `2026-community-trixie`, `2026.07.1-community`, `2026.07-community`, `2026-community`, `2026.07.1-trixie`, `2026.07-trixie`, `2026-trixie`, `2026.07.1`, `2026.07`, `2026`, `community-trixie`, `community`, `trixie`, `latest`](https://github.com/neo4j/docker-neo4j-publish/blob/30aa51289380be4976f77c17537645788abb33d3/2026.07.1/trixie/community/Dockerfile)

-	[`2026.07.1-enterprise-trixie`, `2026.07-enterprise-trixie`, `2026-enterprise-trixie`, `2026.07.1-enterprise`, `2026.07-enterprise`, `2026-enterprise`, `enterprise-trixie`, `enterprise`](https://github.com/neo4j/docker-neo4j-publish/blob/30aa51289380be4976f77c17537645788abb33d3/2026.07.1/trixie/enterprise/Dockerfile)

-	[`2026.07.1-community-ubi10`, `2026.07-community-ubi10`, `2026-community-ubi10`, `2026.07.1-ubi10`, `2026.07-ubi10`, `2026-ubi10`, `community-ubi10`, `ubi10`](https://github.com/neo4j/docker-neo4j-publish/blob/30aa51289380be4976f77c17537645788abb33d3/2026.07.1/ubi10/community/Dockerfile)

-	[`2026.07.1-enterprise-ubi10`, `2026.07-enterprise-ubi10`, `2026-enterprise-ubi10`, `enterprise-ubi10`](https://github.com/neo4j/docker-neo4j-publish/blob/30aa51289380be4976f77c17537645788abb33d3/2026.07.1/ubi10/enterprise/Dockerfile)

-	[`5.26.29-community-trixie`, `5.26-community-trixie`, `5-community-trixie`, `5.26.29-community`, `5.26-community`, `5-community`, `5.26.29-trixie`, `5.26-trixie`, `5-trixie`, `5.26.29`, `5.26`, `5`](https://github.com/neo4j/docker-neo4j-publish/blob/c42f844d726db728d4156888657ed7a1a25bef26/5.26.29/trixie/community/Dockerfile)

-	[`5.26.29-enterprise-trixie`, `5.26-enterprise-trixie`, `5-enterprise-trixie`, `5.26.29-enterprise`, `5.26-enterprise`, `5-enterprise`](https://github.com/neo4j/docker-neo4j-publish/blob/c42f844d726db728d4156888657ed7a1a25bef26/5.26.29/trixie/enterprise/Dockerfile)

-	[`5.26.29-community-ubi10`, `5.26-community-ubi10`, `5-community-ubi10`, `5.26.29-ubi10`, `5.26-ubi10`, `5-ubi10`](https://github.com/neo4j/docker-neo4j-publish/blob/c42f844d726db728d4156888657ed7a1a25bef26/5.26.29/ubi10/community/Dockerfile)

-	[`5.26.29-enterprise-ubi10`, `5.26-enterprise-ubi10`, `5-enterprise-ubi10`](https://github.com/neo4j/docker-neo4j-publish/blob/c42f844d726db728d4156888657ed7a1a25bef26/5.26.29/ubi10/enterprise/Dockerfile)

-	[`4.4.48`, `4.4.48-community`, `4.4`, `4.4-community`](https://github.com/neo4j/docker-neo4j-publish/blob/a3f58105abfd307a24467da003f46d4bd13813f3/4.4.48/bullseye/community/Dockerfile)

-	[`4.4.48-enterprise`, `4.4-enterprise`](https://github.com/neo4j/docker-neo4j-publish/blob/a3f58105abfd307a24467da003f46d4bd13813f3/4.4.48/bullseye/enterprise/Dockerfile)

# Quick reference (cont.)

-	**Where to file issues**:  
	[https://github.com/neo4j/docker-neo4j/issues](https://github.com/neo4j/docker-neo4j/issues?q=)

-	**Supported architectures**: ([more info](https://github.com/docker-library/official-images#architectures-other-than-amd64))  
	[`amd64`](https://hub.docker.com/r/amd64/neo4j/), [`arm64v8`](https://hub.docker.com/r/arm64v8/neo4j/)

-	**Published image artifact details**:  
	[repo-info repo's `repos/neo4j/` directory](https://github.com/docker-library/repo-info/blob/master/repos/neo4j) ([history](https://github.com/docker-library/repo-info/commits/master/repos/neo4j))  
	(image metadata, transfer size, etc)

-	**Image updates**:  
	[official-images repo's `library/neo4j` label](https://github.com/docker-library/official-images/issues?q=label%3Alibrary%2Fneo4j)  
	[official-images repo's `library/neo4j` file](https://github.com/docker-library/official-images/blob/master/library/neo4j) ([history](https://github.com/docker-library/official-images/commits/master/library/neo4j))

-	**Source of this description**:  
	[docs repo's `neo4j/` directory](https://github.com/docker-library/docs/tree/master/neo4j) ([history](https://github.com/docker-library/docs/commits/master/neo4j))

# What is Neo4j?

Neo4j is the world's leading graph database, with native graph storage and processing. You can learn more [here](http://neo4j.com).

![logo](https://raw.githubusercontent.com/docker-library/docs/56823e63d5b6dd7ddbb9d5d3c4a8947778055d8e/neo4j/logo.png)

# How to use this image

You can start a Neo4j container like this:

```console
docker run \
    --publish=7474:7474 --publish=7687:7687 \
    --volume=$HOME/neo4j/data:/data \
    neo4j
```

This binds two ports (`7474` and `7687`) for HTTP and Bolt access to the Neo4j API. A volume is bound to `/data` to allow the database to be persisted outside the container. Once running, you can use the [Neo4j Aura console](https://console.neo4j.io/ce) which includes graph tools for visualizations, data exploration, and monitoring for free. No subscription is required. Simply create a self-managed instance and specify `bolt://localhost:7687` or `http://localhost:7474` in the "Add Deployment" UI.

Alternatively, you can use the Neo4j Browser, a web-based user interface for interacting with Neo4j that is included with the Neo4j installation. To access the Neo4j Browser, open a web browser and navigate to http://localhost:7474.

Your default credentials are neo4j/neo4j. You will be prompted to change the password upon first login. For development purposes, you can disable authentication by passing `--env=NEO4J_AUTH=none` to docker run.

# Documentation

For more examples and complete documentation please go to our manual [here](http://neo4j.com/docs/operations-manual/current/deployment/single-instance/docker/).

# License

View [licensing information](https://neo4j.com/licensing) for the software contained in this image.

As with all Docker images, these likely also contain other software which may be under other licenses (such as Bash, etc from the base distribution, along with any direct or indirect dependencies of the primary software being contained).

Some additional license information which was able to be auto-detected might be found in [the `repo-info` repository's `neo4j/` directory](https://github.com/docker-library/repo-info/tree/master/repos/neo4j).

As for any pre-built image usage, it is the image user's responsibility to ensure that any use of this image complies with any relevant licenses for all software contained within.
