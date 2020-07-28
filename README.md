# MicroOS Tools
Files and scripts for openSUSE MicroOS

## systemd services

### setup-systemd-proxy-env.service

The `setup-systemd-proxy-env.service` makes the proxy variables from
`/etc/sysconfig/proxy` available to all systemd units.

### printenv.service

The `printenv.service` is to debug which environment variables exist
by default. It just calls `printenv`.
