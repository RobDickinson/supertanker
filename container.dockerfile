ARG VERSION
FROM ubuntu:jammy-20240911.1
ARG VERSION
ENV CONTAINER_VERSION=$VERSION

# Switch to Berkeley OCF mirror for updates, install curl and gnupg
RUN sed -i 's|ports.ubuntu.com|mirrors.ocf.berkeley.edu|g' /etc/apt/sources.list && apt update && apt install --no-install-recommends -y ca-certificates curl gnupg wget && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /etc/ssl/private/ssl-cert-snakeoil.key && install -m 0755 -d /etc/apt/keyrings

# Add Graylog repository
RUN wget https://packages.graylog2.org/repo/packages/graylog-6.0-repository_latest.deb && dpkg -i graylog-6.0-repository_latest.deb && rm -rf graylog-6.0-repository_latest.deb

# Add MongoDB repository
RUN curl -fsSL https://pgp.mongodb.com/server-6.0.asc | gpg -o /usr/share/keyrings/mongodb-server-6.0.gpg --dearmor
RUN echo "deb [arch="$(dpkg --print-architecture)" signed-by=/usr/share/keyrings/mongodb-server-6.0.gpg] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/6.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-6.0.list

# Add OpenSearch repository
RUN curl -o- https://artifacts.opensearch.org/publickeys/opensearch.pgp | gpg --dearmor --batch --yes -o /usr/share/keyrings/opensearch-keyring
RUN echo "deb [arch="$(dpkg --print-architecture)" signed-by=/usr/share/keyrings/opensearch-keyring] https://artifacts.opensearch.org/releases/bundle/opensearch/2.x/apt stable main" | tee /etc/apt/sources.list.d/opensearch-2.x.list

# Install all packages, then create runtime user and directories
RUN apt update && apt upgrade -y && DEBIAN_FRONTEND=noninteractive OPENSEARCH_INITIAL_ADMIN_PASSWORD=$(tr -dc A-Z-a-z-0-9_@#%^-_=+ < /dev/urandom | head -c${1:-32}) TZ=Etc/UTC \
apt install --no-install-recommends -y graylog-server less mongodb-org nano opensearch=2.12.0 supervisor && \
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /etc/ssl/private/ssl-cert-snakeoil.key && \
addgroup runtime && useradd -g runtime runtime && \
mkdir -p /data && chmod a+rwx /data && \
mkdir -p /opt/supervisor/bin && mkdir -p /opt/supervisor/logs && chown -R runtime:runtime /opt/supervisor && \
mkdir -p /usr/local/var && chown -R runtime:runtime /usr/local/var && \
chown -R runtime:runtime /var/log/mongodb && \
chown -R runtime:runtime /etc/opensearch /usr/share/opensearch /var/lib/opensearch /var/log/opensearch && \
chown -R runtime:runtime /etc/default/graylog-server /etc/graylog/server /var/lib/graylog-server /var/log/graylog-server

# Configure graylog
RUN sed -i 's|GRAYLOG_COMMAND_WRAPPER=""|GRAYLOG_COMMAND_WRAPPER="exec"|g' /etc/default/graylog-server && \
sed -i 's|<Appenders>|<Appenders><Console name="STDOUT" target="SYSTEM_OUT"><PatternLayout pattern="%d{yyyy-MM-dd'T'HH:mm:ss.SSSXXX} %-5p [%c{1}] %m%n"/></Console>|g' /etc/graylog/server/log4j2.xml && \
sed -i 's|<AppenderRef ref="rolling-file"/>|<AppenderRef ref="rolling-file"/><AppenderRef ref="STDOUT"/>|g' /etc/graylog/server/log4j2.xml && \
sed -i 's|data_dir = /var/lib/graylog-server|data_dir = /data/graylog|g' /etc/graylog/server/server.conf && \
sed -i 's|message_journal_dir = /var/lib/graylog-server/journal|message_journal_dir = /data/graylog/journal|g' /etc/graylog/server/server.conf

# Configure opensearch
COPY --chown=runtime:runtime contents/opensearch/. /etc/opensearch

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