import sqlite3

ver = sqlite3.sqlite_version

con = sqlite3.connect(':memory:', 1, sqlite3.PARSE_DECLTYPES, None)
cur = con.cursor()
cur.execute('CREATE TABLE test (id INT, txt TEXT)')
cur.execute('INSERT INTO test VALUES (?, ?)', (42, 'wut'))
cur.execute('SELECT * FROM test')
assert(cur.fetchall() == [(42, 'wut')])
cur.execute('DROP TABLE test')
con.close()
