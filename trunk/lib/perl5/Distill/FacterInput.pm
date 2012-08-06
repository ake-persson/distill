package Distill::FacterInput;

use warnings;
use strict;
use JSON;
use LWP;
use YAML qw(Load);
use base qw(Exporter);
use Distill::Global qw( :DEFAULT );
use Distill::Logging qw( :DEFAULT );

our @EXPORT = qw( facter_input );

sub facter_input($) {
    my %input;
    $input{'host'} = shift;

    my $browser = LWP::UserAgent->new;
    $browser->timeout( $CONF{'main.puppet-timeout'} );
    $browser->default_header( 'Accept' => 'yaml' );

    # May need the client's proper environment in the future, currently the Puppet REST API doesn't care
    my $url      = "https://$CONF{'main.puppet-server'}:8140/production/facts/$input{'host'}";
    my $response = $browser->get( $url );
    if ( !$response->is_success ) {
        error( "Unable to get url: $url -- " . $response->status_line );
    }

    my $ref = Load( $response->content . "\n" );

    foreach my $fact ( @{ $CONF{'facter.facts'} } ) {
        $input{$fact} = $ref->{'values'}{$fact};
    }

    $input{'puppet_environment'} = $ref->{'values'}{'environment'};

    return \%input;
}

1;
