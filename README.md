# Stackbrew

Stackbrew is a web-application that performs continuous building of the docker
standard library. See `README.md` in the stackbrew subfolder for more 
information.

## Library definition files

The library definition files are plain text files found in the `library/`
subfolder of the stackbrew repository.

### File names

The name of a definition file will determine the name of the image(s) it
creates. For example, the `library/ubuntu` file will create images in the
`<namespace>/ubuntu` repository. If multiple instructions are present in
a single file, all images are expected to be created under a different tag.

### Instruction format

Note: there is no backwards compatibility with the old format. This is part
of our effort to create strict, unambiguous references to build images upon.

	<docker-tag>:	<git-url>@<git-tag>
	2.4.0: 	git://github.com/dotcloud/docker-redis@2.4.0
	<docker-tag>:	<git-url>@<git-commit-id>
	2.2.0: 	git://github.com/dotcloud/docker-redis@a4bf8923ee4ec566d3ddc212

Stackbrew will fetch data from the provided git repository from the
provided reference. Generated image will be tagged as `<docker-tag>`.
If a git tag is removed and added to another commit,
**you should not expect the image to be rebuilt.** Create a new tag and submit
a pull request instead.

## Contributing to the standard library

Thank you for your interest in the stackbrew project! We strive to make these instructions as simple and straightforward as possible, but if you find yourself lost, don't hesitate to seek us out on IRC freenode, channel `#docker` or by creating a github issue.

### New repository.
* Create a new file in the library folder. Its name will be the name of your repository.
* Add your tag definitions using the provided syntax (see above).
* Add the following line to the MAINTAINERS file:
`repo: Your Name (github.name) <you@email.com>`
* Create a pull request from your git repository to this one. Don't hesitate to add details as to what your repository does.

### New tag in existing repository.
* Add your tag definition using the <provided syntax>
* Create a pull request from your git repository to this one. Don't hesitate to add details.
* In the pull request, mention the repository's maintainer using the `@` symbol.

### Change to an existing tag
* Propose a pull request to the origin repository. Don't hesitate to @-mention one of the stackbrew maintainers.
