import sys

sys.path.append('./lib')

import db

data = db.DbManager(debug=True)
data.generate_tables()
