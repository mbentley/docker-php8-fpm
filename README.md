# mbentley/php8-fpm

docker image for php8-fpm
based off of alpine:latest (8.2 - 8.5), alpine:3.16 (8.0), alpine 3.19 (8.1)

To pull this image:
`docker pull mbentley/php8-fpm`

Example usage:
`docker run -i -t mbentley/php8-fpm`

## Tags

* `latest` - `8.5` - php8.5
* `8.4` - php8.4
* `8.3` - php8.3
* `8.2` - php8.2

### Archived Tags

These no longer receive updates or regular rebuilds but the tag(s) may still be available on Docker Hub:

* `8.1` - php8.1
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

## Utilities

Helper scripts live in the `utils` directory and can be run from any directory.

### Supported Versions Check

`utils/check_supported_versions.sh` compares the PHP versions currently supported upstream (from php.net) against the versions this repo expects to build, and exits non-zero if they differ. Requires `curl` and `jq`.

```bash
./utils/check_supported_versions.sh
```

### Nextcloud PHP Module Check

`utils/check_nextcloud_modules.sh` builds the images from the local Dockerfiles and verifies that the PHP modules loaded in each one meet the requirements in Nextcloud's [PHP Module Quick Reference Table](https://docs.nextcloud.com/server/latest/admin_manual/installation/php_configuration.html), which is stored in `utils/requirements_table.rst`. Requires `bash` and Docker.

```bash
./utils/check_nextcloud_modules.sh                  # build and check the supported versions (8.2 - 8.5)
./utils/check_nextcloud_modules.sh 8.4 8.5          # build and check specific versions
./utils/check_nextcloud_modules.sh --pull 8.5       # check the published image from Docker Hub instead of building
```

Each version gets a table showing every module from the requirements table as `ok` or `MISSING`. The script exits non-zero if any version is missing a module that Nextcloud lists as required; missing recommended or app-specific modules are reported but do not fail the check. Images are built with a `-modtest` tag suffix (i.e. - `mbentley/php8-fpm:8.5-modtest`) so they do not overwrite the real tags.

#### Updating the Requirements Table

`utils/requirements_table.rst` is the "PHP Module Quick Reference Table" section copied from Nextcloud's [`php_configuration.rst`](https://raw.githubusercontent.com/nextcloud/documentation/refs/heads/master/admin_manual/installation/php_configuration.rst). To refresh it:

```bash
./utils/update_requirements_table.sh
```

`utils/update_requirements_table.sh` downloads the source file, extracts the section, and shows a diff if anything changed. It checks that the table header still has the expected columns (`Module`, `Required`, `Recommended`, `For Specific App`, `Description`) and exits with an error without touching `utils/requirements_table.rst` if the format has changed.

If the automatic update fails, update the file manually: open the source link above, copy everything from the `PHP Module Quick Reference Table` heading through the footnote below the table, and paste it into `utils/requirements_table.rst`. The check script reads the module name and the `Required`/`Recommended`/`For Specific App` columns by position, so if Nextcloud changes the columns, `check_nextcloud_modules.sh` will need updating too.
