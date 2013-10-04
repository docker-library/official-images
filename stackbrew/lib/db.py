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
