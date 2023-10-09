AUTOMAKE_OPTIONS = 1.6 foreign check-news dist-xz

SUBDIRS = systemd-proxy-env systemd-printenv tmpfs \
	selinux devel-tools

CLEANFILES = *~

EXTRA_DIST = README.md

profile_DATA = man-online.sh
profiledir = $(prefix)$(sysconfdir)/profile.d
bin_SCRIPTS = man-online
