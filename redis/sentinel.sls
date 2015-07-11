#include:
#  - redis.common

{% from "redis/map.jinja" import redis_settings with context %}

{% set install_from = redis_settings.install_from -%}
{% set sentinel     = redis_settings.sentinel.get(grains['id'], redis_settings.sentinel.default) -%}
{% set version      = redis_settings.version|default('3.0.2') -%}
{% set root         = redis_settings.root|default('/usr/local') -%}

update-redis-conf-owner:
  file.managed:
    - name: /etc/redis/redis.conf
    - user: redis

/etc/redis/notification.sh:
  file.managed:
    - user: redis
    - mode: 755
    - makedirs: True
#    - template: jinja
    - source: salt://redis/files/notification.sh

/etc/redis/sentinel.conf:
  file.managed:
    - user: redis
    - mode: 755
    - makedirs: True
    - template: jinja
    - source: salt://redis/files/sentinel.conf.jinja
    - default:
      sentinel: {{ sentinel }}

kill-redis-sentinel:
  cmd.run:
    - name: killall -9 redis-sentinel
    - cwd: /

/etc/init.d/redis-sentinel:
  file.managed:
    - mode: 755
    - makedirs: True
    - template: jinja
    - source: salt://redis/files/redis-sentinel.jinja
  cmd.run: # manually restart sentinel
    - cwd: /
    - name: service redis-sentinel start
    - watch:
      - file: /etc/init.d/redis-sentinel

#service-redis-sentinel:
#  service.running:
#    - name: redis-sentinel
#    - enable: True
#    - reload: True
#    - restart: True
#    - watch:
#      - file: /etc/redis/sentinel.conf