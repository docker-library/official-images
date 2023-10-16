import subprocess, sys
subprocess.check_call([sys.executable, '-m', 'pip', 'install', '--root-user-action', 'ignore', 'requests'])

import requests
r = requests.get('https://google.com')
assert(r.status_code == 200)
