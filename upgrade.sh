#!/bin/bash

PACKSRC=`pwd`

# Install the WHM plugins (administration and groupware control)
if [ `ls /var/cpanel/apps/addon_cgpnewsletter*.conf | wc -l` -gt 0 ]
then
    chmod +x ${PACKSRC}/scripts/unregister_apps.sh
    ${PACKSRC}/scripts/unregister_apps.sh
fi
rm -f /usr/local/cpanel/whostmgr/docroot/templates/cgpnewsletter_*
rm -rf /usr/local/cpanel/whostmgr/docroot/cgi/cgpnewsletter*
cp ${PACKSRC}/whm/templates/* /usr/local/cpanel/whostmgr/docroot/templates/
cp -rf ${PACKSRC}/whm/cgi/* /usr/local/cpanel/whostmgr/docroot/cgi/
if [ -f /usr/local/cpanel/bin/register_appconfig ]
then
    chmod +x ${PACKSRC}/scripts/register_apps.sh
    ${PACKSRC}/scripts/register_apps.sh
fi
