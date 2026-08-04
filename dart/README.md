<!--

********************************************************************************

WARNING:

    DO NOT EDIT "dart/README.md"

    IT IS AUTO-GENERATED

    (from the other files in "dart/" combined with a set of templates)

********************************************************************************

-->

# Quick reference

-	**Maintained by**:  
	The Dart Docker Team

-	**Where to get help**:  
	[the Docker Community Slack](https://dockr.ly/comm-slack), [Server Fault](https://serverfault.com/help/on-topic), [Unix & Linux](https://unix.stackexchange.com/help/on-topic), or [Stack Overflow](https://stackoverflow.com/help/on-topic)

# Supported tags and respective `Dockerfile` links

-	[`3.12.2-sdk`, `3.12-sdk`, `3-sdk`, `stable-sdk`, `sdk`, `3.12.2`, `3.12`, `3`, `stable`, `latest`](https://github.com/dart-lang/dart-docker/blob/649c386683ddb20a76589d8518750d81d0b0df16/stable/trixie/Dockerfile)

-	[`3.13.0-282.4.beta-sdk`, `beta-sdk`, `3.13.0-282.4.beta`, `beta`](https://github.com/dart-lang/dart-docker/blob/649c386683ddb20a76589d8518750d81d0b0df16/beta/trixie/Dockerfile)

# Quick reference (cont.)

-	**Where to file issues**:  
	[https://github.com/dart-lang/dart-docker/issues](https://github.com/dart-lang/dart-docker/issues?q=)

-	**Supported architectures**: ([more info](https://github.com/docker-library/official-images#architectures-other-than-amd64))  
	[`amd64`](https://hub.docker.com/r/amd64/dart/), [`arm32v7`](https://hub.docker.com/r/arm32v7/dart/), [`arm64v8`](https://hub.docker.com/r/arm64v8/dart/), [`riscv64`](https://hub.docker.com/r/riscv64/dart/)

-	**Published image artifact details**:  
	[repo-info repo's `repos/dart/` directory](https://github.com/docker-library/repo-info/blob/master/repos/dart) ([history](https://github.com/docker-library/repo-info/commits/master/repos/dart))  
	(image metadata, transfer size, etc)

-	**Image updates**:  
	[official-images repo's `library/dart` label](https://github.com/docker-library/official-images/issues?q=label%3Alibrary%2Fdart)  
	[official-images repo's `library/dart` file](https://github.com/docker-library/official-images/blob/master/library/dart) ([history](https://github.com/docker-library/official-images/commits/master/library/dart))

-	**Source of this description**:  
	[docs repo's `dart/` directory](https://github.com/docker-library/docs/tree/master/dart) ([history](https://github.com/docker-library/docs/commits/master/dart))

# What is Dart?

Dart is an approachable, portable, and productive language for high-quality apps on any platform.

Its goal is to offer the most productive programming language for multi-platform development, paired with a flexible execution runtime platform for app frameworks, and support for full-stack development. For more details, see https://dart.dev.

By utilizing Dart's support for ahead-of-time (AOT) [compilation to executables](https://dart.dev/tools/dart-compile#exe), you can create very small runtime images (~10 MB).

## Using this image

We recommend using small runtime images that leverage Dart's support for ahead-of-time (AOT) [compilation to executables](https://dart.dev/tools/dart-build#build-a-cli-application). This enables creating small runtime images (~10 MB).

### Creating a Dart server app

After [installing](https://dart.dev/get-dart) the Dart SDK, version 2.14 or later, use the `dart` command to create a new server app:

```shell
$ dart create -t server-shelf myserver
```

### Running the server with Docker Desktop

If you have [Docker Desktop](https://www.docker.com/get-started) installed, you can build and run on your machine with the `docker` command:

```shell
$ docker build -t dart-server .
$ docker run -it --rm -p 8080:8080 --name myserver dart-server
```

When finished, you can stop the container using the name you provided:

```shell
$ docker kill myserver
```

## Image documentation

### `Dockerfile`

The `Dockerfile` created by the `dart` tool performs two steps:

1.	Using the Dart SDK in the `dart:stable` image, compiles your server (`bin/server.dart`) to an executable (`server`).

2.	Assembles the runtime image by combining the compiled server with the Dart VM runtime and it's needed dependencies located in `/runtime/`.

```Dockerfile
# Specify the Dart SDK base image version using dart:<version> (ex: dart:3.10)
FROM dart:stable AS build

# Resolve app dependencies.
WORKDIR /app
COPY pubspec.* ./
RUN dart pub get

# Copy app source code and AOT compile it.
COPY . .
# Ensure packages are still up-to-date if anything has changed
RUN dart pub get --offline
RUN dart build cli --target bin/server.dart -o output

# Build minimal serving image from AOT-compiled `/server` and required system
# libraries and configuration files stored in `/runtime/` from the build stage.
FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/output/bundle/ /app/

# Start server.
EXPOSE 8080
CMD ["/app/bin/server"]
```

### `.dockerignore`

Additionally it creates a recommended `.dockerignore` file, which enumarates files that should be omitted from the built Docker image:

```text
.dockerignore
Dockerfile
build/
.dart_tool/
.git/
.github/
.gitignore
.packages
```

--

Maintained with ❤️ by the [Dart](https://dart.dev) team.

# License

View [license information](https://github.com/dart-lang/sdk/blob/master/LICENSE) for the software contained in this image.

As with all Docker images, these likely also contain other software which may be under other licenses (such as Bash, etc from the base distribution, along with any direct or indirect dependencies of the primary software being contained).

Some additional license information which was able to be auto-detected might be found in [the `repo-info` repository's `dart/` directory](https://github.com/docker-library/repo-info/tree/master/repos/dart).

As for any pre-built image usage, it is the image user's responsibility to ensure that any use of this image complies with any relevant licenses for all software contained within.
