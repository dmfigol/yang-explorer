FROM python:2.7-alpine
LABEL maintainer="Dmitry Figol <git@dmfigol.me>"

RUN apk add --no-cache --virtual .build-deps \
        build-base \
        gcc \
        libffi-dev \
        openssl-dev \
        wget \
        libxml2-dev \
        libxslt-dev \
    && apk add --no-cache git bash \
    && PIP_NO_CACHE_DIR=off pip install "git+https://github.com/CiscoDevNet/ydk-py.git@yam#egg=ydk&subdirectory=core" \
    && wget -qO- https://github.com/CiscoDevNet/yang-explorer/archive/master.tar.gz | tar xz \
    && mv yang-explorer-master yang-explorer \
    && cd yang-explorer \
    && sed -i '/^cd \.\.\/; \\/,/^echo/ d' setup.sh \
    && PIP_NO_CACHE_DIR=off bash setup.sh -y \
    && sed -i -e 's/HOST=\x27localhost\x27/HOST=$HOSTNAME/g' start.sh \
    && find /usr/local /yang-explorer \
        \( -type d -a -name test -o -name tests \) \
        -o \( -type f -a -name '*.pyc' -o -name '*.pyo' \) \
        -exec rm -rf '{}' + \
    && runDeps="$( \
        scanelf --needed --nobanner --recursive /usr/local /yang-explorer \
                | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
                | sort -u \
                | xargs -r apk info --installed \
                | sort -u \
    )" \
    && apk add --no-cache --virtual .rundeps $runDeps \
    && apk del .build-deps \
    && rm -rf /root/.cache /src/ydk/.git /src/ydk/cisco-ios-xr /src/ydk/cisco-ios-xe

WORKDIR /yang-explorer
CMD ["bash", "start.sh"]