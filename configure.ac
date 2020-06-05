dnl Process this file with autoconf to produce a configure script.
AC_INIT(microos-tools, 2.1)
AM_INIT_AUTOMAKE
AC_PREFIX_DEFAULT(/usr)

AC_SUBST(PACKAGE)
AC_SUBST(VERSION)

PKG_CHECK_VAR([systemdsystemunitdir], [systemd], [systemdsystemunitdir], [],
	[AC_MSG_ERROR([Could not determine value for 'systemdsystemunitdir' - is the 'systemd.pc' file installed?])])

if test "${exec_prefix}" = "NONE"
then
  SYSCTLDIR=${prefix}/lib/sysctl.d
else
  SYSCTLDIR=${exec_prefix}/lib/sysctl.d
fi
AC_SUBST(SYSCTLDIR)

AC_PROG_INSTALL
AC_PROG_LN_S

AC_OUTPUT([Makefile firstboot/Makefile firstboot/MicroOS-firstboot.service \
	systemd-proxy-env/Makefile systemd-printenv/Makefile \
	systemd-tmpfs/Makefile sysctl/Makefile])
