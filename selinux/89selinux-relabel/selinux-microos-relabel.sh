#!/bin/sh
type ismounted > /dev/null 2>&1 || . /lib/dracut-lib.sh

# In this mode, the zipl initrd uses grub2-emu to kexec the real kernel
# and initrd. Don't run there, only in the real initrd (s.a. bsc#1218065).
if getargbool 0 'initgrub'; then
    # This script gets sourced, so must use return here instead of exit
    return 0
fi

rd_is_selinux_enabled()
{
    # If SELinux is not enabled exit now
    grep -qw selinux /sys/kernel/security/lsm || return 1

    SELINUX="enforcing"
    [ -e "$NEWROOT/etc/selinux/config" ] && . "$NEWROOT/etc/selinux/config"

    if [ "$SELINUX" = "disabled" ]; then
        return 1;
    fi
    return 0
}

rd_microos_relabel()
{
    info "SELinux: relabeling root filesystem"

    root_is_btrfs=
    if [ "$(findmnt --noheadings --output FSTYPE --target "$NEWROOT")" = "btrfs" ]; then
        root_is_btrfs=y
    fi
    etc_is_overlay=
    if [ "$(findmnt --fstab --noheadings --output FSTYPE /etc --tab-file "${NEWROOT}/etc/fstab")" = "overlay" ]; then
        etc_is_overlay=y
    fi

    # If this doesn't exist because e.g. it's not mounted yet due to a bug
    # (boo#1197309), the exclusion is ignored. If it gets mounted during
    # the relabel, it gets wrong labels assigned.
    if [ -n "$etc_is_overlay" ] && ! [ -d "$NEWROOT/var/lib/overlay" ]; then
        warn "ERROR: /var/lib/overlay doesn't exist - /var not mounted (yet)?"
        return 1
    fi

    # Use alternate mount point to prevent overwriting subvolume options (bsc#1186563)
    ROOT_SELINUX="${NEWROOT}-selinux"
    mkdir -p "${ROOT_SELINUX}"
    # Don't let mounts propagate into other namespaces
    mount --bind --make-private "${ROOT_SELINUX}" "${ROOT_SELINUX}"
    mount --rbind --make-rslave "${NEWROOT}" "${ROOT_SELINUX}"
    ret=0
    for sysdir in /proc /sys /dev; do
        # Don't let recursive umounts propagate into the bind source
        if ! mount --rbind --make-rslave "${sysdir}" "${ROOT_SELINUX}${sysdir}" ; then
            warn "ERROR: mounting ${sysdir} failed!"
            ret=1
        fi
    done
    if [ $ret -eq 0 ]; then
        # Mount /var and /etc, need to be relabelled as well for booting.
        for mp in /var /etc; do
            if ! findmnt "${ROOT_SELINUX}${mp}" >/dev/null \
              && findmnt --fstab --output TARGET --tab-file "${ROOT_SELINUX}/etc/fstab" "$mp" >/dev/null; then
                chroot "$ROOT_SELINUX" mount "$mp" || ret=1
            fi
        done
    fi
    if [ $ret -eq 0 ]; then
        info "SELinux: mount root read-write and relabel"
        mount -o remount,rw "${ROOT_SELINUX}"
        if [ -n "$root_is_btrfs" ]; then
            oldrovalue="$(btrfs prop get "${ROOT_SELINUX}" ro | cut -d= -f2)"
            btrfs prop set "${ROOT_SELINUX}" ro false
        fi
        FORCE=
        [ -e "${ROOT_SELINUX}"/etc/selinux/.autorelabel ] && FORCE="$(cat "${ROOT_SELINUX}"/etc/selinux/.autorelabel)"
        . "${ROOT_SELINUX}"/etc/selinux/config
        # Marker when we had relabelled the filesystem. This is relabelled as well.
        > "${ROOT_SELINUX}"/etc/selinux/.relabelled
        if [ -n "$etc_is_overlay" ]; then
            LANG=C chroot "$ROOT_SELINUX" /sbin/setfiles $FORCE -T 0 -e /var/lib/overlay -e /proc -e /sys -e /dev -e /etc "/etc/selinux/${SELINUXTYPE}/contexts/files/file_contexts" $(chroot "$ROOT_SELINUX" cut -d" " -f2 /proc/mounts)
            # On overlayfs, st_dev isn't consistent so setfiles thinks it's a different mountpoint, ignoring it.
            # st_dev changes also on copy-up triggered by setfiles itself, so the only way to relabel properly
            # is to list every file explicitly.
            # That's not all: There's a kernel bug that security.selinux of parent directories is lost on copy-up (bsc#1210690).
            # Work around that by visiting children first and only then the parent directories.
            LANG=C chroot "$ROOT_SELINUX" find /etc -depth -exec /sbin/setfiles $FORCE "/etc/selinux/${SELINUXTYPE}/contexts/files/file_contexts" \{\} +
        else
            LANG=C chroot "$ROOT_SELINUX" /sbin/setfiles $FORCE -T 0 -e /proc -e /sys -e /dev "/etc/selinux/${SELINUXTYPE}/contexts/files/file_contexts" $(chroot "$ROOT_SELINUX" cut -d" " -f2 /proc/mounts)
        fi
        if [ -n "$root_is_btrfs" ]; then
            btrfs prop set "${ROOT_SELINUX}" ro "${oldrovalue}"
        fi
    fi

    umount -R "${ROOT_SELINUX}"
    # In some versions of util-linux, ^ does not umount stacked mounts
    # (https://github.com/util-linux/util-linux/issues/2551)
    # so take care of the private bind on itself separately:
    if ismounted "${ROOT_SELINUX}"; then
        umount "${ROOT_SELINUX}"
    fi

    return $ret
}

if [ -e "$NEWROOT"/.autorelabel ] && [ "$NEWROOT"/.autorelabel -nt "$NEWROOT"/etc/selinux/.relabelled ]; then
    mount -o remount,rw "$NEWROOT" || return 1
    cp -a "$NEWROOT"/.autorelabel "$NEWROOT"/etc/selinux/.autorelabel || return 1
    rm -f "$NEWROOT"/.autorelabel 2>/dev/null
fi

if rd_is_selinux_enabled; then
    if [ -f "$NEWROOT"/etc/selinux/.autorelabel ] || getarg "autorelabel" > /dev/null; then
        if ! rd_microos_relabel; then
            warn "SELinux autorelabelling failed!"
            return 1
        fi
    fi
elif test -e "$NEWROOT"/etc/selinux/.relabelled; then
    # SELinux is off but looks like some labeling took place before.
    # So probably a boot with manually disabled SELinux. Make sure
    # the system gets relabelled next time SELinux is on.
    > "$NEWROOT"/etc/selinux/.autorelabel
    warn "SELinux is off in labelled system!"
fi

return 0
