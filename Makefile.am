AUTOMAKE_OPTIONS = 1.6 foreign check-news dist-xz

SUBDIRS = systemd-printenv tmpfs selinux devel-tools import-pubring \
	  zypp-single-rpmtrans zypp-configs

CLEANFILES = *~

EXTRA_DIST = README.md

profile_DATA = man-online.sh
profiledir = $(prefix)$(sysconfdir)/profile.d
bin_SCRIPTS = man-online
