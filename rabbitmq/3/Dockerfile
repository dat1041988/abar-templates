FROM rabbitmq:3.6

COPY abar-entrypoint.sh /usr/local/bin/
RUN ln -s usr/local/bin/abar-entrypoint.sh / # backwards compat
ENTRYPOINT ["abar-entrypoint.sh"]

# Overwrite the rabbitmq-server script with our own
# The existing docker-entrypoint script requires that the rabbitmq-server script
# is named rabbitmq-server so the CMD we use needs to be called that
RUN mv /usr/lib/rabbitmq/bin/rabbitmq-server /usr/lib/rabbitmq/bin/rabbitmq-server-original
COPY rabbitmq-server /usr/lib/rabbitmq/bin/
CMD ["rabbitmq-server"]

# Overwrite the rabbitmqctl script with our own so it uses the environment
# variables from abar-entrypoint and docker-entrypoint
RUN mv /usr/lib/rabbitmq/bin/rabbitmqctl /usr/lib/rabbitmq/bin/rabbitmqctl-original
COPY rabbitmqctl /usr/lib/rabbitmq/bin/

RUN touch /etc/erl_inetrc && \
    chmod g+w /etc/erl_inetrc
ENV ERL_INETRC=/etc/erl_inetrc

COPY setup-cluster.sh /usr/local/bin/
