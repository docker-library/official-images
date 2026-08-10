<!--

********************************************************************************

WARNING:

    DO NOT EDIT "archlinux/README.md"

    IT IS AUTO-GENERATED

    (from the other files in "archlinux/" combined with a set of templates)

********************************************************************************

-->

# Quick reference

-	**Maintained by**:  
	Arch Linux trusted users [Santiago Torres-Arias](https://www.archlinux.org/people/trusted-users/#sangy), [Christian Rebischke](https://www.archlinux.org/people/trusted-users/#shibumi) and [Justin Kromlinger](https://www.archlinux.org/people/trusted-users/#hashworks) as well as Arch Linux developer [Pierre Schmitz](https://www.archlinux.org/people/developers/#pierre).

-	**Where to get help**:  
	[the Docker Community Slack](https://dockr.ly/comm-slack), [Server Fault](https://serverfault.com/help/on-topic), [Unix & Linux](https://unix.stackexchange.com/help/on-topic), or [Stack Overflow](https://stackoverflow.com/help/on-topic)

# Supported tags and respective `Dockerfile` links

-	[`latest`, `base`, `base-20260809.0.570793`](https://gitlab.archlinux.org/archlinux/archlinux-docker/-/blob/9bab5146b3ca12a08387de50035d815a297f6046/Dockerfile.base)

-	[`base-devel`, `base-devel-20260809.0.570793`](https://gitlab.archlinux.org/archlinux/archlinux-docker/-/blob/9bab5146b3ca12a08387de50035d815a297f6046/Dockerfile.base-devel)

-	[`multilib-devel`, `multilib-devel-20260809.0.570793`](https://gitlab.archlinux.org/archlinux/archlinux-docker/-/blob/9bab5146b3ca12a08387de50035d815a297f6046/Dockerfile.multilib-devel)

# Quick reference (cont.)

-	**Where to file issues**:  
	https://gitlab.archlinux.org/archlinux/archlinux-docker/issues

-	**Supported architectures**: ([more info](https://github.com/docker-library/official-images#architectures-other-than-amd64))  
	[`amd64`](https://hub.docker.com/r/amd64/archlinux/)

-	**Published image artifact details**:  
	[repo-info repo's `repos/archlinux/` directory](https://github.com/docker-library/repo-info/blob/master/repos/archlinux) ([history](https://github.com/docker-library/repo-info/commits/master/repos/archlinux))  
	(image metadata, transfer size, etc)

-	**Image updates**:  
	[official-images repo's `library/archlinux` label](https://github.com/docker-library/official-images/issues?q=label%3Alibrary%2Farchlinux)  
	[official-images repo's `library/archlinux` file](https://github.com/docker-library/official-images/blob/master/library/archlinux) ([history](https://github.com/docker-library/official-images/commits/master/library/archlinux))

-	**Source of this description**:  
	[docs repo's `archlinux/` directory](https://github.com/docker-library/docs/tree/master/archlinux) ([history](https://github.com/docker-library/docs/commits/master/archlinux))

# What is Arch Linux?

Arch Linux, is a lightweight and flexible Linux® distribution that tries to Keep It Simple.

Currently, we have official packages optimized for the x86-64 architecture. We complement our official package sets with a community-operated package repository that grows in size and quality each and every day.

Our strong community is diverse and helpful, and we pride ourselves on the range of skill sets and uses for Arch that stem from it. Please check out our forums and mailing lists to get your feet wet. Also glance through our [wiki](https://wiki.archlinux.org) if you want to learn more about Arch.

![logo](https://raw.githubusercontent.com/docker-library/docs/ccacad8fa355ebf38dcfd8c216855ab55f981f17/archlinux/logo.png)

# About this image

The root filesystem tarball for this image is auto-generated weekly at 00:00 UTC on Sunday in Arch Linux infrastructure. Given the rolling-release nature of Arch Linux, images are tagged with the included meta package and the timestamp of the date they were generated. For example, `archlinux:base-20201101.0.7893` was generated the First of November 2020 in [CI job #7893](https://gitlab.archlinux.org/archlinux/archlinux-docker/-/jobs/7893). The `latest` tag will always match the latest `base` tag.

Besides `base` we also provide images for the `base-devel` and `multilib-devel` meta packages.

This image is intended to serve the following goals:

-	Provide the Arch experience in a Docker Image
-	Provide simplest but complete image to `base`, `base-devel` and `multilib-devel` on a regular basis
-	`pacman` needs to work out of the box
-	All installed packages have to be kept unmodified

> ⚠️⚠️⚠️ NOTE: For Security Reasons, these images strip the pacman lsign key. This is because the same key would be spread to all containers of the same image, allowing for malicious actors to inject packages (via, for example, a man-in-the-middle). In order to create a lsign-key run `pacman-key --init` on the first execution, but be careful to not redistribute that key. ⚠️⚠️⚠️

## Availability

Root filesystem tarballs are [provided by our GitLab](https://gitlab.archlinux.org/archlinux/archlinux-docker/-/releases) for at least two months.

## Updating

Arch Linux is a rolling release distribution, so a full update is recommended when installing new packages. In other words, we suggest to either execute `RUN pacman -Syu` immediately after your `FROM` statement or as soon as you `docker run` into a container.

## How It's Made

You can build this image with the tools on the [Arch Linux GitLab repository](https://gitlab.archlinux.org/archlinux/archlinux-docker) using the included makefile.

# License

The Docker image creation scripts contained under the repository archlinux are licensed under GPLv3. All the licensing information for the packages contained in it can be found under `/usr/share/licenses/` inside of the image.

As with all Docker images, these likely also contain other software which may be under other licenses (such as Bash, etc from the base distribution, along with any direct or indirect dependencies of the primary software being contained).

Some additional license information which was able to be auto-detected might be found in [the `repo-info` repository's `archlinux/` directory](https://github.com/docker-library/repo-info/tree/master/repos/archlinux).

As for any pre-built image usage, it is the image user's responsibility to ensure that any use of this image complies with any relevant licenses for all software contained within.
