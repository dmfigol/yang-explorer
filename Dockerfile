FROM python:2.7-alpine
LABEL maintainer="Dmitry Figol <git@dmfigol.me>"

RUN apk add --no-cache --virtual .build-deps \
        build-base \
        gcc \
        libffi-dev \
        openssl-dev \
    && apk add --no-cache git libxml2-dev libxslt-dev bash \
    && git clone https://github.com/CiscoDevNet/yang-explorer.git \
    && cd yang-explorer \
    && PIP_NO_CACHE_DIR=off bash setup.sh -y \
    && sed -i -e 's/HOST=\x27localhost\x27/HOST=$HOSTNAME/g' start.sh \
    && find /usr/local \
        \( -type d -a -name test -o -name tests \) \
        -o \( -type f -a -name '*.pyc' -o -name '*.pyo' \) \
        -exec rm -rf '{}' + \
    && runDeps="$( \
        scanelf --needed --nobanner --recursive /usr/local \
                | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
                | sort -u \
                | xargs -r apk info --installed \
                | sort -u \
    )" \
    && apk add --no-cache --virtual .rundeps $runDeps \
    && apk del .build-deps \
    && rm -rf /root/.cache

WORKDIR /yang-explorer
CMD ["bash", "start.sh"]