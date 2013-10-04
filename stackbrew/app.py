import sys
import json

import flask

sys.path.append('./lib')
sys.path.append('..')

import brew
import db
import periodic
import utils

app = flask.Flask('stackbrew')
config = None
with open('./config.json') as config_file:
    config = json.load(config_file)
data = db.DbManager(debug=config['debug'])


@app.route('/')
def home():
    return utils.resp(app, 'Hello World')


@app.route('/summary')
@app.route('/status')
def latest_summary():
    result = data.latest_status()
    return utils.resp(app, result)


@app.route('/summary/<int:id>')
def get_summary(id):
    result = data.get_summary(id)
    return utils.resp(app, result)


@app.route('/success/<repo_name>')
def latest_success(repo_name):
    tag = flask.request.args.get('tag', None)
    result = data.get_latest_successful(repo_name, tag)
    return utils.resp(app, result)


if config['debug']:
    @app.route('/build/force', methods=['POST'])
    def force_build():
        build_task()


def build_task():
    summary = brew.build_library(
        'https://github.com/shin-/brew.git', namespace='stackbrew',
        debug=config['debug'], push=config['push'], prefill=False,
        logger=app.logger
    )
    data.insert_summary(summary)


try:
    periodic.init_task(build_task, config['build_interval'],
                       logger=app.logger)
    app.logger.info('Periodic build task initiated.')
except RuntimeError:
    app.logger.info('Periodic build task already locked.')

app.run(debug=config['debug'])
