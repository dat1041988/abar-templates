FROM alpine:3.6

RUN apk add --no-cache bash wget jq postgresql mongodb-tools mysql-client && \
    wget http://public.abarcloud.com/tools/ossutil32 && \
    mv ossutil32 /usr/local/bin/ossutil && \
    chmod +x /usr/local/bin/ossutil && \
    touch /.ossutilconfig && \
    mkdir /ossutil_output /.ossutil_checkpoint && \
    chmod g+w /.ossutilconfig /ossutil_output /.ossutil_checkpoint && \
    chown 1001:0 /.ossutilconfig /ossutil_output /.ossutil_checkpoint

COPY entrypoint.sh backup.sh idle.sh /
RUN chmod +x entrypoint.sh backup.sh idle.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/backup.sh"]

USER 1001
