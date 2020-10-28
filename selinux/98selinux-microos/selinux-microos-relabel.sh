#!/bin/sh

rd_microos_relabel()
{
    # If SELinux is not enabled exit now
    getarg "selinux=1" > /dev/null || return 0

    SELINUX="enforcing"
    [ -e "$NEWROOT/etc/selinux/config" ] && . "$NEWROOT/etc/selinux/config"

    if [ "$SELINUX" = "disabled" ]; then
        return 0;
    fi

    # We need to load a SELinux policy to label the filesystem
    if [ -x "$NEWROOT/usr/sbin/load_policy" ]; then
        ret=0
        info "SELinux: relabeling root filesystem"

	for sysdir in /proc /sys /dev; do
	    if ! mount --rbind "${sysdir}" "${NEWROOT}${sysdir}" ; then
		warn "ERROR: mounting ${sysdir} failed!"
		ret=1
	    fi
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
		mount -o remount,rw "$NEWROOT"
                FORCE=$(cat "$NEWROOT"/etc/selinux/.autorelabel)
		LANG=C chroot "$NEWROOT" /sbin/restorecon $FORCE -R -e /var/lib/overlay -e /sys -e /dev -e /run /
		mount -o remount,ro "$NEWROOT"
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

test -e "$NEWROOT"/.autorelabel -a "$NEWROOT"/.autorelabel -nt "$NEWROOT"/etc/selinux/.relabelled && (cp -a "$NEWROOT"/.autorelabel "$NEWROOT"/etc/selinux/.autorelabel; rm -f "$NEWROOT"/.autorelabel 2>/dev/null || true )

if test -f "$NEWROOT"/etc/selinux/.autorelabel; then
    rd_microos_relabel
elif getarg "autorelabel" > /dev/null; then
    rd_microos_relabel
fi

return 0
