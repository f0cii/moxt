from collections import Dict, KeyElement
from collections.optional import Optional
from .c import *
from .mo import *
from .ssmap import SSMap
from stdlib_extensions.builtins import dict, list, HashableInt, HashableStr
from ylstdlib.dict import StringKey


alias VERB_UNKNOWN = 0
alias VERB_DELETE = 1
alias VERB_GET = 2
alias VERB_HEAD = 3
alias VERB_POST = 4
alias VERB_PUT = 5


# alias Headers = Dict[StringKey, String]
alias Headers = SSMap
alias DEFAULT_BUFF_SIZE = 1024 * 100


@value
struct QueryParams:
    var data: dict[HashableStr, String]

    fn __init__(inout self):
        self.data = dict[HashableStr, String]()

    fn __setitem__(inout self, name: String, value: String):
        self.data[name] = value

    fn to_string(self) raises -> String:
        if len(self.data) == 0:
            return ""

        var url = String("?")
        for item in self.data.items():
            # if item.value == "":
            #     continue
            url += str(item.key) + "=" + str(item.value) + "&"
        return url[1:-1]

    fn debug(inout self) raises:
        for item in self.data.items():
            logi(
                # str(i)
                # + ": "
                str(item.key)
                + " = "
                + str(item.value)
            )


@value
struct HttpResponse:
    var status_code: Int
    var text: String

    fn __init__(inout self, status_code: Int, text: String):
        self.status_code = status_code
        self.text = text


struct HttpClient:
    var _base_url: String
    var _method: Int
    var ptr: c_void_pointer
    var _verbose: Bool

    fn __init__(inout self, base_url: String, method: Int = tlsv12_client):
        logd("HttpClient.__init__")
        self._base_url = base_url
        self._method = method
        self.ptr = seq_client_new(base_url._buffer.data.value, len(base_url), method)
        self._verbose = False
        logd("HttpClient.__init__ done")

    fn __moveinit__(inout self, owned existing: Self):
        logd("HttpClient.__moveinit__")
        self._base_url = existing._base_url
        self._method = existing._method
        self.ptr = seq_client_new(
            self._base_url._buffer.data.value,
            len(self._base_url),
            self._method,
        )
        self._verbose = existing._verbose
        existing.ptr = c_void_pointer.get_null()
        logd("HttpClient.__moveinit__ done")

    fn __del__(owned self):
        logd("HttpClient.__del__")
        var NULL = c_void_pointer.get_null()
        if self.ptr != NULL:
            seq_client_free(self.ptr)
            self.ptr = NULL
        logd("HttpClient.__del__ done")

    fn set_verbose(inout self, verbose: Bool):
        self._verbose = verbose

    fn delete(
        self, request_path: String, inout headers: Headers, buff_size: Int = DEFAULT_BUFF_SIZE
    ) -> HttpResponse:
        var res = self.do_request(request_path, VERB_DELETE, headers, "", buff_size)
        return res

    fn get(
        self, request_path: String, inout headers: Headers, buff_size: Int = DEFAULT_BUFF_SIZE
    ) -> HttpResponse:
        var res = self.do_request(request_path, VERB_GET, headers, "", buff_size)
        return res

    fn head(
        self,
        request_path: String,
        data: String,
        inout headers: Headers,
        buff_size: Int = DEFAULT_BUFF_SIZE,
    ) -> HttpResponse:
        var res = self.do_request(request_path, VERB_HEAD, headers, data, buff_size)
        return res

    fn post(
        self,
        request_path: String,
        data: String,
        inout headers: Headers,
        buff_size: Int = DEFAULT_BUFF_SIZE,
    ) -> HttpResponse:
        var res = self.do_request(request_path, VERB_POST, headers, data, buff_size)
        return res

    fn put(
        self,
        request_path: String,
        data: String,
        inout headers: Headers,
        buff_size: Int = DEFAULT_BUFF_SIZE,
    ) -> HttpResponse:
        var res = self.do_request(request_path, VERB_PUT, headers, data, buff_size)
        return res

    fn do_request(
        self,
        path: String,
        verb: Int,
        inout headers: Headers,
        body: String,
        buff_size: Int,
    ) -> HttpResponse:
        var n: Int = 0
        headers["User-Agent"] = "MOXT/1.0.0"
        var buff = Pointer[UInt8].alloc(buff_size)
        var status = seq_cclient_do_request(
            self.ptr,
            path._buffer.data.value,
            len(path),
            verb,
            headers.ptr,
            body._buffer.data.value,
            len(body),
            buff,
            buff_size,
            Pointer[Int].address_of(n),
            self._verbose,
        )

        var s = c_str_to_string(buff, n)
        buff.free()

        return HttpResponse(status, s)
