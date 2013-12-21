package Cpanel::CommuniGate;

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
							'namespace' => 'CGPNewslettter',
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
	$CLI = $cli;
	return $cli;
    }
}

sub api2_AddAccount {
	my %OPTS = @_;
	# my @domains = Cpanel::Email::listmaildomains();
	# my $cli = getCLI();
	# my @result;
	# my $data = Cpanel::CachedDataStore::fetch_ref( '/var/cpanel/cgpro/classes.yaml' ) || {};

	# my $return_accounts = {};
	# my $freeExtensions = {};
	# foreach my $domain (@domains) {
	#     my $accounts=$cli->ListAccounts($domain);
	#     foreach my $userName (sort keys %$accounts) {	
	# 	next if $userName eq 'pbx' || $userName eq 'ivr';
	# 	my $accountData = $cli->GetAccountEffectiveSettings("$userName\@$domain");
	# 	my $accountStats = $cli->GetAccountStat("$userName\@$domain");
	# 	my $service = @$accountData{'ServiceClass'} || '';
	# 	my $accountPrefs = $cli->GetAccountEffectivePrefs("$userName\@$domain");
	# 	my $diskquota = @$accountData{'MaxAccountSize'} || '';
	# 	$diskquota =~ s/M//g;
	# 	my $_diskused = $cli->GetAccountInfo("$userName\@$domain","StorageUsed");
	# 	my $diskused = $_diskused / 1024 /1024;
	# 	my $diskusedpercent;
	# 	if ($diskquota eq "unlimited") {
	# 	    $diskusedpercent = 0;
	# 	} else {
	# 	    $diskusedpercent = $diskused / $diskquota * 100;
	# 	}
	# 	$return_accounts->{$userName . "@" . $domain} = {
	# 	    domain => $domain,
	# 	    username => $userName,
	# 	    class => $service,
	# 	    quota => $diskquota,
	# 	    used => $diskused,
	# 	    data => $accountData,
	# 	    prefs => $accountPrefs,
	# 	    usedpercent => $diskusedpercent,
	# 	    stats => $accountStats,
	# 	    md5 => md5_hex(lc $userName . "@" . $domain),
	# 	};
	#     }
	#     my $forwarders = $cli->ListForwarders($domain);
	#     for my $forwarder (@$forwarders) {
	# 	if ($forwarder =~ m/^tn\-\d+/) {
	# 	    my $to = $cli->GetForwarder("$forwarder\@$domain");
	# 	    $freeExtensions->{$domain} = [] unless $freeExtensions->{$domain};
	# 	    push @{$freeExtensions->{$domain}}, $forwarder if $to eq 'null';
	# 	    $return_accounts->{$to}->{extension} = $forwarder if $to ne 'null' && defined $return_accounts->{$to};
	# 	}
	# 	if ($forwarder =~ m/^\d{3}$/) {
	# 	    my $to = $cli->GetForwarder("$forwarder\@$domain");
	# 	    $return_accounts->{$to}->{local_extension} = $forwarder if defined $return_accounts->{$to};
	# 	}
	#     }
	# }
	# my $defaults = $cli->GetServerAccountDefaults();
	# $cli->Logout();
	# return { accounts => $return_accounts,
	# 	 classes => $defaults->{'ServiceClasses'},
	# 	 freeExtensions => $freeExtensions,
	# 	 data => $data,
	# 	 sort_keys_by => sub {
	# 	     my $hash = shift;
	# 	     my $sort_field = shift;
	# 	     my $reverse = shift;
	# 	     $sort_field = 'username' if $sort_field !~ /^\w+$/;
	# 	     return sort { $hash->{$b}->{$sort_field} cmp $hash->{$a}->{$sort_field} || $hash->{$b}->{'username'} cmp $hash->{$a}->{'username'} || $hash->{$b}->{'domain'} cmp $hash->{$a}->{'domain'}} keys %$hash if $reverse == 1;
	# 	     return sort { $hash->{$a}->{$sort_field} cmp $hash->{$b}->{$sort_field} || $hash->{$a}->{'username'} cmp $hash->{$b}->{'username'} || $hash->{$a}->{'domain'} cmp $hash->{$b}->{'domain'}} keys %$hash;
	# 	 }
	# };
}


sub api2 {
    my $func = shift;
    my (%API);
    $API{'AddAccount'} = {};
    return ( \%{ $API{$func} } );
}

1;
