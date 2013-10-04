import sys

import flask

sys.path.append('./lib')
sys.path.append('..')

import brew
import db
import periodic
import utils

app = flask.Flask('stackbrew')
data = db.DbManager(debug=True)


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


@app.route('/build/force', method=['POST'])
def build_task():
    summary = brew.build_library(
        'https://github.com/shin-/brew.git', namespace='stackbrew',
        debug=True, prefill=False, logger=app.logger
    )
    data.insert_summary(summary)


try:
    periodic.init_task(build_task, 600, logger=app.logger)
    app.logger.info('Periodic build task initiated.')
except RuntimeError:
    app.logger.info('Periodic build task already locked.')
app.run(debug=True)
