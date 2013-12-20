#!/bin/sh

PACKSRC=`pwd`

for i in `ls /var/cpanel/apps/addon_cgpnewsletter*.conf`; do
    /usr/local/cpanel/bin/unregister_appconfig "$i";
done;