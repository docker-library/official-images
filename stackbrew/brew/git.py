import os
import tempfile
import logging

from dulwich import index
from dulwich.client import get_transport_and_path
from dulwich.objects import Tag
from dulwich.repo import Repo

logger = logging.getLogger(__name__)


def clone_branch(repo_url, branch="master", folder=None):
    return clone(repo_url, 'refs/heads/' + branch, folder)


def clone_tag(repo_url, tag, folder=None):
    return clone(repo_url, 'refs/tags/' + tag, folder)


def checkout(rep, ref=None):
    if ref is None:
        ref = 'refs/heads/master'
    elif ref.startswith('refs/tags'):
        ref = rep.ref(ref)
    if isinstance(rep[ref], Tag):
        rep['HEAD'] = rep[ref].object[1]
    else:
        rep['HEAD'] = rep.refs[ref]
    indexfile = rep.index_path()
    tree = rep["HEAD"].tree
    index.build_index_from_tree(rep.path, indexfile, rep.object_store, tree)
    return rep.path


def pull(origin, rep, ref=None):
    clone(origin, ref, None, rep)
    return rep, rep.path


def clone(repo_url, ref=None, folder=None, rep=None):
    if ref is None:
        ref = 'refs/heads/master'
    logger.debug("clone repo_url={0}, ref={1}".format(repo_url, ref))
    if not rep:
        if folder is None:
            folder = tempfile.mkdtemp()
        else:
            os.mkdir(folder)
        logger.debug("folder = {0}".format(folder))
        rep = Repo.init(folder)
    client, relative_path = get_transport_and_path(repo_url)
    logger.debug("client={0}".format(client))

    remote_refs = client.fetch(relative_path, rep)
    for k, v in remote_refs.iteritems():
        try:
            rep.refs.add_if_new(k, v)
        except:
            pass

    if ref.startswith('refs/tags'):
        ref = rep.ref(ref)

    if isinstance(rep[ref], Tag):
        rep['HEAD'] = rep[ref].object[1]
    else:
        rep['HEAD'] = rep[ref]
    indexfile = rep.index_path()
    tree = rep["HEAD"].tree
    index.build_index_from_tree(rep.path, indexfile, rep.object_store, tree)
    logger.debug("done")
    return rep, folder
