modulesdir = @dracutmodulesdir@/98selinux-microos
selinuxdir = @sysconfdir@/selinux

modules_SCRIPTS = 98selinux-microos/selinux-microos-relabel.sh \
	98selinux-microos/module-setup.sh

selinux_DATA = fixfiles_exclude_dirs
tmpfiles_DATA = tmp.conf

systemdgenerator_SCRIPTS = selinux-autorelabel-generator

EXTRA_DIST = $(SCRIPTS) $(DATA)
