#!/bin/sh

rd_is_selinux_enabled()
{
    # If SELinux is not enabled exit now
    getarg "selinux=1" > /dev/null || return 1

    SELINUX="enforcing"
    [ -e "$NEWROOT/etc/selinux/config" ] && . "$NEWROOT/etc/selinux/config"

    if [ "$SELINUX" = "disabled" ]; then
        return 1;
    fi
    return 0
}

rd_microos_relabel()
{
    # We need to load a SELinux policy to label the filesystem
    if [ -x "$NEWROOT/usr/sbin/load_policy" ]; then
        ret=0
        info "SELinux: relabeling root filesystem"

	for sysdir in /proc /sys /dev; do
	    if ! mount --rbind "${sysdir}" "${NEWROOT}${sysdir}" ; then
		warn "ERROR: mounting ${sysdir} failed!"
		ret=1
	    fi
            # Don't let recursive umounts propagate into the bind source
            mount --make-rslave "${NEWROOT}${sysdir}"
	done
	if [ $ret -eq 0 ]; then
            # load_policy does mount /proc and /sys/fs/selinux in
            # libselinux,selinux_init_load_policy()
            info "SELinux: loading policy"
	    out=$(LANG=C chroot "$NEWROOT" /usr/sbin/load_policy -i 2>&1)
	    ret=$?
	    info "$out"

            if [ $ret -eq 0 ]; then
		#LANG=C /usr/sbin/setenforce 0
                info "SELinux: mount root read-write and relabel"
		# Use alternate mount point to prevent overwriting subvolume options (bsc#1186563)
		ROOT_SELINUX="${NEWROOT}-selinux"
		mkdir -p "${ROOT_SELINUX}"
		mount --rbind --make-rslave "${NEWROOT}" "${ROOT_SELINUX}"
		mount -o remount,rw "${ROOT_SELINUX}"
                FORCE=
		[ -e "${ROOT_SELINUX}"/etc/selinux/.autorelabel ] && FORCE="$(cat "${ROOT_SELINUX}"/etc/selinux/.autorelabel)"
		LANG=C chroot "${ROOT_SELINUX}" /sbin/restorecon $FORCE -R -e /var/lib/overlay -e /sys -e /dev -e /run /
		umount -R "${ROOT_SELINUX}"
            fi
	fi
	for sysdir in /proc /sys /dev; do
	    if ! umount -R "${NEWROOT}${sysdir}" ; then
		warn "ERROR: unmounting ${sysdir} failed!"
		ret=1
	    fi
	done

	# Marker when we had relabelled the filesystem
	> "$NEWROOT"/etc/selinux/.relabelled

	return $ret
    fi
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
    warn "SElinux is off in lablelled system!"
fi

return 0
