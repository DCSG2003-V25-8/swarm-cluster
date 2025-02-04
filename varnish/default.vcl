vcl 4.1;
import directors;

backend bookstack {
    .host = "tasks.bookstack";
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
    vdir.add_backend(bookstack);
}

sub vcl_recv {
    # Happens before we check if we have this in cache already.
    if (req.url ~ "^/admin" || req.http.Authorization){
        return (pass);
    }
}

sub vcl_backend_response {
    # Happens after we have read the response headers from the backend.
    if (beresp.status == 200 || beresp.status == 301 || beresp.status == 302) {
        set beresp.ttl = 1h;
    } else {
        set beresp.ttl = 0s;
    }

    if (beresp.http.Content-Type ~ "text/(html|css|javascript)") {
        set beresp.do_gzip = true;
    }
}

sub vcl_deliver {
    # Happens when we have all the pieces we need, and are about to send the
    # response to the client.
}
