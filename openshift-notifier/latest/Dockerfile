FROM centos/ruby-23-centos7

ENV OC_VERSION=v3.7.0 \
    OC_TAG_SHA=7ed6862

USER root

RUN yum install -y curl && \
    yum clean all -y && \
    curl -sL -o /tmp/oc.tar.gz https://github.com/openshift/origin/releases/download/${OC_VERSION}/openshift-origin-client-tools-${OC_VERSION}-${OC_TAG_SHA}-linux-64bit.tar.gz && \
    tar xzvf /tmp/oc.tar.gz -C /tmp/ && \
    mv /tmp/openshift-origin-client-tools-${OC_VERSION}-${OC_TAG_SHA}-linux-64bit/oc /usr/local/bin/oc && \
    rm -rf /tmp/oc.tar.gz /tmp/openshift-origin-client-tools-${OC_VERSION}-${OC_TAG_SHA}-linux-64bit && \
    mkdir /.kube && \
    chmod -R g+ws /.kube

COPY Gemfile Gemfile.lock notifier.rb ./
RUN scl enable rh-ruby23 "bundle install" && \
    chmod +x notifier.rb

USER 1001

CMD scl enable rh-ruby23 "bundle exec /opt/app-root/src/notifier.rb"
