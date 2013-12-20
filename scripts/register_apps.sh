#!/bin/sh

PACKSRC=`pwd`

for i in `ls ${PACKSRC}/whm/config/addon_cgpnewsletter*.conf`; do
    /usr/local/cpanel/bin/register_appconfig "$i";
done;