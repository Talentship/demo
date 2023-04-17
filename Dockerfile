FROM php:8.1-apache
#Install git
RUN apt-get update && apt-get install -y yarn
RUN apt-get update && apt-get install -y \
    build-essential \
    libssl-dev \
    libcurl4-openssl-dev \
    libxml2-dev \
    && rm -rf /var/lib/apt/lists/*
RUN apt-get update && apt-get install -y libtool
#RUN rm /usr/lib/x86_64-linux-gnu/libltdl.la
RUN apt-get update \
    && apt-get install -y git
RUN apt-get install -y gnupg2 gnupg1
RUN cd /usr/local/etc/php/conf.d/ && \
  echo 'memory_limit = -1' >> /usr/local/etc/php/conf.d/docker-php-ram-limit.ini
# adding custom MS repository
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
RUN curl https://packages.microsoft.com/config/debian/11/prod.list > /etc/apt/sources.list.d/mssql-release.list

# install SQL Server drivers
RUN apt-get update
RUN ACCEPT_EULA=Y apt-get install -y msodbcsql18 unixodbc-dev

# install SQL Server tools
RUN ACCEPT_EULA=Y apt-get install -y mssql-tools18
RUN echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc
RUN /bin/bash -c "source ~/.bashrc"

# install necessary locales
RUN apt-get update && apt-get install -y locales \
    && echo "en_US.UTF-8 UTF-8" > /etc/locale.gen \
    && locale-gen

#RUN pecl install sqlsrv pdo_sqlsrv
# COPY config/php.ini-development /usr/local/etc/php/php.ini-development
#RUN docker-php-ext-enable sqlsrv pdo_sqlsrv
# RUN a2enmod rewrite
#Install Composer
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
RUN php composer-setup.php --install-dir=. --filename=composer
RUN # Install php extensions
RUN apt-get update \
    && apt-get install -y \
        # Required for downloading Suhosin
        wget \
        # Required for crons (which are needed for logrotate)
        cron \
        # Required for php's bz2 module
        libbz2-dev \
        # Required for php's gd module
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        # Required for php's mcrypt module
        libmcrypt-dev \
        mcrypt \
        # Required for php's intl module
        libicu-dev \
        # Required for php's SOAP module, potentially not needed as may be already installed
        libxml2-dev \
        # Required for php's xsl module
        libxslt1-dev \
        # Required for php's zip module
        libzip-dev \
        # git & unzip needed for composer
        # unzip needed due to https://github.com/composer/composer/issues/4471
        git \
        unzip \
    && docker-php-ext-enable opcache \
    && docker-php-ext-install -j$(nproc) \
        bcmath \
        bz2 \
        calendar \
        # Exif is potentially no longer needed.
        exif \
        gd \
        gettext \
        intl \
        mysqli \
        pcntl \
        pdo_mysql \
        # soap is potentially no longer needed.
        soap \
        sockets \
        xsl \
        zip
RUN mv composer /usr/local/bin/
# RUN yarn encore dev
COPY / /var/www/html/
#RUN a2enmod rewrite && a2enmod ssl && a2enmod socache_shmcb
#RUN sed -i '/SSLCertificateFile.*snakeoil\.pem/c\SSLCertificateFile \/etc\/ssl\/certs\/mycert.crt' /etc/apache2/sites-available/default-ssl.conf && sed -i '/SSLCertificateKeyFile.*snakeoil\.key/cSSLCertificateKeyFile /etc/ssl/private/mycert.key\' /etc/apache2/sites-available/default-ssl.conf
#RUN a2ensite default-ssl
RUN chmod o+x /var/www/html/
RUN cd /var/www/html/
RUN rm -rf /var/www/html/var/cache/dev
RUN composer install
#COPY /config/php.ini-development /etc/php/apache2/php.ini-development
RUN curl -sL https://deb.nodesource.com/setup_16.x  | bash -
RUN apt-get -y install nodejs
# installing symfony CLI
RUN curl https://get.symfony.com/cli/installer | bash
RUN mv /root/.symfony5/bin/symfony /usr/local/bin/symfony
# install node sass
# RUN npm install -y npm@8.19.2
RUN npm install -y node-sass@6.0.1 --force
# install dependencies
RUN npm install --legacy-peer-deps
EXPOSE 80 443 8000
CMD ["symfony", "serve"]
