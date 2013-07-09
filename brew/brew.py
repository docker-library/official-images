import os

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
        f.close()
