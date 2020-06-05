# MicroOS Tools
Files and scripts for openSUSE MicroOS

## /tmp and tmpfs
MicroOS uses now tmpfs for /tmp. This might break a few programs which
assume that they can place large files in /tmp or that /tmp is persistant
across boot. 

Mounting of tmpfs on /tmp can be disabled by issuing
`systemctl mask tmp.mount`, and reboot.

A `/tmp` entry in `/etc/fstab` also take preference over the tmpfs
mount unit. So updated systems will continue to use the tmp subvolume
until this entry get's removed from `/etc/fstab`.
