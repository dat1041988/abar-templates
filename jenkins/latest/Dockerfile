FROM openshift/jenkins-2-centos7:v3.10

USER root

COPY plugins.txt /opt/openshift/configuration/plugins.txt
COPY start.sh prepare.sh /

RUN chmod +x /start.sh /prepare.sh && \
    /prepare.sh && \
    chgrp -R 0 /usr/jenkins-installed && \
    chmod -R g=u /usr/jenkins-installed

CMD /start.sh
