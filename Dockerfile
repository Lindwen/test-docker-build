FROM debian:bookworm-slim AS base

ARG PHP_VERSION=8.2

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        apt-transport-https \
        software-properties-common \
        lsb-release \
        curl \
        wget \
        gnupg \
        apache2 \
        apache2-utils \
        nano \
        git \
    && wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg \
    && echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list \
    && echo 'deb [trusted=yes] https://repo.symfony.com/apt/ /' | tee /etc/apt/sources.list.d/symfony-cli.list \
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        php${PHP_VERSION} \
        libapache2-mod-php${PHP_VERSION} \
        php${PHP_VERSION}-mbstring \
        php${PHP_VERSION}-xml \
        php${PHP_VERSION}-common \
        php${PHP_VERSION}-curl \
        php${PHP_VERSION}-mysql \
        php${PHP_VERSION}-intl \
        symfony-cli \
        nodejs \
        yarn \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

FROM base AS config

RUN a2enmod rewrite \
    && a2dismod info \
    && a2dismod status \
    && phpenmod intl \
    && echo "\
        <VirtualHost *:80>\n\
          ServerAdmin webmaster@localhost\n\
          ServerName localhost\n\
          DocumentRoot /var/www/html/public\n\
          <Directory /var/www/html/public>\n\
            AllowOverride all\n\
          </Directory>\n\
          ErrorLog \${APACHE_LOG_DIR}/error.log\n\
          CustomLog \${APACHE_LOG_DIR}/access.log combined\n\
        </VirtualHost>\n\
    " > /etc/apache2/sites-available/000-default.conf

FROM config AS final

EXPOSE 80

HEALTHCHECK CMD curl --fail http://localhost:80/ || exit 1

CMD ["apache2ctl", "-D", "FOREGROUND"]
