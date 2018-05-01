FROM python:3.6-alpine

# runtime dependencies
RUN set -ex \
	&& apk add --no-cache --virtual .pgadmin4-rundeps \
		bash \
		postgresql

ENV PGADMIN4_VERSION 3.0
ENV PGADMIN4_DOWNLOAD_URL https://ftp.postgresql.org/pub/pgadmin/pgadmin4/v3.0/pip/pgadmin4-3.0-py2.py3-none-any.whl

RUN set -ex \
	&& apk add --no-cache --virtual .build-deps \
		gcc \
		musl-dev \
		postgresql-dev \
	&& pip --no-cache-dir install \
		$PGADMIN4_DOWNLOAD_URL \
	&& apk del .build-deps

COPY entrypoint.sh /

RUN \
    PGADMIN_SITES_DIR=`python -c 'import os; print(os.path.dirname(os.__file__))'`/site-packages/pgadmin4 && \
    mkdir -p     $PGADMIN_SITES_DIR /var/lib/pgadmin && \
    chgrp -R 0   $PGADMIN_SITES_DIR /var/lib/pgadmin /var/log && \
    chmod -R g=u $PGADMIN_SITES_DIR /var/lib/pgadmin /var/log && \
    chmod +x /entrypoint.sh

EXPOSE 5050

ENTRYPOINT ["/entrypoint.sh"]
CMD ["pgadmin4"]

