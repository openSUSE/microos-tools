#
# locale-check.sh: Verify that the locale SSH did set is valid,
#                  else reset to the system default.
#

# Only check locale if it did got set by SSH
test -z "$SSH_SENDS_LOCALE" && return

_SYSTEM_DEFAULT_LANG=C.UTF-8
if [ -s /etc/locale.conf ]; then
    eval "$(sed -rn -e 's/^(LANG)=/_SYSTEM_DEFAULT_\1=/p' < /etc/locale.conf)"
fi
# Make sure the locale variables are set to valid values.
eval "$(/usr/bin/locale-check ${_SYSTEM_DEFAULT_LANG})"
