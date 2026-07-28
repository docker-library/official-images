<!--

********************************************************************************

WARNING:

    DO NOT EDIT "ibmjava/README.md"

    IT IS AUTO-GENERATED

    (from the other files in "ibmjava/" combined with a set of templates)

********************************************************************************

-->

# Quick reference

-	**Maintained by**:  
	[IBM Runtime Technologies](https://github.com/ibmruntimes/ci.docker)

-	**Where to get help**:  
	[the developerWorks forum for IBM Java Runtimes and SDKs](https://www.ibm.com/developerworks/community/forums/html/forum?id=11111111-0000-0000-0000-000000000367)

# Supported tags and respective `Dockerfile` links

-	[`8-jre`, `jre`, `8`, `latest`](https://github.com/ibmruntimes/ci.docker/blob/d909a041f0e0736b779516cac5a9612101d0eff5/ibmjava/8/jre/ubuntu/Dockerfile)

-	[`8-sfj`, `sfj`](https://github.com/ibmruntimes/ci.docker/blob/d909a041f0e0736b779516cac5a9612101d0eff5/ibmjava/8/sfj/ubuntu/Dockerfile)

-	[`8-sdk`, `sdk`](https://github.com/ibmruntimes/ci.docker/blob/d909a041f0e0736b779516cac5a9612101d0eff5/ibmjava/8/sdk/ubuntu/Dockerfile)

# Quick reference (cont.)

-	**Where to file issues**:  
	[GitHub](https://github.com/ibmruntimes/ci.docker/issues); for troubleshooting, see our [How Do I ...?](http://www.ibm.com/developerworks/java/jdk/howdoi/) page

-	**Supported architectures**: ([more info](https://github.com/docker-library/official-images#architectures-other-than-amd64))  
	[`amd64`](https://hub.docker.com/r/amd64/ibmjava/), [`ppc64le`](https://hub.docker.com/r/ppc64le/ibmjava/), [`s390x`](https://hub.docker.com/r/s390x/ibmjava/)

-	**Published image artifact details**:  
	[repo-info repo's `repos/ibmjava/` directory](https://github.com/docker-library/repo-info/blob/master/repos/ibmjava) ([history](https://github.com/docker-library/repo-info/commits/master/repos/ibmjava))  
	(image metadata, transfer size, etc)

-	**Image updates**:  
	[official-images repo's `library/ibmjava` label](https://github.com/docker-library/official-images/issues?q=label%3Alibrary%2Fibmjava)  
	[official-images repo's `library/ibmjava` file](https://github.com/docker-library/official-images/blob/master/library/ibmjava) ([history](https://github.com/docker-library/official-images/commits/master/library/ibmjava))

-	**Source of this description**:  
	[docs repo's `ibmjava/` directory](https://github.com/docker-library/docs/tree/master/ibmjava) ([history](https://github.com/docker-library/docs/commits/master/ibmjava))

### Overview

The images in this repository contain IBM® SDK, Java™ Technology Edition. For more information on the latest version and what's new, see [sdk8 on IBM developerWorks](https://developer.ibm.com/javasdk/downloads/sdk8/) and [jdk11 on IBM developerWorks](https://developer.ibm.com/javasdk/downloads/java-sdk-downloads-version-110/). See the license section for restrictions that relate to the use of this image. For more information about IBM® SDK, Java™ Technology Edition and API documentation as well as tutorials, recipes, and Java usage in IBM Cloud, see [IBM developerWorks](https://developer.ibm.com/javasdk/).

Java and all Java-based trademarks and logos are trademarks or registered trademarks of Oracle and/or its affiliates.

### Eclipse OpenJ9 Images

[Eclipse OpenJ9](https://www.eclipse.org/openj9) is a high performance, scalable, Java virtual machine (JVM) implementation that represents hundreds of person-years of effort. Contributed to the Eclipse project by IBM, the OpenJ9 JVM underpins the IBM SDK, Java Technology Edition product that is a core component of many IBM Enterprise software products. Continued development of OpenJ9 at the Eclipse foundation ensures wider collaboration, fresh innovation, and the opportunity to influence the development of OpenJ9 for the next generation of Java applications. The Eclipse OpenJ9 Docker images are available through [AdoptOpenJDK](https://adoptopenjdk.net/). They are available from [here](https://hub.docker.com/u/adoptopenjdk/).

### Images

There are three types of Docker images here: the Software Developers Kit (SDK), and the Java Runtime Environment (JRE) and a small footprint version of the JRE (SFJ). These images can be used as the basis for custom built images for running your applications.

##### Small Footprint JRE

The Small Footprint JRE ([SFJ](http://www.ibm.com/support/knowledgecenter/en/SSYKE2_8.0.0/com.ibm.java.lnx.80.doc/user/small_jre.html)) is designed specifically for web developers who want to develop and deploy cloud-based Java applications. Java tools and functions that are not required in the cloud environment, such as the Java control panel, are removed. The runtime environment is stripped down to provide core, essential function that has a greatly reduced disk and memory footprint.

##### Alpine Linux

Consider using [Alpine Linux](http://alpinelinux.org/) if you are concerned about the size of the overall image. Alpine Linux is a stripped down version of Linux that is based on [musl libc](http://wiki.musl-libc.org/wiki/Functional_differences_from_glibc) and Busybox, resulting in a [Docker image](https://hub.docker.com/_/alpine/) size of approximately 5 MB. Due to its extremely small size and reduced number of installed packages, it has a much smaller attack surface which improves security. IBM SDK has a dependency on gnu glibc, the sources can be found [here](https://github.com/sgerrand/docker-glibc-builder/releases/). Installing this library adds an extra 8 MB to the image size. The following table compares Docker Image sizes based on the JRE version `8.0-3.10`.

| JRE    | JRE    | SFJ    | SFJ    |
|:------:|:------:|:------:|:------:|
| Ubuntu | Alpine | Ubuntu | Alpine |
| 305 MB | 184 MB | 220 MB | 101 MB |

**Note: Alpine Linux is not an officially supported operating system for IBM® SDK, Java™ Technology Edition.**

##### Multi-Arch Image

Docker Images for the following architectures are now available:

-	[x86\_64](https://hub.docker.com/_/ibmjava/)
-	[i386](https://hub.docker.com/r/i386/ibmjava/)
-	[ppc64le](https://hub.docker.com/r/ppc64le/ibmjava/)
-	[s390x](https://hub.docker.com/r/s390x/ibmjava/)

ibmjava now has multi-arch support and so the exact same commands as below works on all supported architectures. This also means that it is no longer necessary to prefix the arch with the image name as that happens auto-magically.

### How to use this Image

To run a pre-built jar file with the JRE image, use the following commands:

```dockerfile
FROM ibmjava:jre
RUN mkdir /opt/app
COPY japp.jar /opt/app
CMD ["java", "-jar", "/opt/app/japp.jar"]
```

You can build and run the Docker Image as shown in the following example:

```console
docker build -t japp .
docker run -it --rm japp
```

If you want to place the jar file on the host file system instead of inside the container, you can mount the host path onto the container by using the following commands:

```dockerfile
FROM ibmjava:jre
CMD ["java", "-jar", "/opt/app/japp.jar"]
```

```console
docker build -t japp .
docker run -it -v /path/on/host/system/jars:/opt/app japp
```

### Using the Class Data Sharing feature

IBM SDK, Java Technology Edition provides a feature called [Class data sharing](http://www-01.ibm.com/support/knowledgecenter/SSYKE2_8.0.0/com.ibm.java.lnx.80.doc/diag/understanding/shared_classes.html). This mechanism offers transparent and dynamic sharing of data between multiple Java virtual machines (JVMs) running on the same host thereby reducing the amount of physical memory consumed by each JVM instance. By providing partially verified classes and possibly pre-loaded classes in memory, this mechanism also improves the start up time of the JVM.

To enable class data sharing between JVMs that are running in different containers on the same host, a common location must be shared between containers. This requirement can be satisfied through the host or a data volume container. When enabled, class data sharing creates a named "class cache", which is a memory-mapped file, at the common location. This feature is enabled by passing the `-Xshareclasses` option to the JVM as shown in the following Dockerfile example:

```dockerfile
FROM ibmjava:jre
RUN mkdir /opt/shareclasses
RUN mkdir /opt/app
COPY japp.jar /opt/app
CMD ["java", "-Xshareclasses:cacheDir=/opt/shareclasses", "-jar", "/opt/app/japp.jar"]
```

The `cacheDir` sub-option specifies the location of the class cache. For example `/opt/sharedclasses`. When sharing through the host, a host path must be mounted onto the container at the location the JVM expects to find the class cache. For example:

```console
docker build -t japp .
docker run -it -v /path/on/host/shareclasses/dir:/opt/shareclasses japp
```

When sharing through a data volume container, create a named data volume container that shares a volume.

```console
docker create -v /opt/shareclasses --name classcache japp /bin/true
```

Then start your JVM container by using `--volumes-from` flag to mount the shared volume, as shown in the following example:

```console
docker run -it --volumes-from classcache japp
```

### See Also

See the [Websphere-Liberty image](https://hub.docker.com/_/websphere-liberty/), which builds on top of this IBM docker image for Java.

# License

The Dockerfiles and associated scripts are licensed under the [Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0.html).

Licenses for the products installed within the images:

-	IBM® SDK, Java™ Technology Edition Version 8: [International License Agreement for Non-Warranted Programs](http://www14.software.ibm.com/cgi-bin/weblap/lap.pl?la_formnum=&li_formnum=L-SMKR-AVSEUH&title=IBM%AE+SDK%2C+Java%99+Technology+Edition%2C+Version+8.0&l=en).
-	IBM® SDK, Java™ Technology Edition Version 11: [International License Agreement for Non-Warranted Programs](http://www14.software.ibm.com/cgi-bin/weblap/lap.pl?la_formnum=&li_formnum=L-PARM-BMVULC&title=IBM%AE+SDK%2C+Java%99+Technology+Edition%2C+Version+11.0&l=en).

As with all Docker images, these likely also contain other software which may be under other licenses (such as Bash, etc from the base distribution, along with any direct or indirect dependencies of the primary software being contained).

Some additional license information which was able to be auto-detected might be found in [the `repo-info` repository's `ibmjava/` directory](https://github.com/docker-library/repo-info/tree/master/repos/ibmjava).

As for any pre-built image usage, it is the image user's responsibility to ensure that any use of this image complies with any relevant licenses for all software contained within.
