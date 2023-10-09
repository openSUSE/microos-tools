#!/bin/bash

# called by dracut
check() {
    test -f /etc/selinux/config || return 1
    return 0
}

# called by dracut
depends() {
    return 0
}

# called by dracut
install() {
    inst_hook pre-pivot 50 "$moddir/selinux-microos-relabel.sh"
    inst_multiple chroot cut grep
}
