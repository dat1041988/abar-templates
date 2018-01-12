FROM redis:4.0.6-alpine

RUN apk update && \
    apk add --no-cache bash supervisor && \
    rm -rf /var/cache/apk/*

COPY config/supervisord.conf /etc/supervisord.conf
COPY config/master.conf \
     config/slave.conf \
     config/sentinel.conf \
        /redis/config/

COPY start.sh /start.sh

RUN chmod +x /start.sh && \
    chgrp -R 0 /var/run /var/log /redis/config /etc/supervisord.conf /etc && \
    chmod -R g=u /var/run /var/log /redis/config /etc/supervisord.conf /etc

CMD ["/start.sh"]

EXPOSE 6379 26379

USER 1001
