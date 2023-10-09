#!/bin/sh

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

    # If this doesn't exist because e.g. it's not mounted yet due to a bug
    # (boo#1197309), the exclusion is ignored. If it gets mounted during
    # the relabel, it gets wrong labels assigned.
    if ! [ -d "$NEWROOT/var/lib/overlay" ]; then
	warn "ERROR: /var/lib/overlay doesn't exist - /var not mounted (yet)?"
	return 1
    fi

    ret=0
    for sysdir in /proc /sys /dev; do
	if ! mount --rbind "${sysdir}" "${NEWROOT}${sysdir}" ; then
	    warn "ERROR: mounting ${sysdir} failed!"
	    ret=1
	fi
	# Don't let recursive umounts propagate into the bind source
	mount --make-rslave "${NEWROOT}${sysdir}"
    done
    if [ $ret -eq 0 ]; then
	info "SELinux: mount root read-write and relabel"
	# Use alternate mount point to prevent overwriting subvolume options (bsc#1186563)
	ROOT_SELINUX="${NEWROOT}-selinux"
	mkdir -p "${ROOT_SELINUX}"
	mount --rbind --make-rslave "${NEWROOT}" "${ROOT_SELINUX}"
	mount -o remount,rw "${ROOT_SELINUX}"
	oldrovalue="$(btrfs prop get "${ROOT_SELINUX}" ro | cut -d= -f2)"
	btrfs prop set "${ROOT_SELINUX}" ro false
	FORCE=
	[ -e "${ROOT_SELINUX}"/etc/selinux/.autorelabel ] && FORCE="$(cat "${ROOT_SELINUX}"/etc/selinux/.autorelabel)"
	. "${ROOT_SELINUX}"/etc/selinux/config
	# Marker when we had relabelled the filesystem. This is relabelled as well.
	> "${ROOT_SELINUX}"/etc/selinux/.relabelled
	LANG=C chroot "$ROOT_SELINUX" /sbin/setfiles $FORCE -e /var/lib/overlay -e /proc -e /sys -e /dev -e /etc "/etc/selinux/${SELINUXTYPE}/contexts/files/file_contexts" $(chroot "$ROOT_SELINUX" cut -d" " -f2 /proc/mounts)
        # On overlayfs, st_dev isn't consistent so setfiles thinks it's a different mountpoint, ignoring it.
        # st_dev changes also on copy-up triggered by setfiles itself, so the only way to relabel properly
        # is to list every file explicitly.
        # That's not all: There's a kernel bug that security.selinux of parent directories is lost on copy-up (bsc#1210690).
        # Work around that by visiting children first and only then the parent directories.
        LANG=C chroot "$ROOT_SELINUX" find /etc -depth -exec /sbin/setfiles $FORCE "/etc/selinux/${SELINUXTYPE}/contexts/files/file_contexts" \{\} +
	btrfs prop set "${ROOT_SELINUX}" ro "${oldrovalue}"
	umount -R "${ROOT_SELINUX}"
    fi
    for sysdir in /proc /sys /dev; do
	if ! umount -R "${NEWROOT}${sysdir}" ; then
	    warn "ERROR: unmounting ${sysdir} failed!"
	    ret=1
	fi
    done

    return $ret
}

if test -e "$NEWROOT"/.autorelabel -a "$NEWROOT"/.autorelabel -nt "$NEWROOT"/etc/selinux/.relabelled ; then
    cp -a "$NEWROOT"/.autorelabel "$NEWROOT"/etc/selinux/.autorelabel
    rm -f "$NEWROOT"/.autorelabel 2>/dev/null
fi

if rd_is_selinux_enabled; then
    if test -f "$NEWROOT"/etc/selinux/.autorelabel; then
	rd_microos_relabel
    elif getarg "autorelabel" > /dev/null; then
	rd_microos_relabel
    fi
elif test -e "$NEWROOT"/etc/selinux/.relabelled; then
    # SELinux is off but looks like some labeling took place before.
    # So probably a boot with manually disabled SELinux. Make sure
    # the system gets relabelled next time SELinux is on.
    > "$NEWROOT"/etc/selinux/.autorelabel
    warn "SElinux is off in labelled system!"
fi

return 0
