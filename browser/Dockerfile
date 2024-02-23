ARG BASE_VERSION=3.1.0

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

USER root
RUN sed -i '1 a sleep 30' /usr/bin/start-browser
USER torizon
