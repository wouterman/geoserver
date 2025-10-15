# Geoserver docker image
Creates a docker image with GeoServer that runs as a non-root user (geoserveruser).

Adapted from https://gitlab.com/mathias.vanden.auweele/geoserver-openshift, however that version doesn't seem to work.
I removed things I don't need like SSL-support and community plugins. 

## Build
```shell
# See https://geoserver.org/ for latest versions.
docker build --build-arg version=2.27.2 --tag geoserver:1.0.0 .
```

## Run
```shell
docker run -p 8080:8080 geoserver:1.0.0
```