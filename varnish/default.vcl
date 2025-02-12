vcl 4.1;
import directors;

backend bookface {
    .host = "bookface";
    .port = "80";
    .probe = {
        .url = "/";
        .interval = 30s;
        .timeout = 10s;
        .window = 5;
        .threshold = 3;
    }
}

sub vcl_init {
    new vdir = directors.round_robin();
    vdir.add_backend(bookface);
}

sub vcl_recv {
    # Happens before we check if we have this in cache already.

    # Don't cache authorized requests.
    if (req.url ~ "^/admin" || req.http.Authorization) {
        return (pass);
    }

    # if (req.url == "/db") {
    #     return (synth(301, "Moved Permanently"));
    # }
}

sub vcl_backend_response {
    # Happens after we have read the response headers from the backend.
    if (beresp.status == 200 || beresp.status == 301 || beresp.status == 302) {
        set beresp.ttl = 1m;
    } else {
        set beresp.ttl = 0s;
    }

    if (beresp.http.Content-Type ~ "text/(html|css|javascript)") {
        set beresp.do_gzip = true;
    }
}

# sub vcl_synth {
#     if (resp.status == 301 && resp.reason == "Moved Permanently") {
#         set resp.http.Location = "http://cockroachdb:8080/";
#     }
# }

sub vcl_deliver {
    # Happens when we have all the pieces we need, and are about to send the
    # response to the client.
}

sub vcl_backend_error {
    set beresp.http.Content-Type = "text/html; charset=utf-8";
    set beresp.http.Retry-After = "60";
    
    synthetic {"
        <html>
        <head><title>404 Not Found</title></head>
        <body>
        <h1>404 - Page Not Found</h1>
        <p>The requested page could not be found.</p>
        </body>
        </html>
    "};
    
    return (deliver);
}
