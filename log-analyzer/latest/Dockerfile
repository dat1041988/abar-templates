FROM python:3

ENV TZ=Asia/Tehran \
    USER_NAME=ossutil \
    HOME=/etc/ossutil

# Required packages
RUN apt-get update -y && \
    apt-get install -y \
      bash \
      tzdata \
      curl \
      unzip \
    && rm -rf /var/lib/apt/lists/* && \
    cp /usr/share/zoneinfo/${TZ} /etc/localtime && \
    echo "${TZ}" > /etc/timezone

# Install HAProxy Analysis
RUN curl -L https://github.com/gforcada/haproxy_log_analysis/archive/master.zip -o /tmp/haproxy_log_analysis.zip && \
    cd /tmp && \
    unzip haproxy_log_analysis.zip && \
    cd haproxy_log_analysis-master && \
    python setup.py install && \
    rm -rf /tmp/*

# Install OSS Util
RUN curl -L http://public.abarcloud.com/tools/ossutil64 -o /usr/local/bin/ossutil && \
    chmod +x /usr/local/bin/ossutil

# Permissions
RUN mkdir -p /var/log /etc/ossutil && \
    chgrp -R 0 /var/log /etc/ossutil && \
    chmod -R g=u /var/log /etc/ossutil && \
    chmod g=u /etc/passwd

# Scripts
ADD entrypoint.sh /usr/local/bin/entrypoint.sh
ADD helper.sh /usr/local/bin/helper.sh
RUN chmod +x \
  /usr/local/bin/entrypoint.sh \
  /usr/local/bin/helper.sh

USER 10001

ENTRYPOINT ["entrypoint.sh"]

CMD ["tail", "-f", "/dev/null"]
