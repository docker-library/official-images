import os

import docker

import git

DEFAULT_REPOSITORY = 'git://github.com/dotcloud/docker'
DEFAULT_BRANCH = 'library'


def fetch_buildlist(repository=None, branch=None):
    if repository is None:
        repository = DEFAULT_REPOSITORY
    if branch is None:
        branch = DEFAULT_BRANCH
    #FIXME: set destination folder and only pull latest changes instead of
    # cloning the whole repo everytime
    dst_folder = git.clone_branch(repository, branch)
    for buildfile in os.listdir(os.path.join(dst_folder, 'library')):
        f = open(os.path.join(dst_folder, 'library', buildfile))
        for line in f:
            print buildfile, '--->', line
            args = line.split()
            try:
                #FIXME: delegate to workers instead?
                if len(args) == 1:  # Just a URL, simple mode
                    start_build(args[0], 'refs/heads/master', buildfile)
                elif len(args) == 3:  # docker-tag  url     B:branch or T:tag
                    ref = None
                    if args[2].startswith('B:'):
                        ref = 'refs/heads/' + args[2][2:]
                    elif args[2].startswith('T:'):
                        ref = 'refs/tags/' + args[2][2:]
                    else:
                        raise RuntimeError('Incorrect line format, '
                            'please refer to the docs')
                    start_build(args[1], ref, buildfile, args[0])
            except Exception as e:
                print '!!! ', str(e).strip()
        f.close()


def start_build(repository, ref, docker_repo, docker_tag=None):
    print '---> Cloning {0} (ref: {1})'.format(repository, ref)
    dst_folder = git.clone(repository, ref)
    if not 'Dockerfile' in os.listdir(dst_folder):
        raise RuntimeError('Dockerfile not found in cloned repository')
    f = open(os.path.join(dst_folder, 'Dockerfile'))
    print '---> Building using dockerfile...'
    #img_id, logs = docker.build_context(dst_folder)
    print '--> Committing to library/{0}:{1}'.format(docker_repo,
        docker_tag or 'latest')
    #docker.commit(img_id, 'library/' + docker_repo, docker_tag)
    print '---> Pushing result to the main registry'
    #docker.push('library/' + docker_repo)
    f.close()
