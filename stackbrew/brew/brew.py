import hashlib
import logging
import os
import random
from shutil import rmtree
import string

import docker

import git
from summary import Summary

DEFAULT_REPOSITORY = 'git://github.com/shin-/brew'
DEFAULT_BRANCH = 'master'

client = docker.Client(timeout=10000)
processed = {}
processed_folders = []


def build_library(repository=None, branch=None, namespace=None, push=False,
                  debug=False, prefill=True, registry=None, targetlist=None,
                  repos_folder=None, logger=None):
    ''' Entrypoint method build_library.
        repository:     Repository containing a library/ folder. Can be a
                        local path or git repository
        branch:         If repository is a git repository, checkout this branch
                        (default: DEFAULT_BRANCH)
        namespace:      Created repositories will use the following namespace.
                        (default: no namespace)
        push:           If set to true, push images to the repository
        debug:          Enables debug logging if set to True
        prefill:        Retrieve images from public repository before building.
                        Serves to prefill the builder cache.
        registry:       URL to the private registry where results should be
                        pushed. (only if push=True)
        targetlist:     String indicating which library files are targeted by
                        this build. Entries should be comma-separated. Default
                        is all files.
        repos_folder:   Fixed location where cloned repositories should be
                        stored. Default is None, meaning folders are temporary
                        and cleaned up after the build finishes.
        logger:         Logger instance to use. Default is None, in which case
                        build_library will create its own logger.
    '''
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
    else:
        logger.setLevel('INFO')
    if targetlist is not None:
        targetlist = targetlist.split(',')

    if not repository.startswith(('https://', 'git://')):
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
        if buildfile == 'MAINTAINERS':
            continue
        if (targetlist and buildfile not in targetlist):
            continue
        f = open(os.path.join(dst_folder, 'library', buildfile))
        linecnt = 0
        for line in f:
            linecnt += 1
            if not line or line.strip() == '':
                continue
            elif line.lstrip().startswith('#'):  # # It's a comment!
                continue
            logger.debug('{0} ---> {1}'.format(buildfile, line))
            try:
                tag, url, ref, dfile = parse_line(line, logger)
                if prefill:
                    logger.debug('Pulling {0} from official repository (cache '
                                 'fill)'.format(buildfile))
                    try:
                        client.pull(buildfile)
                    except:
                        # Image is not on official repository, ignore prefill
                        pass

                img, commit = build_repo(url, ref, buildfile, dfile, tag,
                                         namespace, push, registry,
                                         repos_folder, logger)
                summary.add_success(buildfile, (linecnt, line), img, commit)
            except Exception as e:
                logger.exception(e)
                summary.add_exception(buildfile, (linecnt, line), e)

        f.close()
    cleanup(dst_folder, dst_folder != repository, repos_folder is None)
    summary.print_summary(logger)
    return summary


def parse_line(line, logger):
    df_folder = '.'
    args = line.split(':', 1)
    if len(args) != 2:
        logger.debug("Invalid line: {0}".format(line))
        raise RuntimeError('Incorrect line format, please refer to the docs')

    try:
        repo = args[1].strip().split()
        if len(repo) == 2:
            df_folder = repo[1].strip()
        url, ref = repo[0].strip().rsplit('@', 1)
        return (args[0].strip(), url, ref, df_folder)
    except ValueError:
        logger.debug("Invalid line: {0}".format(line))
        raise RuntimeError('Incorrect line format, please refer to the docs')


def cleanup(libfolder, clean_libfolder=False, clean_repos=True):
    ''' Cleanup method called at the end of build_library.
        libfolder:       Folder containing the library definition.
        clean_libfolder: If set to True, libfolder will be removed.
                         Only if libfolder was temporary
        clean_repos: Remove library repos. Also resets module variables
                     "processed" and "processed_folders" if set to true.
    '''
    global processed_folders
    global processed
    if clean_libfolder:
        rmtree(libfolder, True)
    if clean_repos:
        for d in processed_folders:
            rmtree(d, True)
        processed_folders = []
        processed = {}


