#!/usr/bin/env bash

echo $(date)" Starting MongoDB discovery"
while :; do
  unset $(env | awk -F = '{print $1}' | grep "^MONGODB_BACKENDS" | xargs)
  index=1
  for ip in $(getent hosts ${MONGODB_SERVICE_NAME} | awk '{ print $1 }' | sort); do
    export MONGODB_BACKENDS_${index}_IP=$ip
    let index=${index}+1
  done
  /usr/local/bin/confd -onetime -backend env -log-level warn
  if [ "$1" == "-onetime" ]; then
    break
  fi
  sleep 1
done
