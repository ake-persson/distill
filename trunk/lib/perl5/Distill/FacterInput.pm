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

    # Check for empty hash value
    if ( $CONF{'facter.query-local'} ) {
        my $facter_out = `facter -p 2>&1`;
        if ( $? != 0 ) {
            error "Failed to run Facter:\n$facter_out";
        }

# MAY POLUTE OUTPUT WITH ERROR'S

        my %facts;
        foreach(split /\n/, $facter_out) {
            my ($key, $value) = split / => /;
            $facts{$key} = $value;
        }

        foreach my $fact ( @{ $CONF{'facter.facts'} } ) {
            $input{$fact} = $facts{$fact};
        }

        $input{'puppet_environment'} = $facts{'environment'};
    }
    else {
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
    }

    if ( $CONF{'facter.use-host-group'} && defined $input{ $CONF{'facter.host-group'} } ) {
        foreach my $host_group ( split /,/, $input{ $CONF{'facter.host-group'} } ) {
            push @{ $input{'facter_host_group'} }, $host_group;
        }
    }

    foreach my $facter ( @{ $CONF{'facter.convert-to-array'} } ) {
        my @values;
        if ( defined $input{$facter} ) {
            @values = split ',', $input{$facter};
        } else {
            @values = ();
        }
        $input{$facter} = \@values;
    }

    return \%input;
}

1;
