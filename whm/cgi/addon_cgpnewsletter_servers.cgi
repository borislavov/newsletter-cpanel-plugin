#!/bin/sh
 eval 'if [ -x /usr/local/cpanel/3rdparty/bin/perl ]; then exec /usr/local/cpanel/3rdparty/bin/perl -x -- $0 ${1+"$@"}; else exec /usr/bin/perl -x $0 ${1+"$@"}; fi;'
    if 0;
#!/usr/bin/perl
#WHMADDON:appname:cMailPro <strong>Newsletter Servers</strong>

use Cpanel::Form            ();
use Whostmgr::HTMLInterface ();
use Whostmgr::ACLS          ();
use Cpanel::CachedDataStore;

print "Content-type: text/html\r\n\r\n";

Whostmgr::ACLS::init_acls();
if ( !Whostmgr::ACLS::hasroot() ) {
  print "You need to be root to see the hello world example.\n";
  exit();
}

my $conf = Cpanel::CachedDataStore::fetch_ref( '/var/cpanel/cgpnewsletetr.yaml' ) || {};

my %FORM = Cpanel::Form::parseform();
Whostmgr::HTMLInterface::defheader( "cMailPro Newsletter Servers",'', '/cgi/addon_cgpnewsletter_servers.cgi' );

Cpanel::Template::process_template(
    'whostmgr',
    {
	'template_file' => 'addon_cgpnewsletter_servers.tmpl',
	conf => $conf,
	FORM => \%FORM
	},
);

1;
