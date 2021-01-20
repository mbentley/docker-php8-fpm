mbentley/php7-fpm
=================

docker image for php7-fpm
based off of alpine:latest

To pull this image:
`docker pull mbentley/php7-fpm`

Example usage:
`docker run -i -t mbentley/php7-fpm`

## Environment Variables
The following environment variables can be passed to the docker image:

`MAX_SIZE` (default: 8) - Sets the 'post_max_size' and 'upload_max_filesize' options in php.ini; value is in MB

`MAX_CHILDREN` (default: 5) - Sets the 'max_children' option in www.conf

`MEMORY_LIMIT` (default: 128) - Sets the 'memory_limit' option in php.ini; value is in MB

`LISTEN` (default: socket; options: socket or port) - Changes php7-fpm listen behavior

## Working with nginx + php7-fpm

First start a PHP container:
`docker run -itd –restart=always -v /data/shared/run:/run -v /data/www:/data/www -v /data/shared/ssmtp:/etc/ssmtp --name php7-fpm mbentley/php7-fpm`

I use a volume to /data/shared/run on the host and then I also use a volume to /data/www on the host. /data/shared/run will get the UNIX socket as it is mapped to /run. I use /data/www so that php5-fpm has access to the files it needs to process requests.

Now for my nginx container:
`docker run -itd -p 80 –restart=always -v /data/shared/run:/run -v /data/www:/data/www -v /data/shared/nginx/my-custom-nginx-conf:/etc/nginx/sites-available/default --name my-site mbentley/nginx`

I need to present /data/shared/run as a volume so that nginx can read the UNIX socket (see my [php.conf](https://github.com/mbentley/docker-nginx/blob/master/php.conf) in [mbentley/nginx](https://github.com/mbentley/docker-php7-fpm) which adds all of the necessary bits for PHP by including a single file). I also add in my /data/www directory which shares my site's code for nginx.

Now you should be able to hit nginx and PHP pages will work. I'm using this method for a small number of sites and it's working great.
