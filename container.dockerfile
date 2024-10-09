ARG VERSION
FROM ubuntu:jammy-20240911.1
ARG VERSION
ENV CONTAINER_VERSION=$VERSION
ENV GRAYLOG_VERSION=6.1.0-13.rc.1

# Switch to Berkeley OCF mirror for updates, install curl and gnupg
RUN sed -i 's|ports.ubuntu.com|mirrors.ocf.berkeley.edu|g' /etc/apt/sources.list && apt update && apt install --no-install-recommends -y ca-certificates curl gnupg wget && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /etc/ssl/private/ssl-cert-snakeoil.key && install -m 0755 -d /etc/apt/keyrings

# Add MongoDB repository
RUN curl -fsSL https://pgp.mongodb.com/server-6.0.asc | gpg -o /usr/share/keyrings/mongodb-server-6.0.gpg --dearmor
RUN echo "deb [arch="$(dpkg --print-architecture)" signed-by=/usr/share/keyrings/mongodb-server-6.0.gpg] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/6.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-6.0.list

# Install all packages, then create runtime user and directories
RUN apt update && apt upgrade -y && \
wget "https://packages.graylog2.org/repo/debian/pool/stable/6.1/g/graylog-datanode/graylog-datanode_${GRAYLOG_VERSION}_$(dpkg --print-architecture).deb" && \
wget "https://packages.graylog2.org/repo/debian/pool/stable/6.1/g/graylog-server/graylog-server_${GRAYLOG_VERSION}_$(dpkg --print-architecture).deb" && \
DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt install --no-install-recommends -y ./*.deb less mongodb-org nano supervisor && \
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /etc/ssl/private/ssl-cert-snakeoil.key ./*.deb && \
addgroup runtime && useradd -g runtime runtime && \
mkdir -p /data && chmod a+rwx /data && \
mkdir -p /opt/supervisor/bin && mkdir -p /opt/supervisor/logs && chown -R runtime:runtime /opt/supervisor && \
mkdir -p /usr/local/var && chown -R runtime:runtime /usr/local/var && \
chown -R runtime:runtime /var/log/mongodb && \
chown -R runtime:runtime /etc/default/graylog-server /etc/graylog/server /var/lib/graylog-server /var/log/graylog-server && \
chown -R runtime:runtime /etc/default/graylog-datanode /etc/graylog/datanode /var/lib/graylog-datanode /var/log/graylog-datanode

# Configure datanode
RUN sed -i 's|file://$(readlink -f "${DATANODE_LOG4J_CONFIG_FILE}")|file:///etc/graylog/datanode/log4j2.xml|g' /usr/share/graylog-datanode/bin/graylog-datanode && \
sed -i 's|<Appenders>|<Appenders><Console name="STDOUT" target="SYSTEM_OUT"><PatternLayout pattern="%d{yyyy-MM-dd'T'HH:mm:ss.SSSXXX} %-5p [%c{1}] %m%n"/></Console>|g' /etc/graylog/datanode/log4j2.xml && \
sed -i 's|<AppenderRef ref="rolling-file"/>|<AppenderRef ref="rolling-file"/><AppenderRef ref="STDOUT"/>|g' /etc/graylog/datanode/log4j2.xml && \
sed -i 's|opensearch_config_location = /var/lib/graylog-datanode/opensearch/config|opensearch_config_location = /data/datanode/opensearch/config|g' /etc/graylog/datanode/datanode.conf && \
sed -i 's|opensearch_data_location = /var/lib/graylog-datanode/opensearch/data|opensearch_data_location = /data/datanode/opensearch/data|g' /etc/graylog/datanode/datanode.conf

# Configure graylog
RUN sed -i 's|GRAYLOG_COMMAND_WRAPPER=""|GRAYLOG_COMMAND_WRAPPER="exec"|g' /etc/default/graylog-server && \
sed -i 's|<Appenders>|<Appenders><Console name="STDOUT" target="SYSTEM_OUT"><PatternLayout pattern="%d{yyyy-MM-dd'T'HH:mm:ss.SSSXXX} %-5p [%c{1}] %m%n"/></Console>|g' /etc/graylog/server/log4j2.xml && \
sed -i 's|<AppenderRef ref="rolling-file"/>|<AppenderRef ref="rolling-file"/><AppenderRef ref="STDOUT"/>|g' /etc/graylog/server/log4j2.xml && \
sed -i 's|data_dir = /var/lib/graylog-server|data_dir = /data/graylog|g' /etc/graylog/server/server.conf && \
sed -i 's|message_journal_dir = /var/lib/graylog-server/journal|message_journal_dir = /data/graylog/journal|g' /etc/graylog/server/server.conf

# Configure supervisord
COPY contents/supervisor/supervisord.conf /etc/supervisord.conf
COPY --chown=runtime:runtime contents/supervisor/autoinit.sh /opt/supervisor/bin

# Configure entrypoint
EXPOSE 5044/tcp
EXPOSE 5140/tcp
EXPOSE 5140/udp
EXPOSE 9000/tcp
EXPOSE 12201/tcp
EXPOSE 12201/udp
EXPOSE 13301/tcp
EXPOSE 13302/tcp
USER runtime
WORKDIR /opt/supervisor/logs
ENTRYPOINT ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]