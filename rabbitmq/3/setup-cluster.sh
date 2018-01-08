#!/bin/bash

# Wait until Rabbit MQ is ready
# Try this 5 times and sleep 10 seconds
n=0
max=5
until [ $n -ge $max ]; do
  rabbitmqctl node_health_check && break
  n=$[$n+1]
  if [ $n -ge $max ]; then
    echo "RabbitMQ has not started properly" 1>&2
    exit 1
  fi
  sleep 10
done


# Add it to the cluster of the first pod in the set
if [[ "$HOSTNAME" != "$RABBITMQ_SERVICE_DOMAIN-0" && -z "$(rabbitmqctl cluster_status | grep $RABBITMQ_SERVICE_DOMAIN-0)" ]]; then
  # If the first pod thinks this pod is already in the cluster then remove this node from the cluster first
  if [[ "$(rabbitmqctl -n rabbit@$RABBITMQ_SERVICE_DOMAIN-0 cluster_status | grep $(hostname))" ]]; then
    rabbitmqctl -n rabbit@$RABBITMQ_SERVICE_DOMAIN-0 forget_cluster_node rabbit@$(hostname);
  fi;
  rabbitmqctl stop_app;
  rabbitmqctl join_cluster rabbit@$RABBITMQ_SERVICE_DOMAIN-0;
  rabbitmqctl start_app;
fi;

# If all the HA options are set then create a HA policy
ha_variables_count=$(( \
  $([ -n "$RABBITMQ_HA_SELECTOR" ] && echo 1 || echo 0) + \
  $([ -n "$RABBITMQ_HA_MODE" ] && echo 1 || echo 0) + \
  $([ -n "$RABBITMQ_HA_PARAMS" ] && echo 1 || echo 0) + \
  $([ -n "$RABBITMQ_HA_SYNC_MODE" ] && echo 1 || echo 0) \
))
if (( ha_variables_count == 4 )); then
  rabbitmqctl set_policy ha-all "$RABBITMQ_HA_SELECTOR" '{"ha-mode":"'$RABBITMQ_HA_MODE'","ha-params":'$RABBITMQ_HA_PARAMS',"ha-sync-mode":"'$RABBITMQ_HA_SYNC_MODE'"}';
elif (( ha_variables_count > 0 )); then
  echo "WARNING: Not setting HA policy because not all HA variables are set." 1>&2;
fi
