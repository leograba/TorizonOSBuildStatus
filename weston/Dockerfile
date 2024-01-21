ARG BASE_VERSION=3.2.2

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
FROM --platform=linux/${IMAGE_ARCH} torizon/weston:${BASE_VERSION}

COPY --chown=torizon:torizon splash.png /etc/xdg/weston/splash.png
COPY weston.ini /etc/xdg/weston/
