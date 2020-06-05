systemddir = $(systemdsystemunitdir)

systemd_DATA = tmp.mount

EXTRA_DIST = $(DATA)

install-data-hook:
	mkdir -p $(DESTDIR)/$(systemdsystemunitdir)/local-fs.target.wants
	ln -sf ../tmp.mount $(DESTDIR)$(systemdsystemunitdir)/local-fs.target.wants/tmp.mount
