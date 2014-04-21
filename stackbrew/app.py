import sys
import json

import flask

sys.path.append('./lib')

import brew.v2 as brew
import db
import periodic
import utils

app = flask.Flask('stackbrew')
config = None
with open('./config.json') as config_file:
    config = json.load(config_file)
data = db.DbManager(config['db_url'], debug=config['debug'])
history = {}
brew.logger = app.logger
brew.set_loglevel('DEBUG' if config['debug'] else 'INFO')


@app.route('/')
def home():
    return utils.resp(app, 'stackbrew')


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
        return utils.resp(app, 'OK')


def build_task():
    summary = data.new_summary(config['repos_folder'])
    library = brew.StackbrewLibrary(config['library_repo'])
    builder = brew.LocalBuilder(
        library=library, namespaces=config['namespaces'],
        repo_cache=config['repos_folder']
    )
    builder.build_repo_list()
    builder.history = history
    builder.build_all(callback=summary.handle_build_result)
    if config['push']:
        builder.push_all()


try:
    periodic.init_task(build_task, config['build_interval'],
                       logger=app.logger)
    app.logger.info('Periodic build task initiated.')
except RuntimeError:
    app.logger.warning('Periodic build task already locked.')

app.run(
    host=config.get('host', '127.0.0.1'),
    port=config.get('port', 5000),
    debug=config['debug']
)
