FROM alpine:3.6

RUN apk update && \
    apk add --no-cache bash varnish=4.1.9-r0 && \
    rm -rf /var/cache/apk/*

COPY default.vcl /etc/varnish/default.vcl
COPY entrypoint.sh /entrypoint.sh
COPY start.sh /start.sh

RUN chmod +x /start.sh /entrypoint.sh && \
    mkdir -p /var/log /etc/varnish /usr/local/var/varnish /var/lib/varnish && \
    chgrp -R 0 /var/log /etc/varnish /usr/local/var/varnish /var/lib/varnish && \
    chmod -R g=u /var/log /etc/varnish /usr/local/var/varnish /var/lib/varnish

EXPOSE 8080

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/start.sh"]

USER 1001