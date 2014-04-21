import datetime

import sqlalchemy as sql


metadata = sql.MetaData()
summary = sql.Table(
    'summary', metadata,
    sql.Column('id', sql.Integer, primary_key=True),
    sql.Column('result', sql.Boolean),
    sql.Column('build_date', sql.String)
)

summary_item = sql.Table(
    'summary_item', metadata,
    sql.Column('id', sql.Integer, primary_key=True),
    sql.Column('repo_name', sql.String),
    sql.Column('exception', sql.String),
    sql.Column('commit_id', sql.String),
    sql.Column('image_id', sql.String),
    sql.Column('source_desc', sql.String),
    sql.Column('tag', sql.String),
    sql.Column('summary_id', None, sql.ForeignKey('summary.id'))
)


class SummaryV2(object):
    def __init__(self, engine, summary_id, errorlogs=None):
        self.summary_id = summary_id
        self._engine = engine
        self.errorlogs = errorlogs

    def handle_build_result(self, exc, repo, version, img_id, build_result):
        c = self._engine.connect()
        if exc and self.errorlogs:
            with open('{2}/{0}.{1}.error.log'.format(repo.name, version[1], self.errorlogs)) as f:
                f.write(build_result)
        ins = summary_item.insert().values(
            repo_name=repo.name,
            exception=str(exc),
            commit_id=version[1],
            image_id=img_id,
            source_desc=version[0],
            tag=', '.join(repo.get_associated_tags(version)),
            summary_id=self.summary_id
        )
        c.execute(ins)


class DbManager(object):
    def __init__(self, db='/opt/stackbrew/data.db', debug=False):
        self._engine = sql.create_engine('sqlite:///' + db, echo=debug)

    def generate_tables(self):
        metadata.create_all(self._engine)

    def insert_summary(self, s):
        c = self._engine.connect()
        summary_id = None
        with c.begin():
            ins = summary.insert().values(
                result=not s.exit_code(),
                build_date=str(datetime.datetime.now()))
            r = c.execute(ins)
            summary_id = r.inserted_primary_key[0]
            for item in s.items():
                ins = summary_item.insert().values(
                    repo_name=item.repository,
                    exception=item.exc,
                    commit_id=item.commit_id,
                    image_id=item.image_id,
                    source_desc=item.source,
                    tag=item.tag,
                    summary_id=summary_id
                )
                c.execute(ins)
        return summary_id

    def new_summary(self, errorlogs=None):
        c = self._engine.connect()
        ins = summary.insert().values(
            result=True, build_date=str(datetime.datetime.now())
        )
        r = c.execute(ins)
        summary_id = r.inserted_primary_key[0]
        return SummaryV2(self._engine, summary_id, errorlogs)

    def latest_status(self):
        c = self._engine.connect()
        s = sql.select([summary]).order_by(summary.c.id.desc()).limit(1)
        res = c.execute(s)
        row = res.fetchone()
        if row is not None:
            return dict(row)
        return None

    def get_summary(self, id):
        c = self._engine.connect()
        s = sql.select([summary_item]).where(summary_item.c.summary_id == id)
        res = c.execute(s)
        return [dict(row) for row in res]

    def get_latest_successful(self, repo, tag=None):
        c = self._engine.connect()
        tag = tag or 'latest'
        s = sql.select([summary_item]).where(
            summary_item.c.repo_name == repo
        ).where(
            summary_item.c.tag == tag
        ).where(
            summary_item.c.image_id is not None
        ).order_by(
            summary_item.c.summary_id.desc()
        ).limit(1)
        res = c.execute(s)
        row = res.fetchone()
        if row is not None:
            return dict(row)
        return None
