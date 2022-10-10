ARG GRAFANA_VERSION="8.2.2"

FROM grafana/grafana:${GRAFANA_VERSION}

USER root

ARG GF_INSTALL_IMAGE_RENDERER_PLUGIN="false"

ARG GF_GID="0"
ENV GF_PATHS_PLUGINS="/var/lib/grafana-plugins"
ENV GF_INSTALL_PLUGINS=""
ENV GF_PLUGINS_ALLOW_LOADING_UNSIGNED_PLUGINS="grafana-clock-panel,volkovlabs-image-panel,alexanderzobnin-zabbix-app,alexanderzobnin-zabbix-datasource,alexanderzobnin-zabbix-triggers-panel,grafana-clock-panel"
ENV GF_SECURITY_ADMIN_PASSWORD="ADD-SENHA"
RUN mkdir -p "$GF_PATHS_PLUGINS" && \
    chown -R grafana:${GF_GID} "$GF_PATHS_PLUGINS"

RUN if [ $GF_INSTALL_IMAGE_RENDERER_PLUGIN = "true" ]; then \
    echo "http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories && \
    echo "http://dl-cdn.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories && \
    echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
    apk --no-cache  upgrade && \
    apk add --no-cache udev ttf-opensans chromium && \
    rm -rf /tmp/* && \
    rm -rf /usr/share/grafana/tools/phantomjs; \
fi

USER grafana

ENV GF_PLUGIN_RENDERING_CHROME_BIN="/usr/bin/chromium-browser"

RUN if [ $GF_INSTALL_IMAGE_RENDERER_PLUGIN = "true" ]; then \
    grafana-cli \
        --pluginsDir "$GF_PATHS_PLUGINS" \
        --pluginUrl https://github.com/grafana/grafana-image-renderer/releases/latest/download/plugin-linux-x64-glibc-no-chromium.zip \
        plugins install grafana-image-renderer; \
fi

ARG GF_INSTALL_PLUGINS=""

RUN if [ ! -z "${GF_INSTALL_PLUGINS}" ]; then \
    OLDIFS=$IFS; \
    IFS=','; \
    for plugin in ${GF_INSTALL_PLUGINS}; do \
        IFS=$OLDIFS; \
        if expr match "$plugin" '.*\;.*'; then \
            pluginUrl=$(echo "$plugin" | cut -d';' -f 1); \
            pluginInstallFolder=$(echo "$plugin" | cut -d';' -f 2); \
            grafana-cli --pluginUrl ${pluginUrl} --pluginsDir "${GF_PATHS_PLUGINS}" plugins install "${pluginInstallFolder}"; \
        else \
            grafana-cli --pluginsDir "${GF_PATHS_PLUGINS}" plugins install ${plugin}; \
        fi \
    done \
fi
# Copy scripts
#-------------
#COPY certificates/* /tmp
COPY certificates/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
#COPY --chown=root:root /home/grafana/grafana-plugins/* /var/lib/grafana-plugins
COPY grafana-plugins/* /var/lib/grafana-plugins/
#COPY --chown=grafana:root /home/grafana/grafana-plugins/* /var/lib/grafana-plugins
#COPY certificates/* /tmp

#COPY --chown=grafana:root /tmp/* /etc/ca-certificates

USER root
RUN apk update && apk --no-cache add vim curl

#ENTRYPOINT [ "bash" ]