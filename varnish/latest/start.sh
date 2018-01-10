#!/usr/bin/env sh

varnishd \
  -j none \
  -F \
  -f /etc/varnish/default.vcl \
  -s "malloc,${VARNISH_MEMORY}" \
  -a 0.0.0.0:8080