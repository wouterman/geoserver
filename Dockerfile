ARG version='2.27.2'
FROM docker.osgeo.org/geoserver:${version}

# specify volume mount points
ENV GEOSERVER_DATA_DIR=/mnt/geoserver_data_dir
ENV GEOWEBCACHE_CACHE_DIR=/mnt/geoserver_caching

# specify extensions to install and location
ENV ADDITIONAL_LIBS_DIR=/opt/additional/libs/
ENV STABLE_EXTENSIONS="control-flow,monitor,printing,params-extractor,web-resource,vectortiles,css,querylayer,importer"

ENV USER_NAME=geoserveruser \
    HOME=/home/geoserveruser

SHELL ["/bin/bash", "-lc"]

RUN set -eux; \
    getent group 1000 >/dev/null || groupadd -g 1000 "$USER_NAME"; \
    id -u 1000 >/dev/null 2>&1 || useradd -m -d "$HOME" -s /bin/bash -g 1000 -u 1000 "$USER_NAME"

COPY --chown=1000:1000 --chmod=0755 scripts/install-extensions.sh /opt/install-extensions.sh
COPY --chown=1000:1000 --chmod=0755 scripts/startup.sh           /opt/startup.sh

RUN set -eux; \
    /opt/install-extensions.sh; \
    rm -f /opt/install-extensions.sh; \
    install -d -m 1777 /tmp; \
    install -d -m 0775 -o 1000 -g 1000 "$GEOSERVER_DATA_DIR"\
     "$GEOWEBCACHE_CACHE_DIR"\
     "$ADDITIONAL_LIBS_DIR"\
     "$HOME"\
     /usr/local/tomcat/{conf,logs,temp,work};

USER 1000:1000

ENTRYPOINT ["/opt/startup.sh"]