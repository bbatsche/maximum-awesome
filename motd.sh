#!/bin/sh

PATH="$PATH:/usr/bin:/usr/sbin"

sysprofile=`system_profiler SPSoftwareDataType | sed -n "s/^[ \t\v\f]*System Version: \(.*$\)/\1/p;\
                    s/^[ \t\v\f]*Computer Name: \(.*\)$/\1/p"`
welcome="Welcome to "
name=`printf "$sysprofile" | sed -n '2p'`
running=" running "
os=`printf "$sysprofile" | sed -n '1p'`
echo "$welcome$name$running$os" > /etc/motd

exit 0
