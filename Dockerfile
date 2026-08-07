# Use the Nextcloud production image as the base
FROM nextcloud:production

# Install gosu (Debian/Ubuntu)
RUN apt-get update && apt-get install -y gosu && rm -rf /var/lib/apt/lists/*

# Update the package lists and install various dependencies
# These dependencies include tools and libraries required for Nextcloud and its features
RUN apt-get update \
 && apt-get install -y \
    cmake \
    ffmpeg \
    ghostscript \
    git \
    imagemagick \
    inotify-tools \
    liblapack-dev \
    libopenblas-dev \
    libx11-dev \
    sudo \
    nano \
    libmagickcore-7.q16-10-extra \
    exiftool \
    supervisor \
    curl \
    wget \
    gnupg2 \
    unzip \
 && apt-get clean

# Enable Apache modules for reverse proxy
RUN a2enmod proxy proxy_http proxy_wstunnel headers rewrite

RUN pecl install inotify && \
    echo "extension=inotify.so" | tee /usr/local/etc/php/conf.d/docker-php-ext-inotify.ini

# Clone and build dlib, a toolkit for making real world machine learning and data analysis applications
RUN git clone https://github.com/davisking/dlib.git \
 && cd dlib/dlib \
 && mkdir build \
 && cd build \
 && cmake -DBUILD_SHARED_LIBS=ON .. \
 && make \
 && make install

# Clone and install pdlib, a PHP extension for dlib
RUN git clone https://github.com/goodspb/pdlib.git /usr/src/php/ext/pdlib

# Install the pdlib PHP extension
RUN docker-php-ext-install pdlib

# Full paths required: busybox crond runs with a minimal PATH (no /usr/local/bin, no /usr/bin)
RUN mkdir -p /var/spool/cron/crontabs \
 && echo '*/5 * * * * /usr/bin/flock -n /tmp/nextcloud-cron.lock /usr/local/bin/php -f /var/www/html/cron.php' > /var/spool/cron/crontabs/www-data \
 && echo '15 2 * * * /usr/bin/flock -n /tmp/nextcloud-memories.lock /usr/local/bin/conditional-cron.sh memories' >> /var/spool/cron/crontabs/www-data \
 && echo '30 2 * * * /usr/bin/flock -n /tmp/nextcloud-face.lock /usr/local/bin/conditional-cron.sh face' >> /var/spool/cron/crontabs/www-data \
 && echo '45 2 * * * /usr/bin/flock -n /tmp/nextcloud-recognize.lock /usr/local/bin/conditional-cron.sh recognize' >> /var/spool/cron/crontabs/www-data \
 && echo '0 3 * * * /usr/bin/flock -n /tmp/nextcloud-preview.lock /usr/local/bin/conditional-cron.sh preview' >> /var/spool/cron/crontabs/www-data \
 && echo '30 3 * * * /usr/bin/flock -n /tmp/nextcloud-previewgen.lock /usr/local/bin/conditional-cron.sh previewgenerator' >> /var/spool/cron/crontabs/www-data \
 && chown www-data:www-data /var/spool/cron/crontabs/www-data \
 && chmod 600 /var/spool/cron/crontabs/www-data

# zz- prefix ensures this loads last and wins over any base image memory_limit
RUN echo memory_limit=1024M > /usr/local/etc/php/conf.d/zz-memory-limit.ini \
 && sed -i 's/memory_limit=.*/memory_limit=1024M/' /usr/local/etc/php/conf.d/nextcloud.ini || true

# Enable proc_open function (required by Memories app and other Nextcloud apps)
RUN echo 'disable_functions =' > /usr/local/etc/php/conf.d/enable-functions.ini

RUN echo 'apc.enable_cli=1' >> "${PHP_INI_DIR}/conf.d/docker-php-ext-apcu.ini"

# Increase opcache memory
RUN sed -i 's/opcache.memory_consumption=128/opcache.memory_consumption=512/g' /usr/local/etc/php/conf.d/opcache-recommended.ini

# Validate pdlib is available without running external image-processing tests
RUN php -r 'exit(extension_loaded("pdlib") ? 0 : 1);'

# Install PHP extensions and configure them
RUN set -ex; \
    \
    savedAptMark="$(apt-mark showmanual)"; \
    \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        libbz2-dev \
        libsmbclient-dev \
    ; \
    \
    docker-php-ext-install \
        bz2 \
    ; \
    pecl install smbclient; \
    docker-php-ext-enable smbclient; \
    \
    apt-mark auto '.*' > /dev/null; \
    apt-mark manual $savedAptMark; \
    ldd "$(php -r 'echo ini_get("extension_dir");')"/*.so \
        | awk '/=>/ { so = $(NF-1); if (index(so, "/usr/local/") == 1) { next }; gsub("^/(usr/)?", "", so); print so }' \
        | sort -u \
        | xargs -r dpkg-query --search \
        | cut -d: -f1 \
        | sort -u \
        | xargs -rt apt-mark manual; \
    \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
    rm -rf /var/lib/apt/lists/*

# Install notify_push binary
RUN NOTIFY_PUSH_VERSION=$(curl -s https://api.github.com/repos/nextcloud/notify_push/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")') \
 && wget -O /usr/local/bin/notify_push "https://github.com/nextcloud/notify_push/releases/download/${NOTIFY_PUSH_VERSION}/notify_push-x86_64-unknown-linux-musl" \
 && chmod +x /usr/local/bin/notify_push

# Copy supervisord configuration
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Copy nginx configuration (for reference/optional standalone nginx)
COPY nginx.conf /etc/nginx/nginx.conf

# Copy auto-install-apps script
COPY auto-install-apps.sh /usr/local/bin/auto-install-apps.sh

# Copy and adjust permissions for cron and setup scripts
COPY conditional-cron.sh /usr/local/bin/conditional-cron.sh
COPY cron.sh /
COPY setup-notify-push.sh /
COPY docker-entrypoint.sh /
COPY init-notify-push.sh /
RUN chmod +x /cron.sh /setup-notify-push.sh /docker-entrypoint.sh /init-notify-push.sh /usr/local/bin/auto-install-apps.sh /usr/local/bin/conditional-cron.sh \
    && sed -i 's/\r$//' /cron.sh /setup-notify-push.sh /docker-entrypoint.sh /init-notify-push.sh /usr/local/bin/auto-install-apps.sh /usr/local/bin/conditional-cron.sh

# Create directory for supervisor logs
RUN mkdir -p /var/log/supervisor

# Set an environment variable to indicate that Nextcloud should be updated
ENV NEXTCLOUD_UPDATE=1

# Expose notify_push port
EXPOSE 7867

# Health check to ensure Nextcloud is running and accessible
HEALTHCHECK --interval=1m --timeout=10s --start-period=30s --retries=3 \
  CMD curl -f http://localhost/status.php || exit 1

# Use custom entrypoint that sets up notify_push
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
