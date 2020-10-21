dnl Process this file with autoconf to produce a configure script.
AC_INIT(microos-tools, 2.6)
AM_INIT_AUTOMAKE
AC_PREFIX_DEFAULT(/usr)

AC_SUBST(PACKAGE)
AC_SUBST(VERSION)

PKG_CHECK_VAR([systemdsystemunitdir], [systemd], [systemdsystemunitdir], [],
	[AC_MSG_ERROR([Could not determine value for 'systemdsystemunitdir' - is the 'systemd.pc' file installed?])])
PKG_CHECK_VAR([tmpfilesdir], [systemd], [tmpfilesdir], [],
        [AC_MSG_ERROR([Could not determine value for 'tmpfilesdir' - is the 'systemd.pc' file installed?])])
PKG_CHECK_VAR([systemdgeneratordir], [systemd], [systemdsystemgeneratordir], [],
        [AC_MSG_ERROR([Could not determine value for 'systemdsystemgeneratordir' - is the 'systemd.pc' file installed?])])
PKG_CHECK_VAR([dracutmodulesdir], [dracut], [dracutmodulesdir], [],
        [AC_MSG_ERROR([Could not determine value for 'dracutmodulesdir' - is the 'dracut.pc' file installed?])])

if test "${exec_prefix}" = "NONE"
then
  SYSCTLDIR=${prefix}/lib/sysctl.d
else
  SYSCTLDIR=${exec_prefix}/lib/sysctl.d
fi
AC_SUBST(SYSCTLDIR)

AC_PROG_CC
AC_PROG_INSTALL
AC_PROG_LN_S

AC_OUTPUT([Makefile firstboot/Makefile firstboot/MicroOS-firstboot.service \
	systemd-proxy-env/Makefile systemd-printenv/Makefile \
	systemd-tmpfs/Makefile sysctl/Makefile selinux/Makefile \
	locale-check/Makefile])
