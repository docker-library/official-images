<!--

********************************************************************************

WARNING:

    DO NOT EDIT "oraclelinux/README.md"

    IT IS AUTO-GENERATED

    (from the other files in "oraclelinux/" combined with a set of templates)

********************************************************************************

-->

# Quick reference

-	**Maintained by**:  
	[the Oracle Linux Container Team](https://github.com/oracle/container-images)

-	**Where to get help**:  
	see the "Customer Support" and "Community Support" sections below

# Supported tags and respective `Dockerfile` links

-	[`10`](https://github.com/oracle/container-images/blob/facb59ab7a0cd1d951f934a0398908a103ab583a/10/Dockerfile)

-	[`10-slim`](https://github.com/oracle/container-images/blob/facb59ab7a0cd1d951f934a0398908a103ab583a/10-slim/Dockerfile)

-	[`9`](https://github.com/oracle/container-images/blob/facb59ab7a0cd1d951f934a0398908a103ab583a/9/Dockerfile)

-	[`9-slim`](https://github.com/oracle/container-images/blob/facb59ab7a0cd1d951f934a0398908a103ab583a/9-slim/Dockerfile)

-	[`9-slim-fips`](https://github.com/oracle/container-images/blob/facb59ab7a0cd1d951f934a0398908a103ab583a/9-slim-fips/Dockerfile)

-	[`8.10`, `8`](https://github.com/oracle/container-images/blob/facb59ab7a0cd1d951f934a0398908a103ab583a/8/Dockerfile)

-	[`8-slim`](https://github.com/oracle/container-images/blob/facb59ab7a0cd1d951f934a0398908a103ab583a/8-slim/Dockerfile)

-	[`8-slim-fips`](https://github.com/oracle/container-images/blob/facb59ab7a0cd1d951f934a0398908a103ab583a/8-slim-fips/Dockerfile)

-	[`7.9`, `7`](https://github.com/oracle/container-images/blob/facb59ab7a0cd1d951f934a0398908a103ab583a/7/Dockerfile)

-	[`7-slim`](https://github.com/oracle/container-images/blob/facb59ab7a0cd1d951f934a0398908a103ab583a/7-slim/Dockerfile)

-	[`7-slim-fips`](https://github.com/oracle/container-images/blob/facb59ab7a0cd1d951f934a0398908a103ab583a/7-slim-fips/Dockerfile)

# Quick reference (cont.)

-	**Where to file issues**:  
	[https://github.com/oracle/container-images/issues](https://github.com/oracle/container-images/issues?q=)

-	**Supported architectures**: ([more info](https://github.com/docker-library/official-images#architectures-other-than-amd64))  
	[`amd64`](https://hub.docker.com/r/amd64/oraclelinux/), [`arm64v8`](https://hub.docker.com/r/arm64v8/oraclelinux/)

-	**Published image artifact details**:  
	[repo-info repo's `repos/oraclelinux/` directory](https://github.com/docker-library/repo-info/blob/master/repos/oraclelinux) ([history](https://github.com/docker-library/repo-info/commits/master/repos/oraclelinux))  
	(image metadata, transfer size, etc)

-	**Image updates**:  
	[official-images repo's `library/oraclelinux` label](https://github.com/docker-library/official-images/issues?q=label%3Alibrary%2Foraclelinux)  
	[official-images repo's `library/oraclelinux` file](https://github.com/docker-library/official-images/blob/master/library/oraclelinux) ([history](https://github.com/docker-library/official-images/commits/master/library/oraclelinux))

-	**Source of this description**:  
	[docs repo's `oraclelinux/` directory](https://github.com/docker-library/docs/tree/master/oraclelinux) ([history](https://github.com/docker-library/docs/commits/master/oraclelinux))

# Oracle Linux

![logo](https://raw.githubusercontent.com/docker-library/docs/beed7adfe2814dd6e12207a2c58b515d87b8a184/oraclelinux/logo.png)

Oracle Linux is an open-source operating system available under the GNU General Public License (GPLv2). Suitable for general purpose or Oracle workloads, it benefits from rigorous testing of more than 128,000 hours per day with real- world workloads and includes unique innovations such as Ksplice for zero- downtime kernel patching, DTrace for real-time diagnostics, the powerful Btrfs file system, and more.

> **NOTE:** the `oraclelinux` image intentionally does *not* provide a `latest` tag. You must specify [an existing tag](https://hub.docker.com/_/oraclelinux?tab=tags) when referencing this image. See *"Removal of the `latest` tag"* below for further details.

## How to use these images

The Oracle Linux images are intended for use in the **FROM** field of a downstream `Dockerfile`. For example, to use the latest optimized Oracle Linux 8 image, specify `FROM oraclelinux:8`.

## Removal of `latest` tag

The `latest` tag was removed from the Oracle Linux official images in June 2020 to avoid breaking any downstream images caused by backwards-incompatible changes introduced by the release of a new version. Downstream images must specify the version, i.e. `oraclelinux:7` or `oraclelinux:8`.

### Differences between `oraclelinux:8` and `oraclelinux:8-slim`

Oracle recommends using `oraclelinux:8` for most images that extend Oracle Linux 8.

The `oraclelinux:8-slim` variant is intended primarily to provide "just enough user space" for statically compiled binaries or microservices. Use of the `8-slim` variant is discouraged for general purposes, due to the inclusion of `microdnf` in place of `dnf` and signficantly reduced locale data.

### Differences between `oraclelinux:7` and `oraclelinux:7-slim`

For images that want an Oracle Linux 7 user space, Oracle recommends using `oraclelinux:7-slim` as the base layer as it contains just enough packages for `yum` to be able to install more packages.

The `oraclelinux:7` images is based on the package set of what would be installed on a bare-metal server when performing a minimal install of Oracle Linux.

## Changelog

Oracle maintains a [CHANGELOG](https://github.com/oracle/container-images/blob/main/CHANGELOG.md) that documents by release date the errata applied and any CVE(s) that are mitigated in each update to the official images.

## Official Resources

-	[Oracle Linux documentation](https://docs.oracle.com/en/operating-systems/oracle-linux/index.html)
-	[Oracle Linux Yum Server](http://yum.oracle.com)
-	[Unbreakable Linux Network](https://linux.oracle.com)

## Customer Support

Oracle provides support to Oracle Linux subscription customers via the [My Oracle Support](https://support.oracle.com) portal. The Oracle Linux container images are covered by Oracle Linux Basic and Premier support subscriptions. Customers should follow existing support procedures to obtain support for Oracle Linux running in a container.

## Community Support

Users without an Oracle Linux support subscription should either [open an issue](https://github.com/oracle/container-images/issues) or [start a discussion](https://github.com/oracle/container-images/discussions) in the [Oracle Linux container image repository](https://github.com/oracle/container-images) on GitHub.

# License

View the [Oracle Linux End-User License Agreement](https://oss.oracle.com/ol/EULA) for the software contained in this image.

As with all Docker images, these likely also contain other software which may be under other licenses (such as Bash, etc from the base distribution, along with any direct or indirect dependencies of the primary software being contained).

Some additional license information which was able to be auto-detected might be found in [the `repo-info` repository's `oraclelinux/` directory](https://github.com/docker-library/repo-info/tree/master/repos/oraclelinux).

As for any pre-built image usage, it is the image user's responsibility to ensure that any use of this image complies with any relevant licenses for all software contained within.
