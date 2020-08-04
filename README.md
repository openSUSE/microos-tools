# MicroOS Tools
Files and scripts for openSUSE MicroOS

## /tmp on tmpfs with noexec flag

By default, MicroOS is using tmpfs for /tmp with noexec flag set.
For this reasons, salt-minion will write it's temporary files into
/run/salt-tmp.
In general, daemons should use private disk space for their data
and not shared one in /tmp.

## SELinux

MicroOS has preliminary support for SELinux.
If the file `/etc/selinux/.autorelabel` exists, the dracut module
`98selinux-microos` will label the root filesystem including
`/etc` and `/var`.

## systemd services

### setup-systemd-proxy-env.service

The `setup-systemd-proxy-env.service` makes the proxy variables from
`/etc/sysconfig/proxy` available to all systemd units.

### printenv.service

The `printenv.service` is to debug which environment variables exist
by default. It just calls `printenv`.

