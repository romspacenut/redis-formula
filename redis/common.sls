{% from "redis/map.jinja" import redis_settings with context %}

{% if redis_settings.install_from == 'source' %}
{% set version  = redis_settings.version|default('3.2.3') -%}
{% set checksum = redis_settings.checksum|default('sha1=92d6d93ef2efc91e595c8bf578bf72baff397507') -%}
{% set root     = redis_settings.root|default('/usr/local') -%}

{# there is a missing config template for version 2.8.8 #}

redis-dependencies:
  pkg.installed:
    - names:
    {% if grains['os_family'] == 'RedHat' %}
        - python-devel
        - make
        - libxml2-devel
    {% elif grains['os_family'] == 'Debian' or 'Ubuntu' %}
        - build-essential
        - python-dev
        - libxml2-dev
    {% endif %}

get-redis:
  file.managed:
    - name: {{ root }}/redis-{{ version }}.tar.gz
    - source: http://download.redis.io/releases/redis-{{ version }}.tar.gz
    - source_hash: {{ checksum }}
    - require:
      - pkg: redis-dependencies
  cmd.wait:
    - cwd: {{ root }}
    - names:
      - tar -zxvf {{ root }}/redis-{{ version }}.tar.gz -C {{ root }}
    - watch:
      - file: get-redis

make-and-install-redis:
  cmd.wait:
    - cwd: {{ root }}/redis-{{ version }}
    - names:
      - make
      - make install
    - watch:
      - cmd: get-redis
{% elif redis_settings.install_from == 'package' %}
redis-repo:
  pkgrepo.managed:
    - ppa: {{ redis_settings.pkg_ppa }}
    - require_in:
      - pkg: install-redis
    - watch_in:
      - pkg: install-redis

install-redis:
  pkg.installed:
    - name: {{ redis_settings.pkg_name }}
    {% if redis_settings.version is defined %}
    - version: {{ redis_settings.version }}
    {% endif %}
{% endif %}
