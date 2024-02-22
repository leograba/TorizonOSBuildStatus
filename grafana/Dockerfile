ARG GRAFANA_VERSION=10.1.6

##
# Board architecture
# arm or arm64
##
ARG IMAGE_ARCH=

# DEPLOY ------------------------------------------------------------------------
FROM --platform=linux/${IMAGE_ARCH} grafana/grafana:${GRAFANA_VERSION}

# Cofigure for the current project
COPY grafana-config/grafana.ini /etc/grafana/grafana.ini
COPY grafana-config/datasource.yaml /etc/grafana/provisioning/datasources/datasource.yaml
COPY grafana-config/dashboard.yaml /etc/grafana/provisioning/dashboards/dashboard.yaml
COPY grafana-config/dashboard.json /etc/grafana/provisioning/dashboards/dashboard.json
