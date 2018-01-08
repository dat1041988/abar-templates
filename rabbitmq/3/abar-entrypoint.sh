#!/bin/bash

set -e

# Use SSL if any certs exist
[ -s "/certs/cert.pem" ] && export RABBITMQ_SSL_CERTFILE=/certs/cert.pem
[ -s "/certs/key.pem" ] && export RABBITMQ_SSL_KEYFILE=/certs/key.pem
[ -s "/certs/cacert.pem" ] && export RABBITMQ_SSL_CACERTFILE=/certs/cacert.pem
# The AbarCloud template sets these env vars by default so unset them if we have
# no certs
if [ -z "$RABBITMQ_SSL_CERTFILE" ] && [ -z "$RABBITMQ_SSL_KEYFILE" ] && [ -z "$RABBITMQ_SSL_CACERTFILE" ]; then
  unset RABBITMQ_SSL_FAIL_IF_NO_PEER_CERT
  unset RABBITMQ_SSL_VERIFY
fi

# Get the search domain for the namespace
# e.g. <project>.svc.cluster.local
namespace_search_domain=$(cat /etc/resolv.conf | grep search | awk '{ print $2 }')
# Use this to construct a search domain for the service
# e.g. rabbitmq.<project>.svc.cluster.local
service_search_domain="\"$RABBITMQ_SERVICE_DOMAIN.$namespace_search_domain\""
[ "$service_search_domain" == "\".\"" ] && service_search_domain=""

# Get the existing search domains from /etc/resolv.conf and format like:
# "search_domain_1","search_domain_2","search_domain_3"
existing_search_domains=$(cat /etc/resolv.conf | grep search | awk '{for (i=2; i<=NF; i++) print "\""$i"\""}' | tr '\n' ',' | sed 's/,$//')
[ -n "$existing_search_domains" ] && existing_search_domains=",$existing_search_domains"

# Write out to a file so we can use this as the Erlang VM inetrc config
cat <<EOF > /etc/erl_inetrc
{lookup, [dns]}.
{hosts_file, ""}.
{resolv_conf, ""}.
{search, [$service_search_domain$existing_search_domains]}.
EOF
# Append the existing nameservers from /etc/resolv.conf and format like this:
# {nameserver, {1,2,3,4}}.
# {nameserver, {5,6,7,8}}.
cat /etc/resolv.conf | grep nameserver | awk '{gsub(/\./,",",$2); print "{nameserver, {"$2"}}." }' >> /etc/erl_inetrc

# Call the existing docker entrypoint
/usr/local/bin/docker-entrypoint.sh "$@"
