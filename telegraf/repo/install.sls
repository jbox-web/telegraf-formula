# -*- coding: utf-8 -*-
# vim: ft=sls

{#- The InfluxData repository is declared by apt-formula (deb822 file and its
    own keyring), not here: the former `pkgrepo.managed` state had no
    `signed-by` and fails where `apt-key` is gone (Debian 13). #}
