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
		my $settings = {};
		$cli->UpdateAccountSettings($OPTS{'email'} . '@' . $domain, $settings);
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
	    }
	}
    }
    $cli->Logout();
}

sub api2 {
    my $func = shift;
    my (%API);
    $API{'AddAccount'} = {};
    $API{'ListAccounts'} = {};
    $API{'changePassword'} = {};
    $API{'editQuota'} = {};
    $API{'deleteAccount'} = {};
    return ( \%{ $API{$func} } );
}

1;
