# InfluxDB container version
ARG INFLUXDB_VERSION=2.7.6
ARG ALPINE_VERSION=3.20.0
# Platform architecture
ARG IMAGE_ARCH=

# Get influx CLI ------------------------------------------------------
FROM --platform=linux/${IMAGE_ARCH} influxdb:${INFLUXDB_VERSION}-alpine AS influxCLI

FROM --platform=linux/${IMAGE_ARCH} alpine:${ALPINE_VERSION}

RUN apk add bash curl jq coreutils

ENV INFLUX_CONFIGS_PATH /etc/influxdb2/influx-configs

COPY --from=influxCLI /usr/local/bin/influx /usr/local/bin/
COPY get-build-status.sh /usr/local/bin/
COPY influx-configs $INFLUX_CONFIGS_PATH

# Command executed when starting the container
ENTRYPOINT [ "/usr/local/bin/get-build-status.sh" ]
