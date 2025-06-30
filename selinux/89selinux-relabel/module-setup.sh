#!/bin/bash

# called by dracut
check() {
    test -f /etc/selinux/config || return 1

    # Relabelling /etc and /var from the initrd needs support for mounting,
    # "chroot mount /..." still loads modules from the initrd.
    # Dracut handles /etc already, but for /var we need to DIY.
    if [[ -f $dracutsysrootdir/etc/fstab ]]; then
        _dev="$(findmnt --fstab --noheadings --output SOURCE /var --tab-file "$dracutsysrootdir/etc/fstab")"
        if [[ -n $_dev ]]; then
            _fstype="$(findmnt --fstab --noheadings --output FSTYPE /var --tab-file "$dracutsysrootdir/etc/fstab")"
            _dev="$(expand_persistent_dev "$_dev")"
            _dev="$(readlink -f "$_dev")"
            if [[ -b $_dev ]]; then
                push_host_devs "$_dev"
                if [[ -z ${host_fs_types["$_dev"]} ]]; then
                    host_fs_types["$_dev"]="$_fstype"
                fi
            fi
        fi
    fi

    return 0
}

# called by dracut
depends() {
    return 0
}

# called by dracut
install() {
    inst_hook pre-pivot 50 "$moddir/selinux-microos-relabel.sh"
    inst_multiple chroot cut findmnt grep
}
