#!/bin/bash

PACKSRC=`pwd`

# Uninstall the WHM plugins (administration and groupware control)
if [ `ls /var/cpanel/apps/addon_cgpnewsletter*.conf | wc -l` -gt 0 ]
then
    chmod +x ${PACKSRC}/scripts/unregister_apps.sh
    ${PACKSRC}/scripts/unregister_apps.sh
fi

rm -rf /usr/local/cpanel/whostmgr/docroot/cgi/addon_cgpnewsletter*
rm -f /usr/local/cpanel/whostmgr/docroot/templates/addon_cgpnewsletter_*


