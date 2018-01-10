#!/usr/bin/env bash

if ! whoami &> /dev/null; then
  echo "Creating user UID entry..."
  if [ -w /etc/passwd ]; then
    echo "${USER_NAME:-default}:x:$(id -u):0:${USER_NAME:-default} user:${HOME}:/sbin/nologin" >> /etc/passwd
  fi
  echo -en "\e[1A"
  echo -e "\e[0K\rUser UID created."
fi

if [ -z ${OSS_ACCESS_KEY_ID} ] || [ -z ${OSS_ACCESS_KEY_SECRET} ] || [ -z ${OSS_ENDPOINT} ]; then
  echo "[WARNING] One or more of OSS_ACCESS_KEY_ID/OSS_ACCESS_KEY_SECRET/OSS_ENDPOINT were not present hence did not authenticate ossutil."
else
  echo "Authenticating ossutil..."
  ossutil config -L EN -i ${OSS_ACCESS_KEY_ID} -k ${OSS_ACCESS_KEY_SECRET} -e ${OSS_ENDPOINT} --output-dir=/etc/ossutil/output --config-file=/etc/ossutil/.config
  if [ $? != "0" ]; then
    echo "Could not authenticate OSS."
    exit 1
  fi

  echo -en "\e[1A"
  echo -e "\e[0K\rOSS authenticated."
fi

# Useful for working with ossutil
# OSS_LOGS_DIR is usually Project's UID
export OSS_LOGS_URL=oss://${OSS_BUCKET_NAME}/${OSS_LOGS_DIR%/}/

exec "$@"