modulesdir = @dracutmodulesdir@/89selinux-relabel
selinuxdir = @sysconfdir@/selinux
systemddir = $(systemdsystemunitdir)

modules_SCRIPTS = 89selinux-relabel/selinux-microos-relabel.sh \
	89selinux-relabel/module-setup.sh

selinux_DATA = fixfiles_exclude_dirs

systemdgenerator_SCRIPTS = selinux-autorelabel-generator

systemd_DATA = systemd-tmpfiles-setup-sys.service

EXTRA_DIST = $(SCRIPTS) $(DATA)
