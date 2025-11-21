# mbentley/php8-fpm

docker image for php8-fpm
based off of alpine:edge (8.5),  alpine:latest (8.2 - 8.4), alpine:3.16 (8.0), alpine 3.19 (8.1)

To pull this image:
`docker pull mbentley/php8-fpm`

Example usage:
`docker run -i -t mbentley/php8-fpm`

## Tags

* `8.5` - php8.5
  * **Note**: php8.5 is currently missing `php85-opcache` and `php85-pecl-mcrypt` from the alpine repositories and is based on the `edge` release
* `latest`, `8.4` - php8.4
* `8.3` - php8.3
* `8.2` - php8.2
* `8.1` - php8.1

### Archived Tags

These no longer receive updates or regular rebuilds but the tag(s) may still be available on Docker Hub:

* `8.0` - php8.0

## Environment Variables

As of 6/25/2024, the way environment variables work has changed.  There are two different prefixes that are used to override settings: `PHP_INI_` and `PHP_FPM_`.  For each, create multiple environment variables with different suffixes (i.e. - `PHP_INI_1`, `PHP_INI_2`, etc) with the value being the setting you wish to set.

* `PHP_INI_*` - written to `/etc/${PHP_VER}/conf.d/99_entrypoint_var_customizations.ini`
* `PHP_FPM_*` - written to `/etc/${PHP_VER}/php-fpm.d/www.inc`

### Example

```ini
...
  -e PHP_INI_SETTING_01="memory_limit = 512M" \
  -e PHP_INI_SETTING_02="post_max_size = 256M" \
  -e PHP_INI_SETTING_03="upload_max_filesize = 256M" \
...
  -e PHP_FPM_SETTING_01="listen = /var/run/php/php-fpm83.sock" \
  -e PHP_FPM_SETTING_02="user = www-data" \
  -e PHP_FPM_SETTING_03="group = www-data" \
  -e PHP_FPM_SETTING_04="listen.owner = www-data" \
  -e PHP_FPM_SETTING_05="listen.group = www-data" \
  -e PHP_FPM_SETTING_06="listen.mode = 0660" \
  -e PHP_FPM_SETTING_07="pm.max_children = 10" \
...
```

## Working with nginx + php8-fpm

First start a PHP container:

`docker run -itd –restart=always -v /data/shared/run:/run -v /data/www:/data/www -v /data/shared/ssmtp:/etc/ssmtp --name php8-fpm mbentley/php8-fpm`

I use a volume to /data/shared/run on the host and then I also use a volume to /data/www on the host. /data/shared/run will get the UNIX socket as it is mapped to /run. I use /data/www so that php5-fpm has access to the files it needs to process requests.

Now for my nginx container:
`docker run -itd -p 80 –restart=always -v /data/shared/run:/run -v /data/www:/data/www -v /data/shared/nginx/my-custom-nginx-conf:/etc/nginx/sites-available/default --name my-site mbentley/nginx`

I need to present /data/shared/run as a volume so that nginx can read the UNIX socket (see my [php.conf](https://github.com/mbentley/docker-nginx/blob/master/php.conf) in [mbentley/nginx](https://github.com/mbentley/docker-php8-fpm) which adds all of the necessary bits for PHP by including a single file). I also add in my /data/www directory which shares my site's code for nginx.

Now you should be able to hit nginx and PHP pages will work. I'm using this method for a small number of sites and it's working great.
