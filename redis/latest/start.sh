#!/usr/bin/env bash

#$1 - parameter; $2 - value; $3 - default value; $4 - file;
set_config () {
    [[ -z "$2" ]] &&  sed -i "s/{{ $1 }}/$3/g" $4 || sed -i "s/{{ $1 }}/$2/g" $4
}

domain_to_ip () {
    getent hosts "$1" | cut -d' ' -f1
}

replication_role () {
    set +e
    local -r info=$(timeout -t 5 redis-cli -h "$1" -a "${REDIS_PASSWORD}" info replication)
    set -e
    echo "$info" | grep -e '^role:' | cut -d':' -f2 | tr -d '[:space:]'
}

server_domains () {
  dig +noall +answer srv "_server._tcp.${SERVICE_NAME}.${NAMESPACE}.svc.cluster.local" | awk -F' ' '{print $NF}' | sed 's/\.$//g'
}

get_master_ip () {
    for peer in $(server_domains); do
        if [ "$(replication_role "$peer")" = 'master' ]; then
            domain_to_ip "$peer"
            return
        fi
    done
    echo -n
}

default_quorum_number () {
    local total=$(server_domains | wc -l)
    let number=$total/2+1
    echo $number
}

configure_master () {
  cp /redis/config/master.conf /redis/config/server.conf
}

configure_slave () {
  while true; do
    MASTER_IP=$(get_master_ip)

    if [ -z "${MASTER_IP}" ]; then
        echo "Could not find a master. Retrying..."
    else
        echo "Found master-candidate peer (${MASTER_IP}) for slave configuration..."

        role=$(replication_role "${MASTER_IP}")
        if [ "${role}" = 'master' ]; then
            break
        fi

        echo "Peer (${MASTER_IP}) was not really a master (it was ${role}). Retrying..."
    fi

    sleep 10
  done

  SLAVE_CONF=/redis/config/slave.conf

  set_config master_ip "${MASTER_IP}" "" ${SLAVE_CONF}
  set_config master_port "${MASTER_PORT}" 6379 ${SLAVE_CONF}

  cp ${SLAVE_CONF} /redis/config/server.conf
}

configure_sentinel() {
  while true; do
    if [[ "${ROLE}" == "master" ]]; then
        MASTER_IP="$( hostname -i )"
        break
    fi

    MASTER_IP=$(get_master_ip)

    if [ -z "${MASTER_IP}" ]; then
        echo "Could not find a master. Retrying..."
    else
        echo "Found master-candidate peer (${MASTER_IP}) for sentinel configuration..."

        role=$(replication_role "${MASTER_IP}")
        if [ "${role}" = 'master' ]; then
            break
        fi

        echo "Peer (${MASTER_IP}) was not really a master (it was ${role}). Retrying..."
    fi

    sleep 10
  done

  SENTINEL_CONF=/redis/config/sentinel.conf

  set_config master_name "${MASTER_NAME}" mymaster ${SENTINEL_CONF}
  set_config master_ip "${MASTER_IP}" "127.0.0.1" ${SENTINEL_CONF}
  set_config master_port "${MASTER_PORT}" 6379 ${SENTINEL_CONF}
  set_config redis_password "${REDIS_PASSWORD}" redis ${SENTINEL_CONF}
  set_config quorum "${QUORUM}" "$(default_quorum_number)" ${SENTINEL_CONF}
  set_config announce_ip "$( hostname -i )" "" ${SENTINEL_CONF}
}

# Use a little lower value for maxmemory so that there is some free RAM on the system for slave
# output buffers AND sentinel process.
REDIS_MAXMEMORY=$(echo | awk '{ print '${REDIS_MAXMEMORY}'*0.8}')

if [[ "${SINGLE_NODE}" == "true" ]]; then
    # Do not auto-start sentinel service for single-node setup
    sed -i '$!N;s/\(command=redis-sentinel.*\n\)\(autostart.*\)/\1\autostart=false\nautorestart=false/;P;D' /etc/supervisord.conf

    configure_master
else
    # if it's not the first StatefulSet pod wait for sentinel service,
    # just to make sure we won't have 2 masters when pods start in parallel (after a Kubernetes node restart)
    hostname=$(hostname)
    if [[ "$hostname" != *"-0" ]]; then
        echo "Waiting for sentinel..."
        until nc -z -v -w30 ${SENTINEL_HOST} ${SENTINEL_PORT}; do sleep 1; done
    fi

    # Check if can get master's IP, if not, it means this node must be master.
    MASTER_IP=$(get_master_ip)

    if [ -z ${MASTER_IP} ]; then
      echo "[NOTICE] This node is a redis master. No other master found."
      export ROLE="master"
    else
      echo "[NOTICE] This node is a slave of ${MASTER_IP}"
      export ROLE="slave"
    fi

    configure_sentinel

    if [[ "${ROLE}" == "master" ]]; then
      configure_master
    else
      configure_slave
    fi
fi

# Whether master or slave and single-node or replication apply general configurations
SERVER_CONF=/redis/config/server.conf

set_config redis_password "${REDIS_PASSWORD}" "" ${SERVER_CONF}
set_config maxmemory "${REDIS_MAXMEMORY}" 0 ${SERVER_CONF}
set_config maxmemory_policy "${REDIS_MAXMEMORY_POLICY}" "noeviction" ${SERVER_CONF}
set_config appendonly "${REDIS_APPENDONLY}" "no" ${SERVER_CONF}
set_config announce_ip "$( hostname -i )" "" ${SERVER_CONF}

/usr/bin/supervisord -c /etc/supervisord.conf