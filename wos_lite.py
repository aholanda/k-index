from urllib.request import urlopen, Request
from urllib.parse import urlencode
from itertools import zip_longest as zipl

# local
from utils import print_error_and_exit

class WoSLite:
    URL = 'https://api.clarivate.com/api/woslite/'

    def __init__(self, key, esci=False):
        assert(key)
        self._key = key
        self._esci = esci

    def get(self, batch):
        data = []
        params = urlencode({'UT': ",".join([b for b in batch if b is not None])})
        if self._esci:
            params += '&esci=y'
        url = "{}query?{}".format(WoSLite.URL, params)
        print(url)
        q = Request(url)
        q.add_header('X-ApiKey', self._key)
        rsp = urlopen(q)
        raw = json.loads(rsp.read().decode('utf-8'))
        data = [item for item in raw['api'][0]['rval']]
        return data
