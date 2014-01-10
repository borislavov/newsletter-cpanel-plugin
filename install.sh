#!/bin/bash

PACKSRC=`pwd`

# WHM

# Install the WHM plugins
cp -rf ${PACKSRC}/whm/cgi/* /usr/local/cpanel/whostmgr/docroot/cgi/
cp ${PACKSRC}/whm/templates/* /usr/local/cpanel/whostmgr/docroot/templates/

if [ -f /usr/local/cpanel/bin/register_appconfig ]
then
    chmod +x ${PACKSRC}/scripts/register_apps.sh
    ${PACKSRC}/scripts/register_apps.sh
fi

# Check the scripts have executable flag
chmod +x /usr/local/cpanel/whostmgr/docroot/cgi/addon_cgpnewsletter*

# cPanel

# Install cPanel CommuniGate Custom Module
cp ${PACKSRC}/module/CGPNewsletter.pm /usr/local/cpanel/Cpanel/

# cPanel Wrapper
cp -r ${PACKSRC}/admin/CGPNewsletter/ /usr/local/cpanel/bin/admin/
chmod +x /usr/local/cpanel/bin/admin/CGPNewsletter/cca

# addon features
cp ${PACKSRC}/featurelists/cgpnewsletter /usr/local/cpanel/whostmgr/addonfeatures/


# Install CommuniGate Plugin
BASEDIR='/usr/local/cpanel/base/frontend';
SAVEIFS=$IFS
IFS=$(echo -en "\n\b")
THEMES=($(find ${BASEDIR} -maxdepth 1 -mindepth 1 -type d))
IFS=$OLDIFS

tLen=${#THEMES[@]}

LOCALES=($(find ${PACKSRC}/locale -maxdepth 1 -mindepth 1))
lLen=${#LOCALES[@]}

for (( i=0; i<${tLen}; i++ ));
do
    cp -r "${PACKSRC}/theme/cgpnewsletter" "${THEMES[$i]}/"
    cp "${PACKSRC}/icons/"* "${THEMES[$i]}/branding"
    cp "${PACKSRC}/plugin/dynamicui_cgpnewletter.conf" "${THEMES[$i]}/dynamicui/"

    for ((j=0; j<${lLen}; j++)); do
        TARGET=${THEMES[$i]}/locale/`basename ${LOCALES[$j]} '{}'`.yaml.local
        if [ ! -f ${TARGET} ]
        then
            echo "---" > ${TARGET}
        else
            sed -i -e '/^CGN/d' ${TARGET}
        fi
	echo >> ${TARGET}
        cat ${LOCALES[$j]} >> ${TARGET}
    done
done

/usr/local/cpanel/bin/rebuild_sprites
/usr/local/cpanel/bin/build_locale_databases
