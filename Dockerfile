# rebased/repackaged base image that only updates existing packages
FROM mbentley/alpine:latest
LABEL maintainer="Matt Bentley <mbentley@mbentley.net>"

# install typical php packages and then additional packages
RUN apk add --no-cache bind-tools imagemagick php8 php8-bcmath php8-bz2 php8-ctype php8-curl php8-exif php8-fileinfo php8-gd php8-fpm php8-gettext php8-gmp php8-iconv php8-intl php8-imap php8-json php8-ldap php8-mbstring php8-mysqli php8-pecl-apcu php8-pecl-igbinary php8-pecl-imagick php8-pecl-mcrypt php8-pecl-memcached php8-pecl-redis php8-pdo php8-pdo_mysql php8-opcache php8-pdo_pgsql php8-pgsql php8-pcntl php8-posix php8-simplexml php8-xml php8-xmlreader php8-xmlwriter php8-zip ssmtp wget whois &&\
  sed -i "s#listen = 127.0.0.1:9000#listen = /var/run/php/php-fpm8.sock#g" /etc/php8/php-fpm.d/www.conf &&\
  sed -i "s#^user = nobody#user = www-data#g" /etc/php8/php-fpm.d/www.conf &&\
  sed -i "s#^group = nobody#group = www-data#g" /etc/php8/php-fpm.d/www.conf &&\
  sed -i "s#^;listen.owner = nobody#listen.owner = www-data#g" /etc/php8/php-fpm.d/www.conf &&\
  sed -i "s#^;listen.group = nobody#listen.group = www-data#g" /etc/php8/php-fpm.d/www.conf &&\
  sed -i "s#^;listen.mode = 0660#listen.mode = 0660#g" /etc/php8/php-fpm.d/www.conf &&\
  sed -i "s#^;env#env#g" /etc/php8/php-fpm.d/www.conf &&\
  sed -i "s#upload_max_filesize = 2M#upload_max_filesize = 8M#g" /etc/php8/php.ini &&\
  sed -i "s#^;opcache.enable=1#opcache.enable=1#g" /etc/php8/php.ini &&\
  sed -i "s#^;opcache.interned_strings_buffer=8#opcache.interned_strings_buffer=8#g" /etc/php8/php.ini &&\
  sed -i "s#^;opcache.max_accelerated_files=10000#opcache.max_accelerated_files=10000#g" /etc/php8/php.ini &&\
  sed -i "s#^;opcache.memory_consumption=128#opcache.memory_consumption=128#g" /etc/php8/php.ini &&\
  sed -i "s#^;opcache.save_comments=1#opcache.save_comments=1#g" /etc/php8/php.ini &&\
  sed -i "s#^;opcache.revalidate_freq=2#opcache.revalidate_freq=1#g" /etc/php8/php.ini &&\
  deluser $(grep ':33:' /etc/passwd | awk -F ':' '{print $1}') || true &&\
  delgroup $(grep '^www-data:' /etc/group | awk -F ':' '{print $1}') || true &&\
  mkdir /var/www &&\
  addgroup -g 33 www-data &&\
  adduser -D -u 33 -G www-data -s /sbin/nologin -H -h /var/www www-data &&\
  chown -R www-data:www-data /var/www

# add entrypoint script
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/sbin/php-fpm8","-F","--fpm-config","/etc/php8/php-fpm.conf"]
