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
    libbz2-dev \
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

# Install the bz2 PHP extension
RUN docker-php-ext-install bz2

# General background stuff – OK every 5 min
RUN echo '*/5 * * * * flock -n /tmp/nextcloud-cron.lock php -f /var/www/html/cron.php' >> /var/spool/cron/crontabs/www-data
RUN echo '*/10 * * * * flock -n /tmp/nextcloud-general.lock /usr/local/bin/conditional-cron.sh general' >> /var/spool/cron/crontabs/www-data

# Heavy stuff – once nightly or off-peak
RUN echo '15 2 * * * flock -n /tmp/nextcloud-memories.lock /usr/local/bin/conditional-cron.sh memories' >> /var/spool/cron/crontabs/www-data
RUN echo '30 2 * * * flock -n /tmp/nextcloud-face.lock /usr/local/bin/conditional-cron.sh face' >> /var/spool/cron/crontabs/www-data
RUN echo '45 2 * * * flock -n /tmp/nextcloud-recognize.lock /usr/local/bin/conditional-cron.sh recognize' >> /var/spool/cron/crontabs/www-data
RUN echo '0 3 * * * flock -n /tmp/nextcloud-preview.lock /usr/local/bin/conditional-cron.sh preview' >> /var/spool/cron/crontabs/www-data
RUN echo '30 3 * * * flock -n /tmp/nextcloud-previewgen.lock /usr/local/bin/conditional-cron.sh previewgenerator' >> /var/spool/cron/crontabs/www-data

# Install dlib development headers from Debian repositories
RUN apt-get update \
  && apt-get install -y libdlib-dev \
  && rm -rf /var/lib/apt/lists/*

# Install pdlib extension from a downloaded archive
RUN wget https://github.com/goodspb/pdlib/archive/master.zip \
  && mkdir -p /usr/src/php/ext/ \
  && unzip -d /usr/src/php/ext/ master.zip \
  && rm master.zip
RUN docker-php-ext-install pdlib-master

# Increase PHP memory limit for Nextcloud
RUN echo memory_limit=1024M > /usr/local/etc/php/conf.d/memory-limit.ini

# Enable proc_open function (required by Memories app and other Nextcloud apps)
RUN echo 'disable_functions =' > /usr/local/etc/php/conf.d/enable-functions.ini

RUN echo 'apc.enable_cli=1' >> "${PHP_INI_DIR}/conf.d/docker-php-ext-apcu.ini"

# Increase opcache memory
RUN sed -i 's/opcache.memory_consumption=128/opcache.memory_consumption=512/g' /usr/local/etc/php/conf.d/opcache-recommended.ini

# Download and test the pdlib extension
RUN wget https://github.com/matiasdelellis/pdlib-min-test-suite/archive/master.zip \
  && unzip -d /tmp/ master.zip \
  && rm master.zip
RUN cd /tmp/pdlib-min-test-suite-master \
    && make

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
