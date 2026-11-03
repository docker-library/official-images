#!/usr/bin/env python3
import argparse
import os
import subprocess
import re
import sys

import mechanize
import tempfile
import pytest


def do_test_content(match, content):
    assert(match in content)

def test_phpmyadmin(url, username, password, server, sqlfile):
    if sqlfile is None:
        if os.path.exists('/world.sql'):
            sqlfile = '/world.sql'
        elif os.path.exists('./world.sql'):
            sqlfile = './world.sql'
        else:
            path = os.path.dirname(os.path.realpath(__file__))
            sqlfile = path + '/world.sql'
    br = mechanize.Browser()

    # Ignore robots.txt
    br.set_handle_robots(False)

    # Login page
    br.open(url)

    # Fill login form
    br.select_form('login_form')
    br['pma_username'] = username
    br['pma_password'] = password
    if server is not None:
        br['pma_servername'] = server

    # Login and check if loggged in
    response = br.submit()
    do_test_content('Server version', response.read())

    # Open server import
    response = br.follow_link(text_regex=re.compile('Import'))
    do_test_content('OpenDocument Spreadsheet', response.read())

    # Upload SQL file
    br.select_form('import')
    br.form.add_file(open(sqlfile), 'text/plain', sqlfile)
    response = br.submit()
    do_test_content('18 queries executed', response.read())


def docker_secret(env_name):
    dir_path = os.path.dirname(os.path.realpath(__file__))
    secret_file = tempfile.mkstemp()

    password = "The_super_secret_password"
    password_file = open(secret_file[1], 'wb')
    password_file.write(str.encode(password))
    password_file.close()

    test_env = {env_name + '_FILE': secret_file[1]}

    # Run entrypoint and afterwards echo the environment variables
    result = subprocess.Popen(dir_path+ "/../docker-entrypoint.sh 'env'", shell=True, stdout=subprocess.PIPE, env=test_env)
    output = result.stdout.read().decode()

    assert (env_name + "=" + password) in output

def test_phpmyadmin_secrets():
    docker_secret('MYSQL_PASSWORD')
    docker_secret('MYSQL_ROOT_PASSWORD')
    docker_secret('PMA_PASSWORD')
    docker_secret('PMA_HOSTS')
    docker_secret('PMA_HOST')
