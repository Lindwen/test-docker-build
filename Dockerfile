FROM debian:12-slim AS base

ARG PHP_VERSION=8.2

ENV DEBIAN_FRONTEND noninteractive

RUN apt update -yq \
&& apt -y upgrade \
&& DEBIAN_FRONTEND=noninteractive \
&& apt -y install ca-certificates apt-transport-https software-properties-common lsb-release curl wget gnupg \
&& wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg \
&& sh -c 'echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list' \
&& echo 'deb [trusted=yes] https://repo.symfony.com/apt/ /' | tee /etc/apt/sources.list.d/symfony-cli.list \
&& mkdir -p /etc/apt/keyrings \
&& curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
&& echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list \
&& apt -y update \
&& apt -y install php${PHP_VERSION} libapache2-mod-php${PHP_VERSION} php${PHP_VERSION}-mbstring php${PHP_VERSION}-xml php${PHP_VERSION}-common php${PHP_VERSION}-curl php${PHP_VERSION}-mysql php${PHP_VERSION}-intl apache2 apache2-utils nano git nodejs symfony-cli yarn \
&& apt -y update \
&& apt -y upgrade \
&& php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
&& php -r "if (hash_file('sha384', 'composer-setup.php') === 'e21205b207c3ff031906575712edab6f13eb0b361f2085f1f1237b7126d785e826a450292b6cfd1d64d92e6563bbde02') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" \
&& php composer-setup.php \
&& php -r "unlink('composer-setup.php');" \
&& mv composer.phar /usr/local/bin/composer \
&& apt -y clean \
&& apt -y autoremove

FROM base AS config

RUN apache2ctl start \
&& a2enmod rewrite \
&& a2dismod info \
&& a2dismod status \
&& phpenmod intl \
&& cat <<EOT > /etc/apache2/sites-available/000-default.conf
<VirtualHost *:80>
  ServerAdmin webmaster@localhost
  ServerName 127.0.0.1
  DocumentRoot /var/www/html/public
  <Directory /var/www/html/public>
    AllowOverride all
  </Directory>
ErrorLog ${APACHE_LOG_DIR}/error.log
CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOT

FROM config AS final

EXPOSE 80

HEALTHCHECK CMD curl --fail http://localhost:80/ || exit 1

CMD ["apache2ctl", "-D", "FOREGROUND"]
