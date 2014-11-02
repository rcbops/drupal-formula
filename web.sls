{% from "drupal/db.jinja" import drupal with context %}
{% set drupal_memcache_version = "7.x-1.2" %}

# Installed required software
drupal-software:
  pkg.installed:
    - pkgs:
      - gcc
      - apache2
      - php5
      - php5-mysql
      - php5-gd
      - php-apc
      - memcached
      - libmemcached-tools
      - php5-dev
      - php-pear
      - make

pecl_memcache:
  pecl.installed:
    - name: memcache

# Remove default index.html
/var/www/index.html:
  file.absent:
    - name: /var/www/index.html

/var/www:
  file.directory:
    - user: www-data
    - group: www-data
    - mode: 755
    - recurse:
      - user
      - group
      - mode

/etc/apache2/sites-enabled/000-default:
  file.absent:
    - require:
      - pkg: drupal-software

/etc/apache2/sites-enabled/drupal:
  file.managed:
    - source: salt://drupal/files/apache2/vhost
    - require:
      - pkg: drupal-software

# Only move, and extract drupal files if settings does not exist.
{% if 1 == salt['cmd.retcode']('test -f /var/www/sites/default/settings.php') %}

# Get the drupal tarball
/tmp/drupal-{{ drupal.version }}.tar.gz:
  file.managed:
    - source: {{ drupal.source }}
    - source_hash: md5={{ drupal.md5 }}

unzip_drupal:
  cmd.run:
    - name: tar -zxf drupal-{{ drupal.version }}.tar.gz
    - cwd: /tmp
    - require:
      - file: /tmp/drupal-{{ drupal.version }}.tar.gz
move_drupal_files:
  cmd.run:
    - name: mv drupal-{{ drupal.version }}/* drupal-{{ drupal.version }}/.htaccess drupal-{{ drupal.version }}/.gitignore /var/www/
    - cwd: /tmp
    - require:
      - cmd: unzip_drupal

# Get the drupal memcache module tarball
/tmp/memcache-{{ drupal_memcache_version }}.tar.gz:
  file.managed:
    - source: salt://drupal/files/drupal/plugins/memcache-{{ drupal_memcache_version }}.tar.gz
unzip_drupal_memcache:
  cmd.run:
    - name: tar -zxf memcache-{{ drupal_memcache_version }}.tar.gz
    - cwd: /tmp
    - require:
      - file: /tmp/memcache-{{ drupal_memcache_version }}.tar.gz
move_drupal_memcache_files:
  cmd.run:
    - name: mv memcache /var/www/sites/all/modules/
    - cwd: /tmp
    - require:
      - cmd: unzip_drupal_memcache

# Clean up .tar.gz and remaining directories
drupal_cleanup:
  cmd.run:
    - name: rm -rf drupal* memcache*
    - cwd: /tmp
    - require:
      - cmd: move_drupal_files
      - cmd: move_drupal_memcache_files

# Recurse and set permissions.
permissions:
  file.directory:
    - name: /var/www/
    - user: www-data
    - group: www-data
    - mode: 755
    - recurse:
      - user
      - group
      - mode
    - require:
      - cmd: move_drupal_files
      - cmd: move_drupal_memcache_files
{% endif %}

/var/www/sites/default/settings.php:
  file.managed:
    - name: /var/www/sites/default/settings.php
    - source: salt://drupal/files/drupal/settings.php
    - template: jinja
    - user: www-data
    - group: www-data
    - mode: 755
    - replace: False

/var/www/status.php:
  file.managed:
    - source: salt://drupal/files/drupal/status.php

php_memcache_ini:
  file.managed:
    - name: /etc/php5/conf.d/memcache.ini
    - source: salt://drupal/files/php/php-memcache.ini

/etc/php5/apache2/php.ini:
  file.managed:
    - source: salt://drupal/files/php/php.ini

memcached_conf:
  file.managed:
    - name: /etc/memcached.conf
    - source: salt://drupal/files/memcached/memcached.conf
    - template: jinja

apache-service:
  service:
    - name: apache2
    - running
    - watch:
      - file: php_memcache_ini
      - pecl: pecl_memcache
      - file: /etc/apache2/sites-enabled/drupal
      - file: /etc/php5/apache2/php.ini

memcached-service:
  service:
    - name: memcached
    - running
    - watch:
      - file: memcached_conf
      - pecl: pecl_memcache
