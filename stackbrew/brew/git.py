import logging
import os
import subprocess
import tempfile


logger = logging.getLogger(__name__)


class GitException(Exception):
    pass


class Repo(object):
    def __init__(self, path, repo_url):
        self.path = path
        self.repo_url = repo_url

    def clone(self):
        logger.debug('Cloning {0} into {1}'.format(self.repo_url, self.path))
        result = _execute('clone', [self.repo_url, '.'], self.path)
        if result != 0:
            raise GitException('git clone failed')


def _execute(command, args, cwd):
    cmd = ['git', command] + args
    logger.debug('Executing "{0}" in {1}'.format(' '.join(cmd), cwd))
    return subprocess.Popen(cmd, cwd=cwd).wait()


def clone_branch(repo_url, branch="master", folder=None):
    return clone(repo_url, 'refs/heads/' + branch, folder)


def clone_tag(repo_url, tag, folder=None):
    return clone(repo_url, 'refs/tags/' + tag, folder)


def checkout(rep, ref=None):
    if ref is None:
        ref = 'refs/heads/master'
    logger.debug("Checkout ref:{0} in {1}".format(ref, rep.path))
    result = _execute('checkout', [ref], rep.path)

    if result != 0:
        raise GitException('git checkout failed')

    return rep.path


def pull(origin, rep, ref=None):
    if ref is None:
        ref = 'refs/heads/master'
    logger.debug("Pull ref:{0} in {1}".format(ref, rep.path))
    result = _execute('pull', ['origin', ref], rep.path)
    if result != 0:
        raise GitException('git pull failed')
    checkout(rep, ref)
    return rep, rep.path


def clone(repo_url, ref=None, folder=None, rep=None):
    if ref is None:
        ref = 'refs/heads/master'
    logger.debug("Cloning repo_url={0}, ref={1}".format(repo_url, ref))
    if folder is None:
        folder = tempfile.mkdtemp()
    else:
        os.mkdir(folder)
    logger.debug("folder = {0}".format(folder))
    rep = Repo(folder, repo_url)
    rep.clone()

    return rep, folder
