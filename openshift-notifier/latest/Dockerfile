FROM centos/ruby-23-centos7

USER root

RUN yum install -y wget && \
    yum clean all -y

RUN wget https://github.com/openshift/origin/releases/download/v1.5.0/openshift-origin-client-tools-v1.5.0-031cbe4-linux-64bit.tar.gz && \
  tar xzf openshift-origin-client-tools-v1.5.0-031cbe4-linux-64bit.tar.gz && \
  mv openshift-origin-client-tools-v1.5.0-031cbe4-linux-64bit/oc /usr/local/bin/

RUN mkdir /.kube && chmod -R g+ws /.kube

COPY Gemfile .
COPY Gemfile.lock .
RUN scl enable rh-ruby23 "bundle install"

COPY notifier.rb .
RUN chmod +x notifier.rb

USER 1001

CMD scl enable rh-ruby23 "bundle exec /opt/app-root/src/notifier.rb"
