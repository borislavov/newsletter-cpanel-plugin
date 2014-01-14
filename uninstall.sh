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

# cPanel

# Install cPanel CommuniGate Custom Module
rm -f /usr/local/cpanel/Cpanel/CGPNewsletter.pm

# cPanel Wrapper
rm -rf /usr/local/cpanel/bin/admin/CGPNewsletter/

# addon features
rm -f /usr/local/cpanel/whostmgr/addonfeatures/cgpnewsletter


# Install CommuniGate Plugin
BASEDIR='/usr/local/cpanel/base/frontend';
SAVEIFS=$IFS
IFS=$(echo -en "\n\b")
THEMES=($(find ${BASEDIR} -maxdepth 1 -mindepth 1 -type d))
LOCALES=($(find ${PACKSRC}/locale -maxdepth 1 -mindepth 1))
IFS=$OLDIFS

tLen=${#THEMES[@]}
lLen=${#LOCALES[@]}

for (( i=0; i<${tLen}; i++ ));
do
    if [ -d "${THEMES[$i]}/dynamicui/" ]
    then
	rm -rf "${THEMES[$i]}/cgpnewsletter"
	rm -f ${THEMES[$i]}/branding/cgpnewsletter_*
	rm -f "${THEMES[$i]}/dynamicui/dynamicui_cgpnewletter.conf"

	for ((j=0; j<${lLen}; j++)); do
            TARGET=${THEMES[$i]}/locale/`basename ${LOCALES[$j]} '{}'`.yaml.local
            sed -i -e '/^"*CGN/d' ${TARGET}
	done
    fi
done

/usr/local/cpanel/bin/rebuild_sprites
/usr/local/cpanel/bin/build_locale_databases
