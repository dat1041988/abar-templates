#!/usr/bin/env bash

if [ ! -f "${JENKINS_HOME}/plugins" ]; then
    mkdir -p ${JENKINS_HOME}
    cp -r /usr/jenkins-installed/* ${JENKINS_HOME}/
fi

exec /usr/libexec/s2i/run


