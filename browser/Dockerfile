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

# Fork of the original start-chromium.sh
COPY start-chromium.sh /usr/bin/start-browser-carousel
COPY start-browser-extra /usr/bin/start-browser-extra
COPY get-next-url /usr/bin/get-next-url

# Specific for the "tdx_br_photo" app
COPY tdx_br_photos.txt /etc/tdx_br_photo/tdx_br_photos.txt

ENTRYPOINT ["/usr/bin/start-browser-carousel"]
