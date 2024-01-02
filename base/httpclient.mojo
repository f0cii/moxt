from .c import *
from .mo import *
from .ssmap import SSMap
from stdlib_extensions.builtins import dict, list, HashableInt, HashableStr


alias VERB_UNKNOWN = 0
alias VERB_DELETE = 1
alias VERB_GET = 2
alias VERB_HEAD = 3
alias VERB_POST = 4
alias VERB_PUT = 5


alias Headers = SSMap


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
    var status: Int
    var body: String


struct HttpClient:
    var _base_url: StringLiteral
    var _method: Int
    var ptr: c_void_pointer

    fn __init__(inout self, base_url: StringLiteral, method: Int = tlsv12_client):
        logd("HttpClient.__init__")
        self._base_url = base_url
        self._method = method
        self.ptr = seq_client_new(
            base_url.data()._as_scalar_pointer(), len(base_url), method
        )
        logd("HttpClient.__init__ done")

    fn __moveinit__(inout self, owned existing: Self):
        logi("HttpClient.__moveinit__")
        self._base_url = existing._base_url
        self._method = existing._method
        self.ptr = seq_client_new(
            self._base_url.data()._as_scalar_pointer(),
            len(self._base_url),
            self._method,
        )
        existing.ptr = c_void_pointer.get_null()
        logi("HttpClient.__moveinit__ done")

    fn __del__(owned self):
        logd("HttpClient.__del__")
        let NULL = c_void_pointer.get_null()
        if self.ptr != NULL:
            seq_client_free(self.ptr)
            self.ptr = NULL
        logd("HttpClient.__del__ done")

    fn get(self, request_path: String, headers: Headers) -> HttpResponse:
        # print("get", request_path, headers)
        let res = self.do_request(request_path, VERB_GET, headers, "")
        return res

    fn post(self, request_path: String, data: String, headers: Headers) -> HttpResponse:
        # print("post", request_path, data, headers)
        let res = self.do_request(request_path, VERB_POST, headers, data)
        return res

    fn do_request(
        self, path: String, verb: Int, headers: Headers, body: String
    ) -> HttpResponse:
        var n: Int = 0
        let buff = Pointer[UInt8].alloc(1024 * 100)
        let status = seq_client_do_request(
            self.ptr,
            path._buffer.data.value,
            len(path),
            verb,
            headers.ptr,
            body._buffer.data.value,
            len(body),
            buff,
            Pointer[Int].address_of(n),
        )

        let s = c_str_to_string(buff, n)
        buff.free()

        # print("s=" + s)

        return HttpResponse(status, s)
