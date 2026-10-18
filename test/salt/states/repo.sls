# -*- coding: utf-8 -*-
# vim: ft=sls
---
# Test-only: declare the influxdata repository the way VEILLECO's apt-formula does in
# production (deb822 file, key in its own keyring), so the formula installs the
# package with `use_upstream_repo: false`.
test-repo-influxdata-key:
  file.managed:
    - name: /etc/apt/keyrings/influxdata.asc
    - source: https://repos.influxdata.com/influxdata-archive.key
    - skip_verify: true
    - makedirs: true
    - mode: '0644'

test-repo-influxdata-source:
  file.managed:
    - name: /etc/apt/sources.list.d/influxdata.sources
    - mode: '0644'
    - contents: |
        Types: deb
        URIs: https://repos.influxdata.com/debian
        Suites: {{ grains['oscodename'] }}
        Components: stable
        Signed-By: /etc/apt/keyrings/influxdata.asc
    - require:
      - file: test-repo-influxdata-key

test-repo-influxdata-refresh:
  cmd.run:
    - name: apt-get update
    - onchanges:
      - file: test-repo-influxdata-source
