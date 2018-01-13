#
# For useful Varnish configuration examples visit:
# https://github.com/mattiasgeniar/varnish-4.0-configuration-templates
#
vcl 4.0;

import std;

backend default {
  .host = ""; # Will be set by start.sh
  .port = ""; # Will be set by start.sh
}

# Purging, allowed only from localhost
acl purge {
  "localhost";
  "0.0.0.0";
  "127.0.0.1";
  # REMOTE_PURGER // Will be set by start.sh
}

sub vcl_recv {
  set req.url = std.querysort(req.url);

  # Remove the Google Analytics added parameters, useless for our backend
  if (req.url ~ "(\?|&)(utm_source|utm_medium|utm_campaign|utm_content|gclid|cx|ie|cof|siteurl)=") {
    set req.url = regsuball(req.url, "&(utm_source|utm_medium|utm_campaign|utm_content|gclid|cx|ie|cof|siteurl)=([A-z0-9_\-\.%25]+)", "");
    set req.url = regsuball(req.url, "\?(utm_source|utm_medium|utm_campaign|utm_content|gclid|cx|ie|cof|siteurl)=([A-z0-9_\-\.%25]+)", "?");
    set req.url = regsub(req.url, "\?&", "?");
  }

  # Strip hash, server doesn't need it.
  if (req.url ~ "\#") {
    set req.url = regsub(req.url, "\#.*$", "");
  }

  # Strip a trailing ? if it exists
  if (req.url ~ "\?$") {
    set req.url = regsub(req.url, "\?$", "");
  }

  # Purging
  if (req.method == "PURGE" || req.method == "BAN") {
    if (!client.ip ~ purge) {
      return(synth(405,"Not allowed."));
    }

    ban("req.http.host == " + req.http.host + " && req.url == " + req.url);
    ban("req.http.host == " + req.http.host + " && req.url ~ " + req.url);

    return (synth(200,"Purged " + req.url + " " + req.http.host));
  }

  # Support WebSockets
  if (req.http.upgrade ~ "(?i)websocket") {
      return (pipe);
  }

  # Only cache GET and HEAD requests
  if (req.method != "GET" && req.method != "HEAD") {
    return (pass);
  }

  # Do not static files:
  #   - They do not cause load to be served
  #   - Varnish memory is expensive so use it for dynamic app pages
  #   - An object storage and a different domain is a better choice for serving static files
  #
  # Read more here: https://ma.ttias.be/stop-caching-static-files-in-varnish/
  # You can add ico|css|txt|js|ttf|eot|otf|woff|woff2 if you're low on memory for your important dynamic pages.
  #
  if (req.url ~ "\.(jpg|jpeg|gif|png|zip|tgz|gz|rar|bz2|pdf|tar|wav|bmp|rtf|flv|swf|7z|avi|bz2|flac|flv|gz|mka|mkv|mov|mp3|mp4|mpeg|mpg|ogg|ogm|opus|rar|tar|tgz|tbz|txz|wav|webm|xz|zip)$") {
    return (pass);
  }

  # Remove the proxy header (see https://httpoxy.org/#mitigate-varnish)
  unset req.http.proxy;

  # Do not cache if user tries authentication
  if (req.http.Authorization) {
    return (pass);
  }

  #
  # Ignore unneeded cookies, on pages you want to cache
  # but may have cookies that are of no interest to the server.
  #

  # Remove has_js and __* cookies.
  set req.http.Cookie = regsuball(req.http.Cookie, "(^|;\s*)(_[_a-z]+|has_js)=[^;]*", "");

  # Remove any Google Analytics based cookies
  set req.http.Cookie = regsuball(req.http.Cookie, "_ga=[^;]+(; )?", "");
  set req.http.Cookie = regsuball(req.http.Cookie, "_gat=[^;]+(; )?", "");
  set req.http.Cookie = regsuball(req.http.Cookie, "utmctr=[^;]+(; )?", "");
  set req.http.Cookie = regsuball(req.http.Cookie, "utmcmd.=[^;]+(; )?", "");
  set req.http.Cookie = regsuball(req.http.Cookie, "utmccn.=[^;]+(; )?", "");

  # Remove a ";" prefix, if present.
  set req.http.Cookie = regsuball(req.http.Cookie, "^;\s*", "");

  # Are there cookies left with only spaces or that are empty?
  if (req.http.cookie ~ "^\s*$") {
    unset req.http.cookie;
  }

  return (hash);
}

sub vcl_backend_response {
  # Cache all objects for 24 hours
  set beresp.ttl = 24h;

  # If server forces to cache we'll remove Set-Cookie
  if (beresp.http.X-Cacheable ~ "1") {
    unset beresp.http.set-cookie;
  }

  # Support pragma: nocache sent by backend
  if (beresp.http.Pragma ~ "nocache") {
    set beresp.uncacheable = true;
    set beresp.ttl = 120s; # how long not to cache this url.
  }

  # Do not cache files larger than 2MB
  if (std.integer(beresp.http.Content-Length, 0) > 2000000) {
    set beresp.uncacheable = true;
    set beresp.ttl = 120s;
    return (deliver);
  }
}

sub vcl_pipe {
  # Support WebSockets
  if (req.http.upgrade) {
    set bereq.http.upgrade = req.http.upgrade;
    set bereq.http.connection = req.http.connection;
  }
}

# The data on which the hashing will take place
sub vcl_hash {
  # Called after vcl_recv to create a hash value for the request. This is used as a key
  # to look up the object in Varnish.

  hash_data(req.url);

  if (req.http.host) {
    hash_data(req.http.host);
  }

  # hash cookies for requests that have them
  if (req.http.Cookie) {
    hash_data(req.http.Cookie);
  }

  # prevent an infinite loop when backend redirects domains (http -> https or www <-> without-www)
  if (req.http.X-Forwarded-Proto) {
    hash_data(req.http.X-Forwarded-Proto);
  }
}

sub vcl_deliver {
  if (obj.hits > 0) {
    set resp.http.X-Cache = "HIT";
  } else {
    set resp.http.X-Cache = "MISS";
  }

  # Remove some headers: PHP version, etc.
  unset resp.http.X-Powered-By;

  # And add the number of hits in the header:
  set resp.http.X-Cache-Hits = obj.hits;
}