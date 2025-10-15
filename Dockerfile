FROM tomcat:9.0.109-jdk17-temurin-noble

ARG version=2.27.2
ARG GS_BUILD=release
ARG WAR_ZIP_URL=https://downloads.sourceforge.net/project/geoserver/GeoServer/${version}/geoserver-${version}-war.zip
ARG STABLE_PLUGIN_URL=https://downloads.sourceforge.net/project/geoserver/GeoServer/${version}/extensions
ENV GEOSERVER_VERSION=$version
ENV CATALINA_HOME=$CATALINA_HOME

# specify volume mount points
ENV GEOSERVER_DATA_DIR=/mnt/geoserver_data_dir
ENV GEOWEBCACHE_CACHE_DIR=/mnt/geoserver_caching

# specify extensions to install and location
ENV GEOSERVER_LIB_DIR=$CATALINA_HOME/webapps/geoserver/WEB-INF/lib/
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
    # Upgrade system and install necessary packages. \
    export DEBIAN_FRONTEND=noninteractive; \
    apt update -y; \
    apt upgrade -y; \
    apt install -y --no-install-recommends \
     curl gettext gosu locales openssl unzip zip; \
    rm -rf /var/lib/apt/lists/*; \
    # Download and unpack geoserver, \
    echo "Downloading GeoServer ${version} ${GS_BUILD}"; \
    wget -O /tmp/geoserver.zip "$WAR_ZIP_URL"; \
    unzip /tmp/geoserver.zip geoserver.war -d /tmp/; \
    unzip -q /tmp/geoserver.war -d /tmp/geoserver; \
    rm /tmp/geoserver.war; \
    rm /tmp/geoserver.zip; \
    echo "Installing GeoServer $version"; \
    mv /tmp/geoserver "$CATALINA_HOME"/webapps/geoserver; \
    mv "$CATALINA_HOME"/webapps/geoserver/WEB-INF/lib/marlin-*.jar "$CATALINA_HOME"/lib/marlin.jar; \
    mv "$CATALINA_HOME"/webapps/geoserver/WEB-INF/lib/postgresql-*.jar "$CATALINA_HOME"/lib/; \
    # Install extensions \
    /opt/install-extensions.sh; \
    rm -f /opt/install-extensions.sh; \
    # Fix permissions and create necessary directories. \
    install -d -m 1777 /tmp; \
    install -d -m 0775 -o 1000 -g 1000 "$GEOSERVER_DATA_DIR"\
     "$GEOWEBCACHE_CACHE_DIR"\
     "$ADDITIONAL_LIBS_DIR"\
     "$HOME"\
     /usr/local/tomcat/{conf,logs,temp,work};

USER 1000:1000

ENTRYPOINT ["/opt/startup.sh"]