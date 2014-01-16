package Cpanel::CGPNewsletter;

use strict;
use vars qw(@ISA @EXPORT $VERSION);
use CLI;
use Cpanel::Logger          ();
use Cpanel::Email ();
use Cpanel                           ();

require Exporter;
@ISA    = qw(Exporter);
@EXPORT = qw(CommuniGate_init );

$VERSION = '1.0';

my $logger = Cpanel::Logger->new();
my $CLI = undef;
sub CommuniGate_init {
    return 1;
}

sub getCLI {
    if ($CLI && $CLI->{isConnected}) {
	return $CLI;
    } else {
	my $loginData;
	my $version = `$^X -V`;
	$version =~ s/^\D*(\d+\.\d+).*?$/$1/;
	my $result = Cpanel::Wrap::send_cpwrapd_request(
							'namespace' => 'CGPNewsletter',
							'module'    => 'cca',
							'function'  => 'GETLOGIN',
							'data' =>  $Cpanel::CPDATA{'USER'}
						       );
	if ( defined( $result->{'data'} ) ) {
	  $loginData = $result->{'data'};
	} else {
	  $logger->warn("Can't login to CGPro: " . $result->{'error'});
	}
	my @loginData = split "::", $loginData;
 	my $cli = new CGP::CLI( { PeerAddr => $loginData[0],
				  PeerPort => $loginData[1],
				  login => $loginData[2],
				  password => $loginData[3]
				});
	unless($cli) {
	    $logger->warn("Can't login to CGPro: ".$CGP::ERR_STRING);
	}
	$cli->{'loginData'} = \@loginData;
	$CLI = $cli;
	return $cli;
    }
}

sub api2_AddAccount {
    my %OPTS = @_;
    my @domains = Cpanel::Email::listmaildomains();
    my $cli = getCLI();
    foreach my $domain (@domains) {
	if ($domain eq $OPTS{'domain'}) {
	    if ($OPTS{'quota'} == 0 || $OPTS{'quota'} eq 'unlimited') {
		$OPTS{'quota'} = "unlimited";
	    }else{
		$OPTS{'quota'} .= "M";
	    }
	    # Create the domain of does not exist
	    my $data = $cli->GetDomainSettings("$domain");
	    if (!$data) {
		$cli->CreateDomain("$domain");
	    }
	    my $UserData;
	    @$UserData{'Password'} = $OPTS{'password'};
	    @$UserData{'MaxAccountSize'} = $OPTS{'quota'};
	    my $response = $cli->CreateAccount(accountName => $OPTS{'email'} . '@' . $domain, settings => $UserData);
	    if ($response) {
		$cli->CreateMailbox($OPTS{'email'} . '@' . $domain, "Spam");
		if ( $Cpanel::CPVAR{'MaxMails'} && $Cpanel::CPVAR{'MaxPeriod'} && !$Cpanel::CPVAR{'MaxMailsDefault'}) {
		    my $settings = {
			"MailOutFlow" => [$Cpanel::CPVAR{'MaxMails'}, $Cpanel::CPVAR{'MaxPeriod'}]
		    };
		    $cli->UpdateAccountSettings($OPTS{'email'} . '@' . $domain, $settings);
		}
		update_spf("addip");
	    } else {
		my $error = $cli->getErrMessage;
		$Cpanel::CPERROR{'cgpro'} = $error;
	    }

	}
    }
    $cli->Logout();
}
sub api2_ListAccounts {
    my %OPTS = @_;
    my @domains = Cpanel::Email::listmaildomains();
    my $cli = getCLI();
    my $accounts = {};
    foreach my $domain (@domains) {
	my $domainAccounts = $cli->ListAccounts($domain);
	foreach my $userName (sort keys %$domainAccounts) {      
	    next if $userName eq 'pbx' ||  $userName eq 'ivr';
	    my $accountData = $cli->GetAccountEffectiveSettings("$userName\@$domain");
	    $accounts->{"$userName\@$domain"} = $accountData;
	    my $diskquota = @$accountData{'MaxAccountSize'} || '';
	    $diskquota =~ s/M//g;
	    $accounts->{"$userName\@$domain"}->{'quota'} = $diskquota;
	    $accounts->{"$userName\@$domain"}->{'MailOutFlow'} = $accountData->{"MailOutFlow"};
	    $accounts->{"$userName\@$domain"}->{'server'} = $cli->{'loginData'}->[0];
	    $accounts->{"$userName\@$domain"}->{'server'} = $ENV{'HTTP_HOST'} if $cli->{'loginData'}->[0] eq '0' ||  $cli->{'loginData'}->[0] =~ /^127\.0/ ||  ! $cli->{'loginData'}->[0] ||  $cli->{'loginData'}->[0] eq 'localhost';
	}
    }
    $cli->Logout();
    return {accounts => $accounts};
}

