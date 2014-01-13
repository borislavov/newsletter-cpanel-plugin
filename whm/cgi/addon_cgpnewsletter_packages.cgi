#!/bin/sh
 eval 'if [ -x /usr/local/cpanel/3rdparty/bin/perl ]; then exec /usr/local/cpanel/3rdparty/bin/perl -x -- $0 ${1+"$@"}; else exec /usr/bin/perl -x $0 ${1+"$@"}; fi;'
    if 0;
#!/usr/bin/perl
#WHMADDON:appname:cMailPro <strong>Newsletter Packages</strong>

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

my %FORM = Cpanel::Form::parseform();
Whostmgr::HTMLInterface::defheader( "cMailPro Newsletter Packages",'', '/cgi/addon_cgpnewsletter_packages.cgi' );

my $limits = Cpanel::CachedDataStore::fetch_ref( '/var/cpanel/cgpnewsletetr_packages.yaml');
if ($FORM{'submit'}) {
    for my $i (0 .. 9999) {
	last unless $FORM{'pkg-' . $i};
	my $pkg = $FORM{'pkg-' . $i};
	if ($FORM{'emails-' . $pkg} && $FORM{'period-' . $pkg}) {
	    $limits->{$pkg} = [$FORM{'emails-' . $pkg}, $FORM{'period-' . $pkg}];
	} else {
	    delete $limits->{$pkg} if $limits->{$pkg};
	}
    }
    Cpanel::CachedDataStore::store_ref( '/var/cpanel/cgpnewsletetr_packages.yaml', $limits );
    $limits = Cpanel::CachedDataStore::fetch_ref( '/var/cpanel/cgpnewsletetr_packages.yaml');
}

Cpanel::Template::process_template(
    'whostmgr',
    {
	'template_file' => 'addon_cgpnewsletter_packages.tmpl',
	limits => $limits,
	FORM => \%FORM
	},
);

1;
