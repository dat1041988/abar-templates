#!/usr/bin/env bash

until certbot certonly --webroot --agree-tos --quiet -w /usr/share/nginx/html --email ${EMAIL} -d ${DOMAIN}
do
  echo "Unable to validate domain. Will retry in 90 seconds."
  echo "Ensure the old route is deleted and the new one for certbot has been added."
  sleep 90
done

echo "certificate.pem:"
echo "================================================================================"
echo ""
cat /etc/letsencrypt/live/${DOMAIN}/cert.pem
echo ""

echo "private-key.pem:"
echo "================================================================================"
echo ""
cat /etc/letsencrypt/live/${DOMAIN}/privkey.pem
echo ""

echo "ca-certificate.pem "
echo "================================================================================"
echo ""
cat /etc/letsencrypt/live/${DOMAIN}/chain.pem
echo ""

echo "Please save the above files and continue with the renewal documentation."

cleanup ()
{
  kill -s SIGTERM $!
  exit 0
}

trap cleanup SIGINT SIGTERM

while [ 1 ]
do
  sleep 60 &
  wait $!
done
