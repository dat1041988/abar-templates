FROM docker.elastic.co/kibana/kibana:6.1.1

USER root

RUN \
    chgrp -R 0 /usr/share/kibana/ /var/log && \
    chmod -R g=u /usr/share/kibana/ /var/log

USER kibana

