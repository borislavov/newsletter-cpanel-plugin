package CGPNewsletter::Hooks;

use CLI;
use Cpanel::Logger ();
use Cpanel::AdminBin ();
use Cpanel::Api2::Exec ();
use Cpanel::CachedDataStore ();
use Cpanel::Config::LoadUserDomains ();

sub describe {
    my $install_spf = {
        'category' => 'Cpanel',
        'event'    => 'Api2::SPFUI::install',
        'stage'    => 'post',
        'hook'     => 'CGPNewsletter::Hooks::install_spf',
        'exectype' => 'module',
    };
    return [
	$install_spf,
	];
}

sub install_spf {
    my (undef, $params) = @_;
    my $args = $params->{args};
    unless ($args->{hooked}) {
	update_spf("addip");
    }
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

sub update_spf {
    my $action = shift;
    my @domains = Cpanel::Email::listmaildomains(); 
    my $cli = getCLI();
    my $found = 0;
    for my $domain (@domains) {
	$accounts = $cli->ListAccounts($domain);
	if (scalar keys %$accounts) {
	    $found = 1;
	    last;
	}
    }
    if ($found) {
	# Rebuild Form Data
	$Cpanel::FORM{'overwrite'} = 1;
	$Cpanel::FORM{'faction'} = "install";
	# $Cpanel::FORM{'spf_ip4_hosts'} = "77.77.150.13";
	# # SPFUI::load_current_values(%,status)
	my $apiref = Cpanel::Api2::Exec::api2_preexec( 'SPFUI', 'load_current_values' );
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
	$cli->Logout();
    }
}


1;
