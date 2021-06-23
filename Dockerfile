FROM debian:buster-slim as builder
LABEL maintainer Daniel Ricci daniel@bpatechnologies.com
USER root
ARG VERSION=7.15.0
ARG SNAPSHOT=false
ARG DISTRO=wildfly

ARG MAVEN_PROXY_HOST
ARG MAVEN_PROXY_PORT
ARG MAVEN_PROXY_USER
ARG MAVEN_PROXY_PASSWORD

ARG JMX_PROMETHEUS_VERSION=0.12.0
RUN mkdir -p /usr/share/man/man1 /usr/share/man/man2
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    maven \
    tar \
    wget \
    xmlstarlet
    
COPY settings.xml download.sh camunda-run.sh camunda-tomcat.sh camunda-wildfly.sh  /tmp/

RUN /tmp/download.sh


##### FINAL IMAGE #####

FROM debian:buster-slim
LABEL maintainer Daniel Ricci daniel@bpatechnologies.com
USER root
ARG VERSION=7.15.0
ENV WILDFLY_VERSION=22.0.1.Final
ENV CAMUNDA_VERSION=7.15.0
ENV SERVER wildfly-22.0.1.Final
ENV DB_DRIVER=
ENV DB_URL=
ENV DB_USERNAME=
ENV DB_PASSWORD=
ENV DB_CONN_MAXACTIVE=20
ENV DB_CONN_MINIDLE=5
ENV DB_CONN_MAXIDLE=20
ENV DB_VALIDATE_ON_BORROW=false
ENV DB_VALIDATION_QUERY="SELECT 1"
ENV SKIP_DB_CONFIG=
ENV WAIT_FOR=
ENV WAIT_FOR_TIMEOUT=30
ENV TZ=America/Sao_Paulo
ENV DEBUG=false
ENV JAVA_OPTS="-Xmx768m -XX:MaxMetaspaceSize=256m"
ENV JMX_PROMETHEUS=false
ENV JMX_PROMETHEUS_CONF=/camunda/javaagent/prometheus-jmx.yml
ENV JMX_PROMETHEUS_PORT=9404
ENV DEBIAN_FRONTEND=noninteractive
RUN mkdir -p /usr/share/man/man1 /usr/share/man/man2
ENV STANDALONE_CONF /camunda/standalone/configuration/standalone.xml

# Downgrading wait-for-it is necessary until this PR is merged
# https://github.com/vishnubob/wait-for-it/pull/68
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    openjdk-11-jre \
    tzdata \
    ca-certificates \
    tini \
    xmlstarlet \
    curl \
    && curl -o /usr/local/bin/wait-for-it.sh \
      "https://raw.githubusercontent.com/vishnubob/wait-for-it/a454892f3c2ebbc22bd15e446415b8fcb7c1cfa4/wait-for-it.sh" \
    && chmod +x /usr/local/bin/wait-for-it.sh

ENV ZONE="America/Sao_Paulo"
RUN ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
RUN echo 'LC_ALL="pt_BR.UTF-8"' >> /etc/locale.conf
ENV LANG=pt_BR.UTF-8
ENV LC_ALL="pt_BR.UTF-8"
ENV LANGUAGE=pt_BR.UTF-8
RUN echo "America/Sao_Paulo" > /etc/timezone
ENV TZ=America/Sao_Paulo
ENV LAUNCH_JBOSS_IN_BACKGROUND=true

RUN adduser --uid 1000 --no-create-home --disabled-password --quiet --gecos GECOS camunda

EXPOSE 8080 9404 8000 9990 8009

RUN apt-get clean autoclean
RUN apt-get autoremove --yes
RUN rm -rf /var/lib/{apt,dpkg,cache,log}/
RUN rm -rf /var/cache/apt/archives
RUN rm -rf /var/cache/apt/lists

WORKDIR /camunda
RUN mkdir /camunda/mail
RUN chmod -R a+x /camunda
RUN chown -R camunda:camunda /camunda

USER camunda
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["./camunda.sh"]

COPY --chown=camunda:camunda --from=builder /camunda .

