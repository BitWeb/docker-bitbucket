FROM bitweb/java:8
MAINTAINER BitWeb

# Configuration variables.
ENV BITBUCKET_HOME    /var/atlassian/bitbucket
ENV BITBUCKET_INSTALL /opt/atlassian/bitbucket
ENV BITBUCKET_VERSION 5.1.3
ENV DOWNLOAD_URL      https://downloads.atlassian.com/software/stash/downloads/atlassian-bitbucket-${BITBUCKET_VERSION}.tar.gz

# MySQL Connector
ENV CONNECTOR_VERSION      5.1.40
ENV CONNECTOR_DOWNLOAD_URL https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-${CONNECTOR_VERSION}.tar.gz

#################################################
####     No need to edit below this line     ####
#################################################

RUN apt-get update -qq \
    && apt-get install -y --no-install-recommends git libtcnative-1 curl htop nano \
    && apt-get clean autoclean \
    && apt-get autoremove --yes \
    && rm -rf /var/lib/{apt,dpkg,cache,log}/

# Installs Bitbucket server and creates required directories and sets correct permissions and owners
RUN mkdir -p             ${BITBUCKET_INSTALL} \
    && mkdir -p          ${BITBUCKET_HOME} \
    && mkdir -p          ${BITBUCKET_HOME}/lib \
    && chmod -R 700      ${BITBUCKET_HOME} \
    && curl -L --silent  ${DOWNLOAD_URL} | tar -xz --strip=1 -C "$BITBUCKET_INSTALL" \
    && curl -Ls          ${CONNECTOR_DOWNLOAD_URL} | tar -xz --directory ${BITBUCKET_INSTALL}/lib --strip-components=1 --no-same-owner "mysql-connector-java-$CONNECTOR_VERSION/mysql-connector-java-$CONNECTOR_VERSION-bin.jar" \
    && mkdir -p          ${BITBUCKET_INSTALL}/conf/Catalina      \
    && mkdir -p          ${BITBUCKET_INSTALL}/logs               \
    && mkdir -p          ${BITBUCKET_INSTALL}/temp               \
    && mkdir -p          ${BITBUCKET_INSTALL}/work               \
    && chmod -R 700      ${BITBUCKET_INSTALL}/conf/Catalina      \
    && chmod -R 700      ${BITBUCKET_INSTALL}/logs               \
    && chmod -R 700      ${BITBUCKET_INSTALL}/temp               \
    && chmod -R 700      ${BITBUCKET_INSTALL}/work               \
    && ln --symbolic     "/usr/lib/x86_64-linux-gnu/libtcnative-1.so" "${BITBUCKET_INSTALL}/lib/native/libtcnative-1.so"

# Set BITBUCKET_HOME env variable
RUN sed -i "s#export BITBUCKET_HOME=#export BITBUCKET_HOME=$BITBUCKET_HOME#g" ${BITBUCKET_INSTALL}/bin/set-bitbucket-home.sh
    
# Change entropy gathering daemon https://jira.atlassian.com/browse/BSERV-8345
RUN sed -i 's/JVM_SUPPORT_RECOMMENDED_ARGS=""/JVM_SUPPORT_RECOMMENDED_ARGS="-Djava\.security\.egd=file:\/dev\/\.\/urandom"/g' ${BITBUCKET_INSTALL}/bin/_start-webapp.sh

WORKDIR $BITBUCKET_INSTALL

# HTTP Port
EXPOSE 7990

# SSH Port
EXPOSE 7999

# Startup
CMD ["./bin/start-bitbucket.sh", "-fg"]
