# mbentley/php8-fpm

docker image for php8-fpm
based off of alpine:latest or alpine:3.16

To pull this image:
`docker pull mbentley/php8-fpm`

Example usage:
`docker run -i -t mbentley/php8-fpm`

## Tags

* `latest`, `8.3` - php8.3
* `8.2` - php8.2
* `8.1` - php8.1

### Archived Tags

These no longer receive updates or regular rebuilds but the tag(s) may still be available on Docker Hub:

* `8.0` - php8.0

## Environment Variables

The following environment variables can be passed to the docker image:

`MAX_SIZE` (default: 8) - Sets the 'post_max_size' and 'upload_max_filesize' options in php.ini; value is in MB

`MAX_CHILDREN` (default: 5) - Sets the 'max_children' option in www.conf

`MEMORY_LIMIT` (default: 128) - Sets the 'memory_limit' option in php.ini; value is in MB

`LISTEN` (default: socket; options: socket or port) - Changes php8-fpm listen behavior

## Working with nginx + php8-fpm

First start a PHP container:

`docker run -itd –restart=always -v /data/shared/run:/run -v /data/www:/data/www -v /data/shared/ssmtp:/etc/ssmtp --name php8-fpm mbentley/php8-fpm`

I use a volume to /data/shared/run on the host and then I also use a volume to /data/www on the host. /data/shared/run will get the UNIX socket as it is mapped to /run. I use /data/www so that php5-fpm has access to the files it needs to process requests.

Now for my nginx container:
`docker run -itd -p 80 –restart=always -v /data/shared/run:/run -v /data/www:/data/www -v /data/shared/nginx/my-custom-nginx-conf:/etc/nginx/sites-available/default --name my-site mbentley/nginx`

I need to present /data/shared/run as a volume so that nginx can read the UNIX socket (see my [php.conf](https://github.com/mbentley/docker-nginx/blob/master/php.conf) in [mbentley/nginx](https://github.com/mbentley/docker-php8-fpm) which adds all of the necessary bits for PHP by including a single file). I also add in my /data/www directory which shares my site's code for nginx.

Now you should be able to hit nginx and PHP pages will work. I'm using this method for a small number of sites and it's working great.
