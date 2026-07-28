<!--

********************************************************************************

WARNING:

    DO NOT EDIT "photon/README.md"

    IT IS AUTO-GENERATED

    (from the other files in "photon/" combined with a set of templates)

********************************************************************************

-->

# Quick reference

-	**Maintained by**:  
	[VMware](https://github.com/vmware/photon-docker-image)

-	**Where to get help**:  
	[the Docker Community Slack](https://dockr.ly/comm-slack), [Server Fault](https://serverfault.com/help/on-topic), [Unix & Linux](https://unix.stackexchange.com/help/on-topic), or [Stack Overflow](https://stackoverflow.com/help/on-topic)

# Supported tags and respective `Dockerfile` links

-	[`5.0`, `5.0-20260727`, `latest`](https://github.com/vmware/photon-docker-image/blob/6d92cd0c93bcfbdb3fe09a72bdc6657f646fd012/docker/Dockerfile)

-	[`4.0`, `4.0-20260614`](https://github.com/vmware/photon-docker-image/blob/de810d1730962f8e379d53126fdc68624a4de5dd/docker/Dockerfile)

-	[`3.0`, `3.0-20250316`](https://github.com/vmware/photon-docker-image/blob/f848d5df815c0afe76b42a608d49df0e87af51c2/docker/Dockerfile)

# Quick reference (cont.)

-	**Where to file issues**:  
	[https://github.com/vmware/photon-docker-image/issues](https://github.com/vmware/photon-docker-image/issues?q=)

-	**Supported architectures**: ([more info](https://github.com/docker-library/official-images#architectures-other-than-amd64))  
	[`amd64`](https://hub.docker.com/r/amd64/photon/), [`arm64v8`](https://hub.docker.com/r/arm64v8/photon/)

-	**Published image artifact details**:  
	[repo-info repo's `repos/photon/` directory](https://github.com/docker-library/repo-info/blob/master/repos/photon) ([history](https://github.com/docker-library/repo-info/commits/master/repos/photon))  
	(image metadata, transfer size, etc)

-	**Image updates**:  
	[official-images repo's `library/photon` label](https://github.com/docker-library/official-images/issues?q=label%3Alibrary%2Fphoton)  
	[official-images repo's `library/photon` file](https://github.com/docker-library/official-images/blob/master/library/photon) ([history](https://github.com/docker-library/official-images/commits/master/library/photon))

-	**Source of this description**:  
	[docs repo's `photon/` directory](https://github.com/docker-library/docs/tree/master/photon) ([history](https://github.com/docker-library/docs/commits/master/photon))

# VMware Photon OS

![logo](https://raw.githubusercontent.com/docker-library/docs/de9a58372c9e1e58ccb08186ab6ebed278b86521/photon/logo.png)

Photon OS is an open source minimal Linux container host optimized for cloud-native applications, cloud platforms, and VMware infrastructure. It is designed to have a small footprint and boot extremely quickly on VMware platforms. Photon OS is intended to invite collaboration around running containerized applications in a virtualized environment.

Photon contains `tdnf`, a new, open-source, yum-compatible package manager that will help make the system as small as possible, but preserve the robust yum package management capabilities.

See the [FAQ](http://vmware.github.io/photon/assets/files/photon_faqs.pdf) for more information.

## How to use these images

Photon OS images are intended for use in the **FROM** field of an application's `Dockerfile`. For example, to use VMware Photon 1.0GA as the base of an image, specify `FROM photon:1.0GA`.

## Support

Photon OS is released as open source software and comes with no commercial support.

But since we want to ensure success and recognize that Photon OS™ consumers might fall into a range of roles - from developers that are steeped in the conventions of open-source to customers that are more accustomed to VMware commercial offerings, we offer several methods of engaging with the Photon OS team and community.

For our developer community, feel free to join our Google groups at [vmware-photon-os-dev](https://groups.google.com/forum/#%21forum/vmware-photon-dev)

For more general user questions, visit the Photon OS user forum in our [Photon OS VMware Community](http://communities.vmware.com/community/vmtn/devops/project-photon).

# License

View [license information](https://github.com/vmware/photon/blob/master/LICENSE) for the software contained in this image.

As with all Docker images, these likely also contain other software which may be under other licenses (such as Bash, etc from the base distribution, along with any direct or indirect dependencies of the primary software being contained).

Some additional license information which was able to be auto-detected might be found in [the `repo-info` repository's `photon/` directory](https://github.com/docker-library/repo-info/tree/master/repos/photon).

As for any pre-built image usage, it is the image user's responsibility to ensure that any use of this image complies with any relevant licenses for all software contained within.
