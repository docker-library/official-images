import json


def resp(app, data=None, code=200, headers=None):
    if not headers:
        headers = {}
    if 'Content-Type' not in headers:
        headers['Content-Type'] = 'application/json'
        data = json.dumps(data)
    return app.make_response((data, code, headers))


def save_history(history, target='/opt/stackbrew/history.json'):
	with open(target, 'w') as f:
		f.write(json.dumps(history))


def load_history(target='/opt/stackbrew/history.json'):
	try:
		with open(target, 'r') as f:
			return json.loads(f.read())
	except IOError:
		return {}
