from base.httpclient import HttpClient, VERB_GET, Headers, QueryParams


struct BackendInteractor:
    var backend_url: String

    fn __init__(inout self, backend_url: String):
        self.backend_url = backend_url

    fn login(self, username: String, password: String) -> String:
        var client = HttpClient(self.backend_url)
        var headers = Headers()
        self.set_default_headers(headers)
        headers["Content-Type"] = "application/json;charset=UTF-8"
        headers["X-Requested-With"] = "XMLHttpRequest"
        var data = '{"username": "' + username + '", "password": "' + password + '"}'
        var res = client.post("/api/auth/login", data, headers)
        # print(res.status_code)
        # print(res.text)
        return res.text

    fn get_bot_params(self, sid: String, token: String) -> String:
        var authorization = "Bearer " + token
        # var headers = {
        #     'Accept': 'application/json, text/plain, */*',
        #     'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8,en-GB;q=0.7,en-US;q=0.6,ja;q=0.5,ms;q=0.4,zh-TW;q=0.3',
        #     'Authorization': authorization,
        #     'Cache-Control': 'no-cache',
        #     'Connection': 'keep-alive',
        #     'Pragma': 'no-cache',
        #     'Referer': 'http://1.94.26.93/',
        #     'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36 Edg/122.0.0.0',
        #     'X-Requested-With': 'XMLHttpRequest',
        # }

        var path = "/api/algos/" + sid + "/options"
        var client = HttpClient(self.backend_url)
        var headers = Headers()
        self.set_default_headers(headers)
        headers["Authorization"] = authorization
        # headers["X-Requested-With"] = "XMLHttpRequest"
        var res = client.get(path, headers)
        # print(res.status_code)
        # print(res.text)
        return res.text

    fn set_default_headers(self, inout headers: Headers):
        headers["Accept"] = "application/json, text/plain, */*"
        headers["Accept-Language"] = "zh-CN,zh;q=0.9"
