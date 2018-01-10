#!/usr/bin/env sh

set -e

VARNISH_CONF=/etc/varnish/default.vcl

sed -i "/\.host = /c .host = \"${TARGET_SERVICE_HOST}\";" ${VARNISH_CONF}
sed -i "/\.port = /c .port = \"${TARGET_SERVICE_PORT}\";" ${VARNISH_CONF}

if [ ! -z ${REMOTE_PURGER} ]; then
    sed -i "/REMOTE_PURGER/c \"${REMOTE_PURGER}\";  # REMOTE_PURGER" ${VARNISH_CONF}
fi

exec "$@"