# install alias if no local man is installed
if [ "$is" = 'bash' ] && ! type -P man >/dev/null; then
    alias man=man-online
fi
