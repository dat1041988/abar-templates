FROM node:8-alpine

RUN apk add --update --no-cache \
        ca-certificates \
    && \
    npm config set unsafe-perm true && \
    npm install --no-optional -g redis-commander@0.4.5 && \
    touch /.redis-commander && \
    chgrp -R 0 /.redis-commander && \
    chmod -R g=u /.redis-commander

COPY start.sh /start.sh

CMD ["/start.sh"]

EXPOSE 8080
