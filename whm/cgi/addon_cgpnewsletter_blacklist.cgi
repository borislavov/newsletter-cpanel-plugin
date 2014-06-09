#!/bin/sh
 eval 'if [ -x /usr/local/cpanel/3rdparty/bin/perl ]; then exec /usr/local/cpanel/3rdparty/bin/perl -x -- $0 ${1+"$@"}; else exec /usr/bin/perl -x $0 ${1+"$@"}; fi;'
    if 0;
#!/usr/bin/perl
#WHMADDON:appname:cMailPro <strong>Newsletter Blacklist</strong>

use Cpanel::Form            ();
use Whostmgr::HTMLInterface ();
use Whostmgr::ACLS          ();
use CLI;
use Cpanel::CachedDataStore;

print "Content-type: text/html\r\n\r\n";

Whostmgr::ACLS::init_acls();
if ( !Whostmgr::ACLS::hasroot() ) {
  print "You need to be root to see the hello world example.\n";
  exit();
}

my $conf = Cpanel::CachedDataStore::fetch_ref( '/var/cpanel/cgpnewsletetr.yaml' ) || {};
my $cli = new CGP::CLI( { PeerAddr => $conf->{cgprohost},
                            PeerPort => $conf->{cgproport},
                            login => $conf->{cgprouser},
                            password => $conf->{cgpropass} } );
unless($cli) {
  print STDERR "Can't login to CGPro: ".$CGP::ERR_STRING,"\n";
   exit(0);
}

my %FORM = Cpanel::Form::parseform();
if ($FORM{'accounts'}) {
    $cli->UpdateServerAccountPrefs({"NewsletterBanned" => $FORM{'accounts'}});
}

my $prefs = $cli->GetServerAccountPrefs();
my $banned = $prefs->{"NewsletterBanned"};

Whostmgr::HTMLInterface::defheader( "cMailPro Newsletter Blacklist",'', '/cgi/addon_cgpnewsletter_blacklist.cgi' );


Cpanel::Template::process_template(
    'whostmgr',
    {
	'template_file' => 'addon_cgpnewsletter_blacklist.tmpl',
	limits => $limits,
	accounts => $banned,
	FORM => \%FORM
	},
);

1;
