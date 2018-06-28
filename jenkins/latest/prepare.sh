#!/usr/bin/env bash

echo "Installing plugins..."
/usr/local/bin/install-plugins.sh < /opt/openshift/configuration/plugins.txt

echo "Running jenkins..."
/usr/libexec/s2i/run &

echo "Waiting for Jenkins to bootstrap..."
while [[ "$(curl -L -s -o /dev/null -w ''%{http_code}'' localhost:8080/login)" != "200" ]]; do echo " - Waiting for 200 OK from Jenkins..."; sleep 5;  done

echo "Copying the artifacts..."
ls -lash /usr /var/lib/jenkins /var/lib/jenkins/*
cp -r /var/lib/jenkins /usr/jenkins-installed
ls -lash /usr/jenkins-installed
ls -lash /usr/jenkins-installed/*