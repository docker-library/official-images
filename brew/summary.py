
class SummaryItem(object):
    def __init__(self, data):
        self.line = data.get('line', None)
        self.repository = data.get('repository', None)
        self.commit_id = data.get('commit', None)
        self.exc = data.get('exc', None)
        self.image_id = data.get('id', None)
        self.source = data.get('source', None)
        self.tag = data.get('tag', None)


class Summary(object):
    def __init__(self):
        self._summary = {}
        self._has_exc = False

    def _add_data(self, image, linestr, data):
        parts = linestr.split('\t')
        tag = 'latest'
        source = None
        if len(parts) == 1:
            source = linestr + '@B:master'
        elif len(parts) == 2:
            tag = parts[0]
            source = parts[1] + '@B:master'
        elif len(parts) == 3:
            tag = parts[0]
            source = '{}@{}'.format(parts[1], parts[2])
        source = source.replace('\n', '')
        data.tag = tag
        data.source = source
        if image not in self._summary:
            self._summary[image] = {linestr: data}
        else:
            self._summary[image][linestr] = data

    def add_exception(self, image, line, exc):
        lineno, linestr = line
        self._add_data(image, linestr, SummaryItem({
            'line': lineno,
            'exc': str(exc),
            'repository': image
        }))
        self._has_exc = True

    def add_success(self, image, line, img_id):
        lineno, linestr = line
        self._add_data(image, linestr, SummaryItem({
            'line': lineno,
            'id': img_id,
            'repository': image
        }))

    def print_summary(self, logger=None):
        linesep = ''.center(61, '-') + '\n'
        s = 'BREW BUILD SUMMARY\n' + linesep
        success = 'OVERALL SUCCESS: {}\n'.format(not self._has_exc)
        details = linesep
        for image, lines in self._summary.iteritems():
            details = details + '{}\n{}'.format(image, linesep)
            for linestr, data in lines.iteritems():
                details = details + '{0:2} | {1} | {2:50}\n'.format(
                    data.line,
                    'KO' if data.exc else 'OK',
                    data.exc or data.image_id
                )
            details = details + linesep
        if logger is not None:
            logger.info(s + success + details)
        else:
            print s, success, details

    def exit_code(self):
        return 1 if self._has_exc else 0

    def items(self):
        for lines in self._summary.itervalues():
            for item in lines.itervalues():
                yield item
