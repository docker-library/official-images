import json
import logging
import os
import random
import re
from shutil import rmtree
import string

import docker

import git

DEFAULT_REPOSITORY = 'git://github.com/dotcloud/stackbrew'
DEFAULT_BRANCH = 'master'

logger = logging.getLogger(__name__)
logging.basicConfig(format='%(asctime)s %(levelname)s %(message)s',
                    level='INFO')


def set_loglevel(level):
    logger.setLevel(level)
    git.logger.setLevel(level)


class StackbrewError(Exception):
    def __init__(self, message, cause=None):
        super(StackbrewError, self).__init__(message)
        self.cause = cause

    def log(self, logger):
        logger.exception(self)
        if self.cause:
            logger.error('The cause of this error is the following:')
            logger.exception(self.cause)


class StackbrewLibrary(object):
    def __init__(self, repository, branch=None):
        self.logger = logging.getLogger(__name__)
        logging.basicConfig(format='%(asctime)s %(levelname)s %(message)s',
                            level='INFO')

        self.branch = branch or DEFAULT_BRANCH
        self.repository = repository
        self.library = None
        if not self.repository.startswith(('https://', 'git://')):
            self.logger.info('Repository provided assumed to be a local path')
            self.library = self.repository

    def clone_library(self):
        if self.library:
            return self.library

        try:
            rep, library = git.clone_branch(self.repository, self.branch)
            self.library = library
        except git.GitException as e:
            raise StackbrewError(
                'Source repository could not be fetched. Ensure '
                'the address is correct and the branch exists.',
                e
            )

    def list_repositories(self):
        if not self.library:
            self.clone_library()
        try:
            return [e for e in os.listdir(
                os.path.join(self.library, 'library')) if e != 'MAINTAINERS']
        except OSError as e:
            raise StackbrewError(
                'The path provided ({0}) could not be found or '
                'didn\'t contain a library/ folder'.format(self.library),
                e
            )


class StackbrewRepo(object):
    def __init__(self, name, definition_file):
        self.buildlist = {}
        self.git_folders = {}
        self.name = name
        for line in definition_file:
            if not line or line.strip() == '':
                continue
            elif line.lstrip().startswith('#'):  # # It's a comment!
                continue
            logger.debug(line)
            tag, url, ref, dfile = self._parse_line(line)
            if (url, ref, dfile) in self.buildlist:
                self.buildlist[(url, ref, dfile)].append(tag)
            else:
                self.buildlist[(url, ref, dfile)] = [tag]

    def _parse_line(self, line):
        df_folder = '.'
        args = line.split(':', 1)
        if len(args) != 2:
            logger.debug("Invalid line: {0}".format(line))
            raise StackbrewError(
                'Incorrect line format, please refer to the docs'
            )

        try:
            repo = args[1].strip().split()
            if len(repo) == 2:
                df_folder = repo[1].strip()
            url, ref = repo[0].strip().rsplit('@', 1)
            return (args[0].strip(), url, ref, df_folder)
        except ValueError:
            logger.debug("Invalid line: {0}".format(line))
            raise StackbrewError(
                'Incorrect line format, please refer to the docs'
            )

    def list_versions(self):
        return self.buildlist.keys()

    def get_associated_tags(self, repo):
        return self.buildlist.get(repo, None)

    def add_git_repo(self, url, repo):
        self.git_folders[url] = repo

    def get_git_repo(self, url):
        return self.git_folders.get(url, (None, None))


