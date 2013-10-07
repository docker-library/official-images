import logging
import os
from shutil import rmtree

import docker

import git
from summary import Summary

DEFAULT_REPOSITORY = 'git://github.com/shin-/brew'
DEFAULT_BRANCH = 'master'

client = docker.Client()
processed = {}
processed_folders = []


def build_library(repository=None, branch=None, namespace=None, push=False,
                  debug=False, prefill=True, registry=None, targetlist=None,
                  logger=None):
    dst_folder = None
    summary = Summary()
    if logger is None:
        logger = logging.getLogger(__name__)
        logging.basicConfig(format='%(asctime)s %(levelname)s %(message)s',
                            level='INFO')

    if repository is None:
        repository = DEFAULT_REPOSITORY
    if branch is None:
        branch = DEFAULT_BRANCH
    if debug:
        logger.setLevel('DEBUG')
    if targetlist is not None:
        targetlist = targetlist.split(',')

    if not (repository.startswith('https://') or repository.startswith('git://')):
        logger.info('Repository provided assumed to be a local path')
        dst_folder = repository

    try:
        client.version()
    except Exception as e:
        logger.error('Could not reach the docker daemon. Please make sure it '
                     'is running.')
        logger.warning('Also make sure you have access to the docker UNIX '
                       'socket (use sudo)')
        return

    #FIXME: set destination folder and only pull latest changes instead of
    # cloning the whole repo everytime
    if not dst_folder:
        logger.info('Cloning docker repo from {0}, branch: {1}'.format(
            repository, branch))
        try:
            rep, dst_folder = git.clone_branch(repository, branch)
        except Exception as e:
            logger.exception(e)
            logger.error('Source repository could not be fetched. Check '
                         'that the address is correct and the branch exists.')
            return
    try:
        dirlist = os.listdir(os.path.join(dst_folder, 'library'))
    except OSError as e:
        logger.error('The path provided ({0}) could not be found or didn\'t'
                     'contain a library/ folder.'.format(dst_folder))
        return
    for buildfile in dirlist:
        if buildfile == 'MAINTAINERS' or (targetlist and buildfile not in targetlist):
            continue
        f = open(os.path.join(dst_folder, 'library', buildfile))
        linecnt = 0
        for line in f:
            linecnt += 1
            logger.debug('{0} ---> {1}'.format(buildfile, line))
            args = line.split()
            try:
                if len(args) > 3:
                    raise RuntimeError('Incorrect line format, '
                                       'please refer to the docs')

                url = None
                ref = 'refs/heads/master'
                tag = None
                if len(args) == 1:  # Just a URL, simple mode
                    url = args[0]
                elif len(args) == 2 or len(args) == 3:  # docker-tag   url
                    url = args[1]
                    tag = args[0]

                if len(args) == 3:  # docker-tag  url     B:branch or T:tag
                    ref = None
                    if args[2].startswith('B:'):
                        ref = 'refs/heads/' + args[2][2:]
                    elif args[2].startswith('T:'):
                        ref = 'refs/tags/' + args[2][2:]
                    elif args[2].startswith('C:'):
                        ref = args[2][2:]
                    else:
                        raise RuntimeError('Incorrect line format, '
                                           'please refer to the docs')
                if prefill:
                    logger.debug('Pulling {0} from official repository (cache '
                                 'fill)'.format(buildfile))
                    try:
                        client.pull('stackbrew/' + buildfile)
                    except:
                        # Image is not on official repository, ignore prefill
                        pass

                img, commit = build_repo(url, ref, buildfile, tag, namespace,
                                         push, registry, logger)
                summary.add_success(buildfile, (linecnt, line), img, commit)
                processed['{0}@{1}'.format(url, ref)] = img
            except Exception as e:
                logger.exception(e)
                summary.add_exception(buildfile, (linecnt, line), e)

        f.close()
    cleanup(dst_folder, dst_folder != repository)
    summary.print_summary(logger)
    return summary


def cleanup(libfolder, clean_libfolder=False, clean_repos=True):
    global processed_folders
    global processed
    if clean_libfolder:
        rmtree(libfolder, True)
    if clean_repos:
        for d in processed_folders:
            rmtree(d, True)
        processed_folders = []
        processed = {}


def build_repo(repository, ref, docker_repo, docker_tag, namespace, push,
               registry, logger):
    docker_repo = '{0}/{1}'.format(namespace or 'library', docker_repo)
    img_id = None
    commit_id = None
    dst_folder = None
    if '{0}@{1}'.format(repository, ref) not in processed.keys():
        rep = None
        logger.info('Cloning {0} (ref: {1})'.format(repository, ref))
        if repository not in processed:
            rep, dst_folder = git.clone(repository, ref)
            processed[repository] = rep
            processed_folders.append(dst_folder)
        else:
            rep = processed[repository]
            dst_folder = git.checkout(rep, ref)
        if not 'Dockerfile' in os.listdir(dst_folder):
            raise RuntimeError('Dockerfile not found in cloned repository')
        logger.info('Building using dockerfile...')
        img_id, logs = client.build(path=dst_folder, quiet=True)
        commit_id = rep.head()
    else:
        logger.info('This ref has already been built, reusing image ID')
        img_id = processed['{0}@{1}'.format(repository, ref)]
        if ref.startswith('refs/'):
            commit_id = processed[repository].ref(ref)
        else:
            commit_id = ref
    logger.info('Committing to {0}:{1}'.format(docker_repo,
                docker_tag or 'latest'))
    client.tag(img_id, docker_repo, docker_tag)
    if push:
        logger.info('Pushing result to registry {0}'.format(
            registry or "default"))
        push_repo(img_id, docker_repo, registry=registry, logger=logger)
    return img_id, commit_id


def push_repo(img_id, repo, registry=None, docker_tag=None, logger=None):
    exc = None
    if registry is not None:
        repo = '{0}/{1}'.format(registry, repo)
        logger.info('Also tagging {0}'.format(repo))
        client.tag(img_id, repo, docker_tag)
    for i in xrange(4):
        try:
            pushlog = client.push(repo)
            if '"error":"' in pushlog:
                raise RuntimeError('Error while pushing: {0}'.format(pushlog))
        except Exception as e:
            exc = e
            continue
        return
    raise exc
