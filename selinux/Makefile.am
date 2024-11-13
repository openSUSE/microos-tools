modulesdir = @dracutmodulesdir@/98selinux-microos
selinuxdir = @sysconfdir@/selinux
systemddir = $(systemdsystemunitdir)

modules_SCRIPTS = 98selinux-microos/selinux-microos-relabel.sh \
	98selinux-microos/module-setup.sh

selinux_DATA = fixfiles_exclude_dirs

systemdgenerator_SCRIPTS = selinux-autorelabel-generator

systemd_DATA = systemd-tmpfiles-setup-sys.service

EXTRA_DIST = $(SCRIPTS) $(DATA)
