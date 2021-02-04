# MicroOS Tools
Files and scripts for openSUSE MicroOS

## /tmp on tmpfs with noexec flag

MicroOS will use tmpfs for /tmp with noexec flag set in the future.
For this reasons, salt-minion will write it's temporary files into
/run/salt-tmp.
In general, daemons should use private disk space for their data
and not shared one in /tmp.

## SELinux

MicroOS has preliminary support for SELinux.
If the file `/etc/selinux/.autorelabel` exists, the dracut module
`98selinux-microos` will label the root filesystem including
`/etc` and `/var`.

## locale-check

MicroOS supports only a limited number of locales (C, C.utf8, en_US.utf8,
POSIX). If you login via SSH, the locale settings will be verified that
they exist on this system. If not, locale is reset to the system default.

## systemd services

### setup-systemd-proxy-env.service

The `setup-systemd-proxy-env.service` makes the proxy variables from
`/etc/sysconfig/proxy` available to all systemd units.

### printenv.service

The `printenv.service` is to debug which environment variables exist
by default. It just calls `printenv`.

## development tools

* microos-rw: switches the root file system to read-write
* microos-ro: resets btrfs property to read-only again.
* rpmorphan: display files not owned by rpm
* rpm-sortbysize: list all installed packages sorted by size
