systemddir = $(systemdsystemunitdir)

libexec_SCRIPTS = MicroOS-firstboot
systemd_DATA = MicroOS-firstboot.service

EXTRA_DIST = MicroOS-firstboot.service.in $(SCRIPTS)

install-data-hook:
	mkdir -p $(DESTDIR)@sysconfdir@/systemd/system
	ln -sf /dev/null $(DESTDIR)@sysconfdir@/systemd/system/systemd-firstboot.service

install-exec-hook:
	mkdir -p $(DESTDIR)/$(systemdsystemunitdir)/sysinit.target.wants
	ln -sf ../MicroOS-firstboot.service $(DESTDIR)$(systemdsystemunitdir)/sysinit.target.wants/MicroOS-firstboot.service
