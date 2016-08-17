{% from "redis/map.jinja" import redis_settings with context %}

{%- if redis_settings.cluster is defined %}
include:
  - redis.common
  
{% set cluster = redis_settings.cluster %}

# this is a hack until redis-node upstart is fixed
kill-all-redis-nodes:
  cmd.run:
    - name: killall -9 redis-server
    - onlyif: ps xawww | grep "redis-server" | grep -v "grep" | grep -c .

{% for port, node in cluster.items() %}
service-redis-node-{{ port }}:
  file.managed:
    - name: /etc/init.d/redis-node-{{ port }}
    - user: root
    - mode: 0755
    - makedirs: True
    - source: salt://redis/files/redis-node.jinja

usr-local-service-redis-node-{{ port }}:
  file.managed:
    - name: /usr/local/bin/redis-node-{{ port }}
    - user: root
    - mode: 0755
    - makedirs: True
    - source: salt://redis/files/redis-node.jinja

usr-bin-service-redis-node-{{ port }}:
  file.managed:
    - name: /usr/bin/redis-node-{{ port }}
    - user: root
    - mode: 0755
    - makedirs: True
    - source: salt://redis/files/redis-node.jinja

redis-conf-dir-{{ port }}:
  file.directory:
    - user: root
    - name: /etc/redis/node-{{ port }}
    - makedirs: True

/var/lib/redis/node-{{ port }}:
  file.directory:
    - user: redis
    - makedirs: True

/etc/redis/node-{{ port }}/redis.conf:
  file.absent

config-redis-node-{{ port }}:
  file.managed:
    - name: /etc/redis/node-{{ port }}/redis.conf
    - user: redis
    - group: redis
    - mode: 755
    - makedirs: True
    - template: jinja
    - source: salt://redis/files/redis.conf.jinja
    - require_in:
      service: /etc/init.d/service-redis-node-{{ port }}
    - require:
      - file: redis-conf-dir-{{ port }}
#      - cmd: redis-old-init-disable
    - default:
      node: {{ node }}

#/etc/init.d/redis-node-{{ port }}:
#  service.running:
#    - enable: True
#    - reload: True
#    - restart: True
#    - watch:
#      - file: /etc/redis/node-{{ port }}/redis.conf

# this is a hack to restart a redis node until the upstart is fixed; should use service.running
restart-redis-node-{{ port }}:
  cmd.run:
    - name: service redis-node-{{ port }} restart
    - watch:
      - file: /etc/redis/node-{{ port }}/redis.conf
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
{%- endif %}