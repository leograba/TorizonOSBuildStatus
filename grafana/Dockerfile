ARG GRAFANA_VERSION=10.4.3

##
# Board architecture
# arm or arm64
##
ARG IMAGE_ARCH=

# DEPLOY ------------------------------------------------------------------------
FROM --platform=linux/${IMAGE_ARCH} grafana/grafana:${GRAFANA_VERSION}

# Cofigure for the current project
COPY grafana-config /etc/grafana
