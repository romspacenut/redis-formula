include:
  - redis.common

{% from "redis/map.jinja" import redis_settings with context %}

{% set install_from = redis_settings.install_from -%}
{% set cluster      = redis_settings.cluster.get(grains['id'], {}) -%}
{% set version      = redis_settings.version|default('3.0.2') -%}
{% set root         = redis_settings.root|default('/usr/local') -%}

stop-redis-server:
  service.dead:
    - name: redis-server

service-redis-node:
  file.managed:
    - name: /etc/init.d/redis-node
    - mode: 755
    - makedirs: True
    - source: salt://redis/files/redis-node

{% for port, node in cluster.items() %}
redis-conf-dir-{{ port }}:
  file.directory:
    - user: redis
    - name: /etc/redis/node-{{ port }}
    - makedirs: True

/var/lib/redis/node-{{ port }}:
  file.directory:
    - user: redis
    - makedirs: True

/etc/redis/node-{{ port }}/redis.conf:
  file.absent

redis-node-{{ port }}:
  file.managed:
    - name: /etc/redis/node-{{ port }}/redis.conf
    - user: redis
    - mode: 755
    - makedirs: True
    - template: jinja
    - source: salt://redis/files/redis.conf.jinja
    - require:
      - file: redis-conf-dir-{{ port }}
#      - cmd: redis-old-init-disable
    - default:
      node: {{ node }}

/etc/init.d/redis-node-{{ port }}-stop:
  cmd.run:
    - name: /etc/init.d/redis-node-{{ port }} stop
    - cwd: /

/etc/init.d/redis-node-{{ port }}:
  file.symlink:
    - target: /etc/init.d/redis-node
    - require:
      - file: service-redis-node
  service.running:
    - name: redis-node-{{ port }}
    - enable: True
    - reload: True
    - restart: True
    - watch:
      - file: /etc/init.d/redis-node-{{ port }}
{% endfor %}

{% for port, node in cluster.items() %}
{% if node.get('slaveof_host') is defined %}
redis-slaveof-{{ port }}:
  cmd.wait:
    - name: redis-cli -p {{ port }} SLAVEOF {{ node.get('slaveof_host') }} {{ node.get('slaveof_port') }}
    - cwd: /
    - require:
      - file: /etc/init.d/redis-node-{{ port }}
{% else %}
redis-slaveof-no-one-{{ port }}:
  cmd.wait:
    - name: redis-cli -p {{ port }} SLAVEOF NO ONE
    - cwd: /
    - require:
      - file: /etc/init.d/redis-node-{{ port }}
{% endif %}
{% endfor %}