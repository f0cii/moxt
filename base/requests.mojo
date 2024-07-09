from collections.optional import Optional
from .httpclient import (
    HttpClient,
    VERB_GET,
    Headers,
    HttpResponse,
)


struct requests:
    @staticmethod
    fn delete(
        base_url: String, path: String, inout headers: Headers
    ) -> HttpResponse:
        var client = HttpClient(base_url)
        var res = client.delete(path, headers)
        return res

    @staticmethod
    fn get(
        base_url: String, path: String, inout headers: Headers
    ) -> HttpResponse:
        var client = HttpClient(base_url)
        var res = client.get(path, headers)
        return res

    @staticmethod
    fn head(
        base_url: String, path: String, data: String, inout headers: Headers
    ) -> HttpResponse:
        var client = HttpClient(base_url)
        var res = client.head(path, data, headers)
        return res

    @staticmethod
    fn post(
        base_url: String, path: String, data: String, inout headers: Headers
    ) -> HttpResponse:
        var client = HttpClient(base_url)
        var res = client.post(path, data, headers)
        return res

    @staticmethod
    fn put(
        base_url: String, path: String, data: String, inout headers: Headers
    ) -> HttpResponse:
        var client = HttpClient(base_url)
        var res = client.put(path, data, headers)
        return res
