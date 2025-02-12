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

    if (std.healthy(req.backend_hint)) {
        // change the behavior for healthy backends: Cap grace to 10s
        set req.grace = 1m;
    }
}

sub vcl_backend_response {
    # Happens after we have read the response headers from the backend.
    if (beresp.status == 200 || beresp.status == 301 || beresp.status == 302) {
        set beresp.ttl = 1m; # How long the cache is valid
        set beresp.grace = 24h; # How long the server can serv it after it is invalid (changed in vcl_recv for healthy servers)
        set beresp.keep = 4m; # Keep stale object in cache for background fetch
    } else {
        set beresp.ttl = 0s;
    }

    if (beresp.status >= 500 && bereq.is_bgfetch) {
        return (abandon);
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
    if (obj.ttl <= 0s && obj.grace <= 0s) {
        set beresp.http.Content-Type = "text/html; charset=utf-8";
        synthetic {"
            <html>
            <head><title>503 Service Unavailable</title></head>
            <body>
            <h1>Service Unavailable</h1>
            <p>The backend is down and no cached content is available.</p>
            </body>
            </html>
        "};
        return (deliver);
    }
}