#!/bin/bash

PACKSRC=`pwd`

# Install CLI
if [ ! -f /usr/local/cpanel/perl/CLI.pm ]
then
# Lets add CGPro perl lib
    wget -O /usr/local/cpanel/perl/CLI.pm "https://raw2.github.com/communigate/communigate-cpanel-adaptor/v3.0.2-1/library/CLI.pm"
    ln -s /usr/local/cpanel/perl/CLI.pm /usr/local/cpanel
    PERL_VERSION=`perl -v | grep 'This is perl' | perl -pe 's/^.*?v(\d+\.\d+\.\d+).*?$/$1/g'`
    MY_PERL_PATHS="/usr/local/lib/perl5/$PERL_VERSION /usr/local/lib/perl/$PERL_VERSION /usr/local/share/perl/$PERL_VERSION /usr/local/share/perl5"
    DEFAULT_PERL_PATHS=`perl -e "print join ' ', @INC"`
    PERL_PATH=""
    found=
    for i in ${MY_PERL_PATHS[@]}; do
	for j in ${DEFAULT_PERL_PATHS[@]}; do
	    [[ $i == $j ]] && { PERL_PATH=$i; found=1; break; }
	done
	[[ -n $skip ]] && { break; }
    done
    if [ ! -d $PERL_PATH ]
    then
	mkdir -p $PERL_PATH
    fi
    ln -s /usr/local/cpanel/perl/CLI.pm $PERL_PATH/
fi

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

# Check the scripts have executable flag
chmod +x /usr/local/cpanel/whostmgr/docroot/cgi/addon_cgpnewsletter*

# cPanel

/usr/local/cpanel/bin/manage_hooks delete module CGPNewsletter::Hooks

# Install cPanel CommuniGate Custom Module
cp ${PACKSRC}/module/CGPNewsletter.pm /usr/local/cpanel/Cpanel/

# cPanel Wrapper
rm -rf /usr/local/cpanel/bin/admin/CGPNewsletter/
cp -r ${PACKSRC}/admin/CGPNewsletter/ /usr/local/cpanel/bin/admin/
chmod +x /usr/local/cpanel/bin/admin/CGPNewsletter/cca

# addon features
cp ${PACKSRC}/featurelists/cgpnewsletter /usr/local/cpanel/whostmgr/addonfeatures/


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
	cp -r "${PACKSRC}/theme/cgpnewsletter" "${THEMES[$i]}/"
	rm -f ${THEMES[$i]}/branding/cgpnewsletter_*
	cp "${PACKSRC}/icons/"* "${THEMES[$i]}/branding"
	cp "${PACKSRC}/plugin/dynamicui_cgpnewletter.conf" "${THEMES[$i]}/dynamicui/"

	for ((j=0; j<${lLen}; j++)); do
            TARGET=${THEMES[$i]}/locale/`basename ${LOCALES[$j]} '{}'`.yaml.local
            if [ ! -f ${TARGET} ]
            then
		echo "---" > ${TARGET}
            else
		sed -i -e '/^"*CGN/d' ${TARGET}
            fi
            if [ -f ${TARGET} ]
            then
		sed -i -e '/^$/d' ${TARGET}
		echo >> ${TARGET}
		cat ${LOCALES[$j]} >> ${TARGET}
            fi
	done
    fi
done

# Install cPanel Function hooks
if [ ! -d /var/cpanel/perl5/lib/ ]
then
    mkdir -p /var/cpanel/perl5/lib/
fi
rm -rf /var/cpanel/perl5/lib/CGPNewsletter
cp -rf ${PACKSRC}/hooks/CGPNewsletter /var/cpanel/perl5/lib/
/usr/local/cpanel/bin/manage_hooks add module CGPNewsletter::Hooks

/usr/local/cpanel/bin/rebuild_sprites
/usr/local/cpanel/bin/build_locale_databases
