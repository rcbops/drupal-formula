{%- set keyname = '/etc/ssl/private/drupal' -%}
{%- set interface = salt['pillar.get']('interfaces:public', 'eth0') -%}
{%- set ip = salt['network.ipaddrs'](interface)[0] -%}
{%- set cn = salt['pillar.get']('ssl:cn', ip) -%}

# Temporary hack for now. Should switch back to pkgrepo.manahed
apt-add-repository -y ppa:vbernat/haproxy-1.5:
  cmd.run:
    - require_in:
      - pkg:haproxy-software

#haproxy-repo:
#  pkgrepo.managed:
#    - humanname: haproxy
#    - name: ppa:vbernat/haproxy-1.5
#    - require_in:
#      - pkg:haproxy-software

haproxy-software:
  pkg.installed:
    - pkgs:
      - haproxy

{{ keyname }}.pem:
  file.managed:
    - source: salt://drupal/files/haproxy/cert.pem
    - replace: False
    - mode: 600

generate-self-signed-cert:
  cmd.run:
    - name: openssl req -x509 -nodes -newkey rsa:2048 -keyout {{ keyname }}.key -out {{ keyname }}.crt -days 999 -subj "/CN={{ cn }}" 
    - unless: test -s {{ keyname }}.pem
    - require:
      - file: {{ keyname }}.pem

create-pem:
  cmd.wait:
    - name: cat {{ keyname }}.crt {{ keyname }}.key > {{ keyname }}.pem;
    - watch:
      - cmd: generate-self-signed-cert

rm {{ keyname }}.crt {{ keyname }}.key:
  cmd.wait:
    - watch:
      - cmd: create-pem

/etc/haproxy/haproxy.cfg:
  file.managed:
    - source: salt://drupal/files/haproxy/haproxy.cfg
    - template: jinja
    - makedirs: True

/etc/default/haproxy:
  file.managed:
    - source: salt://drupal/files/haproxy/default-haproxy
    - makedirs: True

haproxy-service:
  service:
    - name: haproxy
    - running
    - enable: True
    - require:
      - pkg: haproxy-software
    - watch:
      - file: /etc/haproxy/haproxy.cfg
      - file: /etc/default/haproxy
      - cmd: create-pem