sub api2_changePassword {
    my %OPTS = @_;
    my @domains = Cpanel::Email::listmaildomains();
    my $account = $OPTS{'email'} . '@' . $OPTS{'domain'};
    my $cli = getCLI();
    foreach my $domain (@domains) {
	my $domainAccounts = $cli->ListAccounts($domain);
	foreach my $userName (sort keys %$domainAccounts) {      
	    if ($account eq "$userName\@$domain") {
		my $response = $cli->SetAccountPassword("$userName\@$domain",$OPTS{'password'},0);
		unless ($response) {
		    $Cpanel::CPERROR{'email'} = $cli->getErrMessage;
		}
		
	    }
	}
    }
    $cli->Logout();
}

sub api2_editQuota {
    my %OPTS = @_;
    my @domains = Cpanel::Email::listmaildomains();
    my $account = $OPTS{'email'} . '@' . $OPTS{'domain'};
    my $cli = getCLI();
    foreach my $domain (@domains) {
	my $domainAccounts = $cli->ListAccounts($domain);
	foreach my $userName (sort keys %$domainAccounts) {      
	    if ($account eq "$userName\@$domain") {
		my $data = $cli->GetAccountSettings("$userName\@$domain");
		if ($OPTS{'quota'} == 0 || $OPTS{'quota'} eq 'unlimited') {
		    $OPTS{'quota'} = "unlimited";
		}else{
		    $OPTS{'quota'} .= "M";
		}
		$data->{'MaxAccountSize'} = $OPTS{'quota'};
		my $response = $cli->UpdateAccountSettings("$userName\@$domain", $data);
		unless ($response) {
		    $Cpanel::CPERROR{'email'} = $cli->getErrMessage;
		}
		
	    }
	}
    }
    $cli->Logout();
}
sub api2_deleteAccount {
    my %OPTS = @_;
    my @domains = Cpanel::Email::listmaildomains();
    my $account = $OPTS{'email'} . '@' . $OPTS{'domain'};
    my $cli = getCLI();
    foreach my $domain (@domains) {
	my $domainAccounts = $cli->ListAccounts($domain);
	foreach my $userName (sort keys %$domainAccounts) {      
	    if ($account eq "$userName\@$domain") {
		my $response = $cli->DeleteAccount("$userName\@$domain");
		unless ($response) {
		    $Cpanel::CPERROR{'email'} = $cli->getErrMessage;
		}
		update_spf("delip");
		last;
	    }
	}
    }
    $cli->Logout();
}

sub api2_MailOutLimit {
    my %OPTS = @_;
    my @domains = Cpanel::Email::listmaildomains();
    my $account = $OPTS{'email'} . '@' . $OPTS{'domain'};
    my $limit = [];
    my $limits = Cpanel::CachedDataStore::fetch_ref( '/var/cpanel/cgpnewsletetr_packages.yaml');
    $limit = $limits->{$Cpanel::CPDATA{'PLAN'}} if $limits->{$Cpanel::CPDATA{'PLAN'}};
    unless ($limit->[0]) {
	my $cli = getCLI();
	my $def = $cli->GetServerAccountDefaults();
	if ($def) {$limit = $def->{'MailOutFlow'}};
	$Cpanel::CPVAR{'MaxMailsDefault'} = 1;
	$cli->Logout();
    }
    $Cpanel::CPVAR{'MaxMails'} = $limit->[0] if $limit->[0];
    $Cpanel::CPVAR{'MaxPeriod'} = $limit->[1] if $limit->[1];
}

sub api2 {
    my $func = shift;
    my (%API);
    $API{'AddAccount'} = {};
    $API{'ListAccounts'} = {};
    $API{'changePassword'} = {};
    $API{'editQuota'} = {};
    $API{'deleteAccount'} = {};
    $API{'MailOutLimit'} = {};
    return ( \%{ $API{$func} } );
}

