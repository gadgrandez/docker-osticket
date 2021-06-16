FROM php:7.4-fpm-alpine

VOLUME /var/lib/osticket

RUN set -ex; \
    \
    export CFLAGS="-Os"; \
    export CPPFLAGS="${CFLAGS}"; \
    export LDFLAGS="-Wl,--strip-all"; \
    \
    # Runtime dependencies
    apk add --no-cache \
        c-client \
        icu \
        libintl \
        libpng \
        libzip \
        msmtp \
        nginx \
        openldap \
        runit \
    ; \
    \
    # Build dependencies
    apk add --no-cache --virtual .build-deps \
        ${PHPIZE_DEPS} \
        gettext-dev \
        icu-dev \
        imap-dev \
        libpng-dev \
        libzip-dev \
        openldap-dev \
    ; \
    \
    # Install PHP extensions
    docker-php-ext-configure imap --with-imap-ssl; \
    docker-php-ext-install -j "$(nproc)" \
        gd \
        gettext \
        imap \
        intl \
        ldap \
        mysqli \
        sockets \
        zip \
    ; \
    pecl install apcu; \
    docker-php-ext-enable \
        apcu \
        opcache \
    ; \
    \
    # Create msmtp log
    touch /var/log/msmtp.log; \
    chown www-data:www-data /var/log/msmtp.log; \
    \
    # Create data dir
    #mkdir /var/lib/osticket; \
    #\
    # Clean up
    apk del .build-deps; \
    rm -rf /tmp/pear /var/cache/apk/*
    
VOLUME /var/www/

# DO NOT FORGET TO UPDATE "tags" FILE
ENV OSTICKET_VERSION=1.15.2 \
    OSTICKET_SHA256SUM=83c435956f3975eefcc001152ce848bf00f26cdc97305e312b7653d6f843a252
RUN set -ex; \
    \
    wget -q -O osTicket.zip https://github.com/osTicket/osTicket/releases/download/\
v${OSTICKET_VERSION}/osTicket-v${OSTICKET_VERSION}.zip; \
    echo "${OSTICKET_SHA256SUM}  osTicket.zip" | sha256sum -c; \
    unzip osTicket.zip 'upload/*'; \
    rm osTicket.zip; \
    #mkdir /usr/local/src; \
    #mv upload /usr/local/src/osticket; \
    # Hard link the sources to the public directory
    #cp -al /usr/local/src/osticket/. /var/www/html; \
    # Hide setup
    #rm -r /var/www/html/setup; \
    #\
    for lang in ar az bg ca cs da de el es_ES et fr hr hu it ja ko lt mk mn nl no fa pl pt_PT \
        pt_BR sk sl sr_CS fi sv_SE ro ru vi th tr uk zh_CN zh_TW; do \
        wget -q -O upload/include/i18n/${lang}.phar \
            https://s3.amazonaws.com/downloads.osticket.com/lang/${lang}.phar; \
    done
    mv upload /var/www/html; \
COPY root /
CMD ["start"]
STOPSIGNAL SIGTERM
EXPOSE 80
HEALTHCHECK CMD curl -fIsS http://localhost/ || exit 1
