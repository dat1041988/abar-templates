#!/bin/bash

echo "Reloading haproxy"
if [ -e /var/run/supervisord.sock ]; then
  echo "supervisord is running"
  supervisorctl -c supervisord.conf restart haproxy
else
  echo "supervisord is not running"
fi
