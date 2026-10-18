# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

The parent `../CLAUDE.md` describes the fork collection, the shared toolchain
(Test Kitchen, pre-commit, CI) and the `template-formula` layout. This file only
covers what is specific to `telegraf-formula`.

## Commands

```bash
bundle install
bin/kitchen list                               # 3 instances: default-<platform>
bin/kitchen test default-debian-13-3008-2      # one instance end to end
bin/kitchen converge default-debian-11-3006-27 # apply only, keep the container
bin/kitchen verify default-debian-11-3006-27   # rerun the InSpec controls
pre-commit run --all-files
```

There is a single suite, `default`, so one instance per platform.

## How the formula works

The whole formula is a pipeline from one pillar key to one file:

1. `map.jinja` merges `defaults.yaml` with the pillar/config under `telegraf`.
2. `config/file.sls` passes `telegraf.conf` (the dict, not the path) as the
   template context.
3. `files/default/telegraf.tmpl.jinja` is a single call,
   `salt['slsutil.serialize']('toml', telegraf)`, written to `telegraf.config`
   (`/etc/telegraf/telegraf.conf`).

There is no per-plugin templating: every Telegraf section is a pillar key under
`telegraf:conf` (`agent`, `global_tags`, `inputs:<plugin>`, `outputs:<plugin>`,
`processors:<plugin>`), and its TOML shape is whatever the serializer produces
from the YAML. The inputs in `defaults.yaml` are merged with the pillar, so they
are always rendered; a pillar adds sections, it does not replace the default set.

### Points that look removable but are not

- **`toml` in Salt's Python.** The TOML serializer imports the `toml` library,
  which is in neither the 3006 nor the 3008 onedir. `package/install.sls`
  pip-installs it **pinned** (`toml == 0.10.2`) on Salt ≥ 3001: unpinned, a new
  release would land in every minion's onedir at the next highstate. The
  `pkg.installed` branch with `toml_pkg` (and the Python 2 branch of `map.jinja`
  that sets it) is dead on Salt ≥ 3001.
- **`telegraf.conf` permissions.** It holds the InfluxDB password, hence
  `mode: '0640'`, group `telegraf` (`system_group` in `defaults.yaml`) and
  `show_changes: False`, so a password change never appears in a job return.
  Keep all three when touching `config/file.sls`.
- **`repo/install.sls` is an intentional no-op.** The InfluxData repository is
  declared by apt-formula (deb822 file, key in its own keyring); the former
  `pkgrepo.managed` had no `signed-by` and fails where `apt-key` is gone
  (Debian 13). `telegraf.repo` stays in `init.sls` only as an include target.

### Dead map data

Nothing reads `repo`, `repo_python` or `arch` any more, so on Debian
`osarchmap.yaml`, `osfamilymap.yaml`, `osmap.yaml` and `osfingermap.yaml`
contribute nothing to the rendered config. Change defaults in `defaults.yaml`.

## Tests

- `test/salt/states/repo.sls` reproduces the production repository (deb822
  source + keyring under `/etc/apt/keyrings/`) and runs first in `state_top`;
  without it the package cannot be installed, since the formula no longer
  declares a repository.
- `test/salt/pillar/telegraf.sls` adds `outputs.discard`, which
  `config_spec.rb` asserts on; the other assertions cover the default inputs.
- `telegraf._mapdata` runs in the suite, but this fork has **no**
  `_mapdata` control and no reference dumps under
  `test/integration/default/files/`, so the merged map is never compared.
