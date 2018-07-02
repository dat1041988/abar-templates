FROM centos:7

ENV JAVA_HOME=/usr/lib/jvm/jre-1.8.0-openjdk \
    KAFKA_VERSION=1.0.0 \
    SCALA_VERSION=2.11 \
    KAFKA_HOME=/opt/kafka

COPY fix-permissions /usr/local/bin

RUN INSTALL_PKGS="gettext tar zip unzip hostname java-1.8.0-openjdk openssl" && \
    yum install -y $INSTALL_PKGS && \
    rpm -V $INSTALL_PKGS && \
    yum clean all  && \
    mkdir -p $KAFKA_HOME && \
    curl -fSL $(curl -s http://www.apache.org/dyn/closer.cgi/kafka/$SCALA_VERSION-$KAFKA_VERSION/kafka-$SCALA_VERSION-$KAFKA_VERSION.tgz?as_json=1 | grep preferred | cut -f 4 -d \" -)/kafka/$KAFKA_VERSION/kafka_$SCALA_VERSION-$KAFKA_VERSION.tgz | tar xzf - --strip 1 -C $KAFKA_HOME/ && \
    mkdir -p $KAFKA_HOME/logs && \
    /usr/local/bin/fix-permissions $KAFKA_HOME

WORKDIR "/opt/kafka"

RUN sed -i "/listeners=/c listeners=SSL://:9093" config/server.properties
RUN sed -i "/listener.security.protocol.map=/c listener.security.protocol.map=SSL:SSL" config/server.properties
RUN echo $'\n\
    ssl.client.auth=required\n\
    security.protocol=SSL\n\
    security.inter.broker.protocol=SSL\n\
    ssl.keystore.location=/var/private/ssl/kafka.server.keystore.jks\n\
    ssl.keystore.password=test1234\n\
    ssl.key.password=test1234\n\
    ssl.truststore.location=/var/private/ssl/kafka.server.truststore.jks\n\
    ssl.truststore.password=test1234\n'\
>> config/server.properties

EXPOSE 9093
