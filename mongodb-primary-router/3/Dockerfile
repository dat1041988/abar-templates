FROM haproxy:1.7

RUN  apt-get update \
  && apt-get install -y wget supervisor \
  && rm -rf /var/lib/apt/lists/*

RUN wget https://github.com/kelseyhightower/confd/releases/download/v0.11.0/confd-0.11.0-linux-amd64 && \
    mv confd-0.11.0-linux-amd64 /usr/local/bin/confd && \
    chmod +x /usr/local/bin/confd

RUN chown -R 1001:0 /var/run /run /var/log /usr/local/etc/haproxy && \
    chmod -R g+w /var/run /run /var/log /usr/local/etc/haproxy

EXPOSE 27017

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

COPY mongodb-discovery.sh /
RUN chmod +x /mongodb-discovery.sh

COPY reload-haproxy.sh /
RUN chmod +x /reload-haproxy.sh

COPY supervisord.conf /

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/supervisord.conf"]

COPY confd /etc/confd

USER 1001
