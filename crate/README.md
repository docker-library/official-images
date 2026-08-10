<!--

********************************************************************************

WARNING:

    DO NOT EDIT "crate/README.md"

    IT IS AUTO-GENERATED

    (from the other files in "crate/" combined with a set of templates)

********************************************************************************

-->

# Quick reference

-	**Maintained by**:  
	[Crate.io](https://github.com/crate/docker-crate)

-	**Where to get help**:  
	[project documentation](https://crate.io/docs/), [StackOverflow](https://stackoverflow.com/tags/cratedb), [support channels](https://crate.io/support/)

# Supported tags and respective `Dockerfile` links

-	[`6.4.2`, `6.4`, `latest`](https://github.com/crate/docker-crate/blob/4517ee34c4140c29f9da1eb0c58027458821d8f0/Dockerfile)

-	[`6.3.7`, `6.3`](https://github.com/crate/docker-crate/blob/11157f4a7bb64d4210c9fcca8a10262712dc23d4/Dockerfile)

# Quick reference (cont.)

-	**Where to file issues**:  
	[https://github.com/crate/docker-crate/issues](https://github.com/crate/docker-crate/issues?q=)

-	**Supported architectures**: ([more info](https://github.com/docker-library/official-images#architectures-other-than-amd64))  
	[`amd64`](https://hub.docker.com/r/amd64/crate/), [`arm64v8`](https://hub.docker.com/r/arm64v8/crate/)

-	**Published image artifact details**:  
	[repo-info repo's `repos/crate/` directory](https://github.com/docker-library/repo-info/blob/master/repos/crate) ([history](https://github.com/docker-library/repo-info/commits/master/repos/crate))  
	(image metadata, transfer size, etc)

-	**Image updates**:  
	[official-images repo's `library/crate` label](https://github.com/docker-library/official-images/issues?q=label%3Alibrary%2Fcrate)  
	[official-images repo's `library/crate` file](https://github.com/docker-library/official-images/blob/master/library/crate) ([history](https://github.com/docker-library/official-images/commits/master/library/crate))

-	**Source of this description**:  
	[docs repo's `crate/` directory](https://github.com/docker-library/docs/tree/master/crate) ([history](https://github.com/docker-library/docs/commits/master/crate))

![logo](https://raw.githubusercontent.com/docker-library/docs/774acf9bf99ca29eded5cd50f0ba3f755716673d/crate/logo.svg?sanitize=true)

# What Is CrateDB?

[CrateDB](http://github.com/crate/crate) is a distributed SQL database that makes it simple to store and analyze massive amounts of machine data in real-time.

CrateDB offers the scalability and flexibility typically associated with a NoSQL database, is designed to run on inexpensive commodity servers and can be deployed and run on any sort of network - from personal computers to multi-region hybrid clouds.

The smallest CrateDB clusters can easily ingest tens of thousands of records per second. The data can be queried, ad-hoc, in parallel across the whole cluster in real time.

# Features

-	Standard SQL plus dynamic schemas, queryable objects, geospatial features, time series data, first-class BLOB support, and realtime full-text search.
-	Dynamic schemas, queryable objects, geospatial features, time series data support, and realtime full-text search providing functionality for handling both relational and document oriented nested data structures.
-	Horizontally scalable, highly available and fault tolerant clusters that run very well in virtualized and containerised environments.
-	Extremely fast distributed query execution.
-	Auto-partitioning, auto-sharding, and auto-replication.
-	Self-healing and auto-rebalancing.

# Screenshots

CrateDB provides an [Admin UI](https://crate.io/docs/crate/admin-ui/):

![Screenshots of the CrateDB Admin UI](https://raw.githubusercontent.com/crate/crate/master/crate-admin.gif)

# Try CrateDB

Spin up this Docker image like so:

```console
$ docker run --publish 4200:4200 --publish 5432:5432 crate -Cdiscovery.type=single-node
```

Visit the [getting started](https://crate.io/docs/crate/tutorials/en/latest/install-run/) page to see all the available download and install options.

Once you're up and running, head over to the [introductory docs](https://crate.io/docs/crate/tutorials/). To interact with CrateDB, you can use the Admin UI [web console](https://crate.io/docs/crate/admin-ui/en/latest/console.html#sql-console) or the [CrateDB shell](https://crate.io/docs/crate/crash/) CLI tool. Alternatively, review the list of recommended [clients and tools](https://crate.io/docs/crate/clients-tools/) that work with CrateDB.

For container-specific documentation, check out the [CrateDB on Docker how-to guide](https://crate.io/docs/crate/howtos/en/latest/deployment/containers/docker.html) or the [CrateDB on Kubernetes how-to guide](https://crate.io/docs/crate/howtos/en/latest/deployment/containers/kubernetes.html).

## Issues

### Memory Accounting

The combinations of Linux kernel version 3.x and Docker >= 1.12 could lead to a major problem with memory accounting causing the kernel to kill the CrateDB process in the container. This problems occurs because of a [slab shrinker issue](https://lwn.net/Articles/628829/) that is fixed in kernel versions >= 4.0.

### Others

For issue specific to the CrateDB Docker image, report issues via [the `docker-crate` GitHub issue tracker](https://github.com/crate/docker-crate/issues)

For issues with CrateDB itself, report issues via [the `crate` GitHub issue tracker](https://github.com/crate/crate/issues)

## Contributing

This image is primarily maintained by [Crate.io](http://crate.io/), but we welcome community contributions!

See the [contribution docs](https://github.com/crate/docker-crate/blob/master/CONTRIBUTING.rst) for more information.

# License

CrateDB is licensed under the Apache License 2.0.

See [LICENSE](https://github.com/crate/crate/blob/master/LICENSE) for more information.

As with all Docker images, these likely also contain other software which may be under other licenses (such as Bash, etc from the base distribution, along with any direct or indirect dependencies of the primary software being contained).

Some additional license information which was able to be auto-detected might be found in [the `repo-info` repository's `crate/` directory](https://github.com/docker-library/repo-info/tree/master/repos/crate).

As for any pre-built image usage, it is the image user's responsibility to ensure that any use of this image complies with any relevant licenses for all software contained within.
