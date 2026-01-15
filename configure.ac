dnl Process this file with autoconf to produce a configure script.
AC_INIT([microos-tools], [4.0])
AM_INIT_AUTOMAKE
AC_PREFIX_DEFAULT(/usr)

AC_SUBST(PACKAGE)
AC_SUBST(VERSION)

PKG_CHECK_VAR([systemdutildir], [systemd], [systemdutildir], [],
        [AC_MSG_ERROR([Could not determine value for 'systemdutildir' - is the 'systemd.pc' file installed?])])
PKG_CHECK_VAR([systemdsystemunitdir], [systemd], [systemdsystemunitdir], [],
	[AC_MSG_ERROR([Could not determine value for 'systemdsystemunitdir' - is the 'systemd.pc' file installed?])])
PKG_CHECK_VAR([tmpfilesdir], [systemd], [tmpfilesdir], [],
        [AC_MSG_ERROR([Could not determine value for 'tmpfilesdir' - is the 'systemd.pc' file installed?])])
PKG_CHECK_VAR([systemdgeneratordir], [systemd], [systemdsystemgeneratordir], [],
        [AC_MSG_ERROR([Could not determine value for 'systemdsystemgeneratordir' - is the 'systemd.pc' file installed?])])
PKG_CHECK_VAR([dracutmodulesdir], [dracut], [dracutmodulesdir], [],
        [AC_MSG_ERROR([Could not determine value for 'dracutmodulesdir' - is the 'dracut.pc' file installed?])])
PKG_CHECK_MODULES([RPM], [rpm])

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

AC_CONFIG_FILES([Makefile systemd-printenv/Makefile \
	tmpfs/Makefile selinux/Makefile \
	import-pubring/Makefile \
	zypp-single-rpmtrans/Makefile \
	zypp-configs/Makefile \
	devel-tools/Makefile])
AC_OUTPUT
