#!/usr/bin/env bash

#$1 - parameter; $2 - value; $3 - default value; $4 - file;
set_config() {
    [[ -z "$2" ]] &&  sed -i "s/{{ $1 }}/$3/g" $4 || sed -i "s/{{ $1 }}/$2/g" $4
}

function get_master_address()
{
  if [[ "${ROLE}" == "master" ]]; then
    MASTER_IP=$(hostname -i)
  else
    MASTER_IP=$(redis-cli -a ${REDIS_PASSWORD} -h ${SENTINEL_HOST} -p ${SENTINEL_PORT} --csv SENTINEL get-master-addr-by-name mymaster | tr ',' ' ' | cut -d' ' -f1)
    MASTER_IP="${MASTER_IP//\"}"

    if [ -z ${MASTER_IP} ]; then
      echo "Failed to find master."
      sleep 60
      exit 1
    fi
  fi

  echo ${MASTER_IP}
}

function configure_master() {
  MASTER_CONF=/redis/config/master.conf

  set_config redis_password "${REDIS_PASSWORD}" "" ${MASTER_CONF}
  set_config maxmemory "${REDIS_MAXMEMORY}" 13107200 ${MASTER_CONF}
  set_config maxmemory_policy "${REDIS_MAXMEMORY_POLICY}" "noeviction" ${MASTER_CONF}
  set_config appendonly "${REDIS_APPENDONLY}" "no" ${MASTER_CONF}

  cp /redis/config/master.conf /redis/config/server.conf
}

function configure_slave() {
  while true; do
    MASTER_IP=$(get_master_address)

    redis-cli -a ${REDIS_PASSWORD} -h ${MASTER_IP} INFO
    if [[ "$?" == "0" ]]; then
      break
    fi
    echo "Connecting to master failed.  Waiting..."
    sleep 10
  done

  SLAVE_CONF=/redis/config/slave.conf

  set_config master_ip "${MASTER_IP}" "127.0.0.1" ${SLAVE_CONF}
  set_config master_port "${MASTER_PORT}" 6379 ${SLAVE_CONF}
  set_config redis_password "${REDIS_PASSWORD}" "" ${SLAVE_CONF}
  set_config maxmemory "${REDIS_MAXMEMORY}" 0 ${SLAVE_CONF}
  set_config maxmemory_policy "${REDIS_MAXMEMORY_POLICY}" "noeviction" ${SLAVE_CONF}
  set_config appendonly "${REDIS_APPENDONLY}" "no" ${SLAVE_CONF}

  cp /redis/config/slave.conf /redis/config/server.conf
}

function configure_sentinel() {
  while true; do
    MASTER_IP=$(get_master_address)

    # It doesn't need to check connection with master if this pod is itself the master
    if [[ "${ROLE}" == "master" ]]; then
      break
    fi

    redis-cli -a ${REDIS_PASSWORD} -h ${MASTER_IP} INFO
    if [[ "$?" == "0" ]]; then
      break
    fi
    echo "Connecting to master failed.  Waiting..."
    sleep 10
  done

  SENTINEL_CONF=/redis/config/sentinel.conf

  set_config master_name "${MASTER_NAME}" mymaster ${SENTINEL_CONF}
  set_config master_ip "${MASTER_IP}" 127.0.0.1 ${SENTINEL_CONF}
  set_config master_port "${MASTER_PORT}" 6379 ${SENTINEL_CONF}
  set_config redis_password "${REDIS_PASSWORD}" redis ${SENTINEL_CONF}
  set_config quorum "${QUORUM}" 2 ${SENTINEL_CONF}
}

# Use a little lower value for maxmemory so that there is some free RAM on the system for slave
# output buffers (but this is not needed if the policy is 'noeviction').
if [[ "${REDIS_MAXMEMORY_POLICY}" != "noeviction" && ${REDIS_MAXMEMORY} ]]; then
    REDIS_MAXMEMORY=$(echo | awk '{ print '${REDIS_MAXMEMORY}'*0.9}')
fi

if [[ "${SINGLE_NODE}" == "true" ]]; then
    # Do not auto-start sentinel service for single-node setup
    sed '$!N;s/\(command=redis-sentinel.*\n\)\(.*\)/\1\;\2/;P;D' /etc/supervisord.conf

    configure_master
else
    # When running in a replication setup,
    # Figure-out what is role of this node.
    MASTER_INFO=$(timeout -t 10 redis-cli -a ${REDIS_PASSWORD} -h ${SENTINEL_HOST} -p ${SENTINEL_PORT} --csv SENTINEL get-master-addr-by-name mymaster)

    if [ -z ${MASTER_INFO} ]; then
      echo "[NOTICE] This node is a redis master. No other master found."
      export ROLE="master"
    else
      echo "[NOTICE] This node is a slave of $MASTER_INFO"
      export ROLE="slave"
    fi

    configure_sentinel

    if [[ "${ROLE}" == "master" ]]; then
      configure_master
    else
      configure_slave
    fi
fi

/usr/bin/supervisord -c /etc/supervisord.conf