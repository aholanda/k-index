from utils import print_error_and_exit

class WoS:
    URL = 'https://api.clarivate.com/api/'
    SERVICES = {'incities'}

    def __init__(self, key, service='incities'):
        if service not in WoS.SERVICES:
            print_error_and_exit('service not recognized: {}'
                                 .format(service))

        assert(key)
        self.key = key
        self.url = WoS.URL + '/' + service

    def get(self, batch):
        data = []
        params = urlencode({'UT': ",".join([b for b in batch if b is not None])})
        if ESCI:
            params += '&esci=y'
        url = "{}?{}".format(self.url, params)
        q = Request(url)
        q.add_header('X-ApiKey', INCITES_KEY)
        rsp = urlopen(q)
        raw = json.loads(rsp.read().decode('utf-8'))
        data = [item for item in raw['api'][0]['rval']]
        return data