class StackbrewBuilder(object):
    def __init__(self, library, namespaces=None, targetlist=None,
                 repo_cache=None):
        self.lib = library
        if not hasattr(self.lib, 'list_repositories'):
            raise StackbrewError('Invalid library passed to StackbrewBuilder')
        self.namespaces = namespaces or ['stackbrew']
        self.targetlist = targetlist
        self.repo_cache = repo_cache
        self.history = {}

    def build_repo_list(self):
        self.repos = []
        for repo in self.lib.list_repositories():
            if self.targetlist and repo not in self.targetlist:
                continue
            try:
                with open(os.path.join(self.lib.library, 'library', repo)) as f:
                    self.repos.append(StackbrewRepo(repo, f))
            except IOError as e:
                raise StackbrewError(
                    'Failed to read definition file for {0}'.format(repo),
                    e
                )
        for repo in self.repos:
            for version in repo.list_versions():
                logger.debug('{0}: {1}'.format(
                    repo.name,
                    ','.join(repo.get_associated_tags(version))
                ))
        return self.repos

    def build_all(self, continue_on_error=True, callback=None):
        self.pushlist = []
        for repo in self.repos:
            self.build_repo(repo, continue_on_error, callback)
            for namespace in self.namespaces:
                self.pushlist.append('/'.join([namespace, repo.name]))

    def build_repo(self, repo, continue_on_error=True, callback=None):
        for version in repo.list_versions():
            try:
                self.build_version(repo, version, callback)
            except StackbrewError as e:
                if not continue_on_error:
                    raise e
                e.log(logger)

    def build_version(self, repo, version, callback=None):
        if version in self.history:
            return self.history[version], None
        url, ref, dfile = version
        try:
            rep, dst_folder = self.clone_version(repo, version)
        except StackbrewError as exc:
            if callback:
                callback(exc, repo, version, None, None)
            raise exc
        dockerfile_location = os.path.join(dst_folder, dfile)
        if not 'Dockerfile' in os.listdir(dockerfile_location):
            exc = StackbrewError('Dockerfile not found in cloned repository')
            if callback:
                callback(exc, repo, version, None, None)
            raise exc
        img_id, build_result = self.do_build(
            repo, version, dockerfile_location, callback
        )
        self.history[version] = img_id
        return img_id, build_result

    def do_build(self, repo, version, dockerfile_location, callback=None):
        raise NotImplementedError

    def _clone_or_checkout(self, url, ref, dst_folder, rep):
        if rep:
            try:
                # The ref already exists, we just need to checkout
                dst_folder = git.checkout(rep, ref)
            except git.GitException:
                # ref is not present, try pulling it from the remote origin
                rep, dst_folder = git.pull(url, rep, ref)
            return rep, dst_folder

        if dst_folder:
            rmtree(dst_folder)
        return git.clone(url, ref, dst_folder)

    def clone_version(self, repo, version):
        url, ref, dfile = version
        rep, dst_folder = repo.get_git_repo(url)
        if not dst_folder and self.repo_cache:
            dst_folder = os.path.join(
                self.repo_cache, repo.name + _random_suffix()
            )
            os.mkdir(dst_folder)
        try:
            rep, dst_folder = self._clone_or_checkout(
                url, ref, dst_folder, rep
            )
        except Exception as e:
            raise StackbrewError(
                'Failed to clone repository {0}@{1}'.format(url, ref),
                e
            )

        repo.add_git_repo(url, (rep, dst_folder))
        return rep, dst_folder

    def get_pushlist(self):
        return self.pushlist

    def push_all(self, continue_on_error=True, callback=None):
        for repo in self.pushlist:
            try:
                self.do_push(repo, callback)
            except StackbrewError as e:
                if continue_on_error:
                    e.log(logger)
                else:
                    raise e

    def do_push(self, repo_name, callback=None):
        raise NotImplementedError


def _random_suffix():
    return ''.join([
        random.choice(string.ascii_letters + string.digits) for i in xrange(6)
    ])


class LocalBuilder(StackbrewBuilder):
    def __init__(self, library, namespaces=None, targetlist=None,
                 repo_cache=None):
        super(LocalBuilder, self).__init__(
            library, namespaces, targetlist, repo_cache
        )
        self.client = docker.Client(version='1.9', timeout=10000)
        self.build_success_re = r'^Successfully built ([a-f0-9]+)\n$'

    def do_build(self, repo, version, dockerfile_location, callback=None):
        logger.info(
            'Build start: {0} {1}'.format(repo.name, version)
        )
        build_result = self.client.build(path=dockerfile_location, rm=True,
                                         stream=True, quiet=True)
        img_id, logs = self._parse_result(build_result)
        if not img_id:
            exc = StackbrewError(
                'Build failed for {0} ({1})'.format(repo.name, version)
            )
            if callback:
                callback(exc, repo, version, None, logs)
            raise exc
        for tag in repo.get_associated_tags(version):
            logger.info(
                'Build success: {0} ({1}:{2})'.format(img_id, repo.name, tag)
            )
            for namespace in self.namespaces:
                self.client.tag(img_id, '/'.join([namespace, repo.name]), tag)

        if callback:
            callback(None, repo, version, img_id, logs)
        return img_id, build_result

    def _parse_result(self, build_result):
        if isinstance(build_result, tuple):
            img_id, logs = build_result
            return img_id, logs
        else:
            lines = [line for line in build_result]
            try:
                parsed_lines = [json.loads(e).get('stream', '') for e in lines]
            except ValueError:
                # sometimes all the data is sent on a single line ????
                #
                # ValueError: Extra data: line 1 column 87 - line 1 column
                # 33268 (char 86 - 33267)
                line = lines[0]
                # This ONLY works because every line is formatted as
                # {"stream": STRING}
                parsed_lines = [
                    json.loads(obj).get('stream', '') for obj in
                    re.findall('{\s*"stream"\s*:\s*"[^"]*"\s*}', line)
                ]

            for line in parsed_lines:
                match = re.match(self.build_success_re, line)
                if match:
                    return match.group(1), parsed_lines
            return None, parsed_lines

    def do_push(self, repo_name, callback=None):
        exc = None
        for i in xrange(4):
            try:
                pushlog = self.client.push(repo_name)
                if '"error":"' in pushlog:
                    raise RuntimeError(
                        'Error while pushing: {0}'.format(pushlog)
                    )
            except Exception as e:
                exc = e
                continue
            if callback:
                callback(None, repo_name, pushlog)
            return
        if not callback:
            raise StackbrewError(
                'Error while pushing {0}'.format(repo_name),
                exc
            )
        else:
            return callback(exc, repo_name, None)