sub update_spf {
    my $action = shift;
    my $apiref = Cpanel::Api2::Exec::api2_preexec( 'SPFUI', 'installed' );
    my ( $spf, undef ) = Cpanel::Api2::Exec::api2_exec( 'SPFUI', 'installed', $apiref );
    if ($spf->[0]->{installed}) {
	# Rebuild Form Data
	$Cpanel::FORM{'overwrite'} = 1;
	$Cpanel::FORM{'faction'} = "install";
	# $Cpanel::FORM{'spf_ip4_hosts'} = "77.77.150.13";
	# # SPFUI::load_current_values(%,status)
	$apiref = Cpanel::Api2::Exec::api2_preexec( 'SPFUI', 'load_current_values' );
	my ( undef, undef) = Cpanel::Api2::Exec::api2_exec( 'SPFUI', 'load_current_values', $apiref);
	# SPFUI::list_settings()
	$apiref = Cpanel::Api2::Exec::api2_preexec( 'SPFUI', 'list_settings' );
	my ( $a, undef) = Cpanel::Api2::Exec::api2_exec( 'SPFUI', 'list_settings', $apiref, {settings => 'a_hosts'} );
	for (my $i = 0; $i < scalar @{ $a }; $i++) {
	    $Cpanel::FORM{'spf_a_hosts-' . $i} = $a->[$i]->{opt};
	}
	my ( $mx, undef) = Cpanel::Api2::Exec::api2_exec( 'SPFUI', 'list_settings', $apiref, {settings => 'mx_hosts'} );
	for (my $i = 0; $i < scalar @{ $mx }; $i++) {
	    $Cpanel::FORM{'spf_mx_hosts-' . $i} = $mx->[$i]->{opt};
	}
	my ( $include, undef) = Cpanel::Api2::Exec::api2_exec( 'SPFUI', 'list_settings', $apiref, {settings => 'include_hosts'} );
	for (my $i = 0; $i < scalar @{ $include }; $i++) {
	    $Cpanel::FORM{'spf_include_hosts-' . $i} = $include->[$i]->{opt};
	}
	# SPFUI::entries_complete()
	$apiref = Cpanel::Api2::Exec::api2_preexec( 'SPFUI', 'entries_complete' );
	my ( $complete, undef) = Cpanel::Api2::Exec::api2_exec( 'SPFUI', 'entries_complete', $apiref);
	$Cpanel::FORM{'entries_complete'} = $complete->[0]->{'complete'};
	my $server_ip = "";
	# Add CGPro server to ip4
	my $cli = getCLI();
	if ($cli->{loginData}->[0] =~ /^\d+\.\d+\.\d+\.\d+\/?\d*$/) {
	    $server_ip = $cli->{loginData}->[0];
	} elsif ($cli->{loginData}->[0] =~ /^[\w\.\-]+$/) {
	    $apiref = Cpanel::Api2::Exec::api2_preexec( 'DnsLookup', 'name2ip' );
	    my ( $ip, undef) = Cpanel::Api2::Exec::api2_exec( 'DnsLookup', 'name2ip', $apiref, {domain => $cli->{loginData}->[0]});
	    if  ($ip->[0]->{status} == 1) {
		$server_ip = $ip->[0]->{ip};
	    }
	}
	if ($action eq "addip") {
	    $Cpanel::FORM{'spf_ip4_hosts'} = $server_ip;
	}
	my ( $ip4, undef) = Cpanel::Api2::Exec::api2_exec( 'SPFUI', 'list_settings', $apiref, {settings => 'ip4_hosts'} );
	for (my $i = 0; $i < scalar @{ $ip4 }; $i++) {
	    next if $action eq "delip" && $server_ip eq $ip4->[$i]->{opt};
	    $Cpanel::FORM{'spf_ip4_hosts-' . $i} = $ip4->[$i]->{opt};
	}
	# Apply Changes
	$apiref = Cpanel::Api2::Exec::api2_preexec( 'SPFUI', 'install' );
	my @result = Cpanel::Api2::Exec::api2_exec( 'SPFUI', 'install', $apiref, {entries_complete => $complete->[0]->{'complete'}, hooked => 1} );
    }
}

1;
