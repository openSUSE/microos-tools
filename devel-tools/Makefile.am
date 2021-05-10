systemddir = $(systemdsystemunitdir)

systemd_DATA = microos-ro.service
sbin_SCRIPTS = microos-rw microos-ro rpm-sortbysize
sbin_PROGRAMS = rpmorphan

rpmorphan_LDADD = $(RPM_LIBS)
rpmorphan_CFLAGS = $(RPM_CFLAGS)

EXTRA_DIST = $(SCRIPTS) $(DATA)
