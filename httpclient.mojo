from c import *
from mo import *
from ssmap import SSMap
from simpletools.simplelist import SimpleList


alias VERB_UNKNOWN = 0
alias VERB_DELETE = 1
alias VERB_GET = 2
alias VERB_HEAD = 3
alias VERB_POST = 4
alias VERB_PUT = 5


alias Headers = SSMap


@value
@register_passable
struct StringRefPair(CollectionElement):
    var name: StringRef
    var value: StringRef


@value
struct QueryParams:
    var data: SimpleList[StringRefPair]

    fn __init__(inout self):
        self.data = SimpleList[StringRefPair]()

    fn __setitem__(inout self, name: StringRef, value: StringRef):
        self.data.append(StringRefPair(name, value))

    fn to_string(self) raises -> String:
        if self.data.size() == 0:
            return ""

        var url = String("?")
        for i in range(0, self.data.size()):
            let name = self.data[i].name
            let value = self.data[i].value
            # logi("name: " + String(name) + " value: " + String(value))
            # if value == "":
            #     continue
            url += String(name) + "=" + String(value) + "&"
        return url[1:-1]

    fn debug(inout self) raises:
        for i in range(0, self.data.size()):
            logi(
                String(i)
                + ": "
                + String(self.data[i].name)
                + " = "
                + String(self.data[i].value)
            )


@value
@register_passable
struct HttpResponse:
    var status: Int
    var body: StringRef


@value
struct HttpClient:
    var ptr: c_void_pointer
    # var buff: Pointer[UInt8]

    fn __init__(inout self, base_url: StringLiteral, method: Int = tlsv12_client):
        # print("Client.__init__")
        self.ptr = seq_client_new(
            base_url.data()._as_scalar_pointer(), len(base_url), method
        )
        # self.buff = Pointer[UInt8].alloc(1024 * 64)
        logd("HttpClient.__init__")

    fn __del__(owned self):
        logd("HttpClient.__del__")
        seq_client_free(self.ptr)
        # self.res.free()
        logd("HttpClient.__del__ success")

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
        let buff = Pointer[UInt8].alloc(1024 * 64)
        # let path_ = to_schar_ptr(path)
        # let body_ = to_schar_ptr(body)
        let status = seq_client_do_request(
            self.ptr,
            path._buffer.data.value,
            len(path),
            verb,
            headers.ptr,
            # body_,
            body._buffer.data.value,
            len(body),
            buff,
            Pointer[Int].address_of(n),
        )

        logd("do_request success")
        # let s = c_str_to_string(self.res, n)

        let s = to_string_ref(buff, n)
        # logi("do_request to_string_ref ok")
        return HttpResponse(status, s)
