import json


def resp(app, data=None, code=200, headers=None):
    if not headers:
        headers = {}
    if 'Content-Type' not in headers:
        headers['Content-Type'] = 'application/json'
        data = json.dumps(data)
    return app.make_response((data, code, headers))
