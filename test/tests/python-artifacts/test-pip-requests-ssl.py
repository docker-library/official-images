import pip

pip.main(['install', '-q', 'requests'])

import requests

r = requests.get('https://google.com')
assert(r.status_code == 200)
