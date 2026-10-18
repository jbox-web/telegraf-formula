# -*- coding: utf-8 -*-
# vim: ft=sls

{#- Get the `tplroot` from `tpldir` #}
{%- set tplroot = tpldir.split('/')[0] %}
{%- set sls_package_install = tplroot ~ '.package.install' %}
{%- from tplroot ~ "/map.jinja" import telegraf with context %}
{%- from tplroot ~ "/libtofs.jinja" import files_switch with context %}

include:
  - {{ sls_package_install }}

telegraf/config/install:
  file.managed:
    - name: {{ telegraf.config }}
    - source: {{ files_switch(['telegraf.tmpl.jinja'],
                              lookup='telegraf/config/install'
                 )
              }}
    # The file holds output credentials (e.g. the InfluxDB password): readable
    # by the service group only, and never shown in a state diff.
    - mode: '0640'
    - user: {{ telegraf.system_user }}
    - group: {{ telegraf.system_group }}
    - show_changes: False
    - makedirs: True
    - template: jinja
    - require:
      - sls: {{ sls_package_install }}
    - context:
        telegraf: {{ telegraf.conf | json }}
