#!/bin/sh

rd_microos_relabel()
{
    # If SELinux is disabled exit now
    getarg "selinux=0" > /dev/null && return 0

    SELINUX="enforcing"
    [ -e "$NEWROOT/etc/selinux/config" ] && . "$NEWROOT/etc/selinux/config"

    if [ "$SELINUX" = "disabled" ]; then
        return 0;
    fi

    # We need to load a SELinux policy to label the filesystem
    if [ -x "$NEWROOT/usr/sbin/load_policy" ]; then
        ret=0
        info "Loading SELinux policy"

	for sysdir in /proc /sys /dev; do
	    if ! mount --rbind "${sysdir}" "${NEWROOT}${sysdir}" ; then
		warn "ERROR: mounting ${sysdir} failed!"
		ret=1
	    fi
	done
	if [ $ret -eq 0 ]; then
            # load_policy does mount /proc and /sys/fs/selinux in
            # libselinux,selinux_init_load_policy()
            if [ -x "$NEWROOT/sbin/load_policy" ]; then
		out=$(LANG=C chroot "$NEWROOT" /sbin/load_policy -i 2>&1)
		ret=$?
		info "$out"
            else
		out=$(LANG=C chroot "$NEWROOT" /usr/sbin/load_policy -i 2>&1)
		ret=$?
		info "$out"
            fi

            if [ $ret -eq 0 ]; then
		#LANG=C /usr/sbin/setenforce 0
		mount -o remount,rw "$NEWROOT"
		LANG=C chroot "$NEWROOT" /sbin/restorecon -R -e /var/lib/overlay -e /sys -e /dev -e /run /
		rm -f "$NEWROOT"/.autorelabel
		rm -f "$NEWROOT"/etc/sysconfig/.autorelabel
		mount -o remount,ro "$NEWROOT"
            fi
	fi
	for sysdir in /proc /sys /dev; do
	    if ! umount -R "${NEWROOT}${sysdir}" ; then
		warn "ERROR: unmounting ${sysdir} failed!"
		ret=1
	    fi
	done

	return $ret
    fi
}

if test -f "$NEWROOT"/etc/selinux/.autorelabel; then
    rd_microos_relabel 
elif getarg "autorelabel" > /dev/null; then
    rd_microos_relabel
fi

return 0
