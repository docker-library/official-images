import sys

import lib.db as db

data = db.DbManager(debug=True)
data.generate_tables()
