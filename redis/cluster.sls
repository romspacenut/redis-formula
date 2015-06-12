include:
  - redis.common

{% from "redis/map.jinja" import redis_settings with context %}

{% set install_from = redis_settings.install_from -%}
{% set cluster      = redis_settings.cluster.get(grains['id'], {}) -%}
{% set version      = redis_settings.version|default('3.0.2') -%}
{% set root         = redis_settings.root|default('/usr/local') -%}

{% for port, node in cluster.items() %}
redis-conf-dir-{{ port }}:
  file.directory:
    - name: /etc/redis/node-{{ port }}
    - makedirs: True

/var/lib/redis/node-{{ port }}:
  file.directory:
    - owner: redis
    - makedirs: True

redis-node-{{ port }}:
  file.managed:
    - name: /etc/redis/node-{{ port }}/redis.conf
    - mode: 755
    - makedirs: True
    - template: jinja
    - source: salt://redis/files/redis.conf.jinja
    - require:
      - file: redis-conf-dir-{{ port }}
#      - cmd: redis-old-init-disable
    - default:
      node: {{ node }}

/etc/init.d/redis-node-{{ port }}:
  file.symlink:
    - target: /etc/init.d/redis-node
  service.running:
    - name: redis-node-{{ port }}
    - enable: True
    - reload: True
    - restart: True
    - watch:
      - file: /etc/init.d/redis-node-{{ port }}
{% endfor %}