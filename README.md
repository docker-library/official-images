# Docker Official Images

[![Build Status](https://travis-ci.org/docker-library/official-images.svg?branch=master)](https://travis-ci.org/docker-library/official-images)

## Contributing to the standard library

Thank you for your interest in the Docker official images project! We strive to make these instructions as simple and straightforward as possible, but if you find yourself lost, don't hesitate to seek us out on Freenode IRC in channel `#docker-library`, or by creating a GitHub issue here.

Be sure to familiarize yourself with the [Guidelines for Creating and Documenting Official Repositories](https://docs.docker.com/docker-hub/official_repos/) and the [Best practices for writing Dockerfiles](https://docs.docker.com/articles/dockerfile_best-practices/) in the Docker documentation.

Also, the Hub descriptions for these images are currently stored separately in the [docker-library/docs](https://github.com/docker-library/docs) repository.

## Library definition files

The library definition files are plain text files found in the `library/` subfolder of the official-images repository.

### File names

The name of a definition file will determine the name of the image(s) it creates. For example, the `library/ubuntu` file will create images in the `<namespace>/ubuntu` repository. If multiple instructions are present in a single file, all images are expected to be created under a different tag.

### Instruction format

	<docker-tag>: <git-url>@<git-commit-id>
	2.2.0: git://github.com/dotcloud/docker-redis@a4bf8923ee4ec566d3ddc212
	
	<docker-tag>: <git-url>@<git-tag>
	2.4.0: git://github.com/dotcloud/docker-redis@2.4.0
	
	<docker-tag>: <git-url>@<git-tag-or-commit-id> <dockerfile-dir>
	2.5.1: git://github.com/dotcloud/docker-redis@2.5.1 tools/dockerfiles/2.5.1

Bashbrew will fetch data from the provided git repository from the provided reference. Generated image will be tagged as `<docker-tag>`. If a git tag is removed and added to another commit, **you should not expect the image to be rebuilt.** Create a new tag and submit a pull request instead.

Optionally, if `<dockerfile-dir>` is present, Bashbrew will look for the `Dockerfile` inside the specified subdirectory instead of at the root (and `<dockerfile-dir>` will be used as the "context" for the build).

### Creating a new repository

-	Create a new file in the `library/` folder. Its name will be the name of your repository on the Hub.
-	Add your tag definitions using the appropriate syntax (see above).
-	Add a line similar to the following to the top of the file:

		# maintainer: Your Name <your@email.com> (@github.name)

-	Create a pull request adding the file from your forked repository to this one. Please be sure to add details as to what your repository does.

### Adding a new tag in an existing repository (that you're the maintainer of)

-	Add your tag definition using the instruction format documented above.
-	Create a pull request from your Git repository to this one. Please be sure to add details about what's new, if possible.
-	In the pull request comments, feel free to prod the repository's maintainers (found in the relevant `MAINTAINERS` file) using GitHub's @-mentions.

### Change to a tag in an existing repository (that you're the maintainer of)

-	Update the relevant tag definition using the instruction format documented above.
-	Create a pull request from your Git repository to this one. Please be sure to add details about what's changed, if possible.
-	In the pull request comments, feel free to prod the repository's maintainers (found in the relevant `MAINTAINERS` file) using GitHub's @-mentions.

## Bashbrew

Bashbrew is a set of bash scripts for cloning, building, tagging, and pushing the Docker official images. See [`README.md` in the `bashbrew/` subfolder](bashbrew/README.md) for more information.

## Stackbrew (deprecated)

Stackbrew is a web-application that performs continuous building of the Docker official images. See [`README.md` in the `stackbrew/` subfolder](stackbrew/README.md) for more information.
