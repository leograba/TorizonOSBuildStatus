ARG BASE_VERSION=3.0.2

##
# Board architecture
# arm or arm64
##
ARG IMAGE_ARCH=

##
# Board GPU vendor prefix
##
ARG GPU=

# DEPLOY ------------------------------------------------------------------------
FROM --platform=linux/${IMAGE_ARCH} torizon/chromium:${BASE_VERSION}

ARG IMAGE_ARCH
ARG GPU

# Command executed when starting the container
CMD [ "http://grafana:3000/d/tor-jenkins-status/tor-jenkins-status?orgId=1&refresh=15m&kiosk" ]
