import json


def resp(app, data=None, code=200, headers=None):
    if not headers:
        headers = {}
    if 'Content-Type' not in headers:
        headers['Content-Type'] = 'application/json'
        data = json.dumps(data)
    return app.make_response((data, code, headers))


def save_history(history, target='/opt/stackbrew/history.json'):
    save = []
    for k in history.iterkeys():
        url, ref, dfile = k # unpack
        save.append({
            'url': url,
            'ref': ref,
            'dfile': dfile,
            'img': history[k]
        })

    with open(target, 'w') as f:
        f.write(json.dumps(save))


def load_history(target='/opt/stackbrew/history.json'):
    history = {}
    try:
        with open(target, 'r') as f:
            savefile = json.loads(f.read())
            for item in savefile:
                history[(item['url'], item['ref'], item['dfile'])] = item['img']
            return history
    except IOError:
        return {}