def _random_suffix():
    return ''.join([
        random.choice(string.ascii_letters + string.digits) for i in xrange(6)
    ])


def get_repo_hash(repo_url, ref, df_location):
    h = hashlib.md5(repo_url)
    h.update(ref)
    h.update(df_location)
    return h.hexdigest()


def build_repo(repository, ref, docker_repo, dockerfile_location,
               docker_tag, namespace, push, registry, repos_folder, logger):
    ''' Builds one line of a library file.
        repository:     URL of the git repository that needs to be built
        ref:            Git reference (or commit ID) that needs to be built
        docker_repo:    Name of the docker repository where the image will
                        end up.
        dockerfile_location: Folder containing the Dockerfile
        docker_tag:     Tag for the image in the docker repository.
        namespace:      Namespace for the docker repository.
        push:           If the image should be pushed at the end of the build
        registry:       URL to private registry where image should be pushed
        repos_folder:   Directory where repositories should be cloned
        logger:         Logger instance
    '''
    dst_folder = None
    img_id = None
    commit_id = None
    repo_hash = get_repo_hash(repository, ref, dockerfile_location)
    if repos_folder:
        # Repositories are stored in a fixed location and can be reused
        dst_folder = os.path.join(repos_folder, docker_repo + _random_suffix())
    docker_repo = '{0}/{1}'.format(namespace or 'library', docker_repo)

    if repo_hash in processed.keys():
        logger.info('[cache hit] {0}'.format(repo_hash))
        logger.info('This ref has already been built, reusing image ID')
        img_id = processed[repo_hash]
        if ref.startswith('refs/'):
            commit_id = processed[repository].ref(ref)
        else:
            commit_id = ref
    else:
        # Not already built
        logger.info('[cache miss] {0}'.format(repo_hash))
        rep = None
        logger.info('Cloning {0} (ref: {1})'.format(repository, ref))
        if repository not in processed:  # Repository not cloned yet
            try:
                rep, dst_folder = git.clone(repository, ref, dst_folder)
            except Exception:
                if dst_folder:
                    rmtree(dst_folder)
                ref = 'refs/tags/' + ref
                rep, dst_folder = git.clone(repository, ref, dst_folder)
            processed[repository] = rep
            processed_folders.append(dst_folder)
        else:
            rep = processed[repository]
            if ref in rep.refs:
                # The ref already exists, we just need to checkout
                dst_folder = git.checkout(rep, ref)
            elif 'refs/tags/' + ref in rep.refs:
                ref = 'refs/tags/' + ref
                dst_folder = git.checkout(rep, ref)
            else:  # ref is not present, try pulling it from the remote origin
                try:
                    rep, dst_folder = git.pull(repository, rep, ref)
                except Exception:
                    ref = 'refs/tags/' + ref
                    rep, dst_folder = git.pull(repository, rep, ref)
        dockerfile_location = os.path.join(dst_folder, dockerfile_location)
        if not 'Dockerfile' in os.listdir(dockerfile_location):
            raise RuntimeError('Dockerfile not found in cloned repository')
        commit_id = rep.head()
        logger.info('Building using dockerfile...')
        img_id, logs = client.build(path=dockerfile_location, quiet=True)
        if img_id is None:
            logger.error('Image ID not found. Printing build logs...')
            logger.debug(logs)
            raise RuntimeError('Build failed')

    logger.info('Committing to {0}:{1}'.format(docker_repo,
                docker_tag or 'latest'))
    client.tag(img_id, docker_repo, docker_tag)
    logger.info("Registering as processed: {0}".format(repo_hash))
    processed[repo_hash] = img_id
    if push:
        logger.info('Pushing result to registry {0}'.format(
            registry or "default"))
        push_repo(img_id, docker_repo, registry=registry, logger=logger)
    return img_id, commit_id


def push_repo(img_id, repo, registry=None, docker_tag=None, logger=None):
    ''' Pushes a repository to a registry
        img_id:     Image ID to push
        repo:       Repository name where img_id should be tagged
        registry:   Private registry where image needs to be pushed
        docker_tag: Tag to be applied to the image in docker repo
        logger:     Logger instance
    '''
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
