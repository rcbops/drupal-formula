# A salt formula for creating a drupal cluster

This formula can:
* Set up HAPROXY for load balancing multiple drupal web servers.
* Set up apache2, drupal, php5, memcached, and php-apc for a drupal web server.

When used in conjunction with the [sync](https://github.com/absalon-james/sync) formula, web files can be syncronized between multiple web servers.

#### Dependencies
* formula [sync](://github.com/rcbops/sync-formula) Optional

#### Pillar
```yaml

# Need to inform the formula how to determine what address mysql should bind
# to. Mysql will bind to the ip of the private interface
# sync (if used) will bind to the ip of the private interface
# haproxy will bind to the ip of the public interface
interfaces:
  private: eth2
  public: eth0

# The formula will pull host and ip addresses of other related nodes using the salt mine.
mine_functions:
  network.ip_addrs: [eth0]
  network.interfaces: []
  grains.get: ['host']
mine_interval: 1

# Need to inform drupal on how to connect to the drupal database
# This pillar should only be readable by the same user salt runs under.
drupal:
  # Only versions 7.31 and 7.32 are supported at this time
  version: '7.32'
  db:
    name: database-name
    user: drupal-stack
    password: some-hard-password
    host: location-of-database
    read:
      port: 3306
    write:
      port: 13306
```

#### How to use
If using a top file:
```shell
salt <targets> state.highstate
```

Haproxy explicitly:
```shell
salt <target> state.sls drupal.haproxy
```

Webserver explicitly:
```shell
salt <target> state.sls drupal.web
```

#### SSL
This formula will create a self signed ssl cert by default. You can provide
your own cert by placing a copy at drupal/files/haproxy/drupal.pem.
Before running state.highstate, make sure an existing self signed cert
is gone:

```shell
salt -G roles:haproxy cmd.run "rm /etc/ssl/private/drupal.pem"
salt -G roles:haproxy state.highstate
```

#### Helpful links
* [drupal](https://www.drupal.org/)
* [haproxy](http://www.haproxy.org/)
* [memcached](http://memcached.org/)
* [php5](http://php.net/)
* [php-apc](http://php.net/manual/en/book.apc.php)

