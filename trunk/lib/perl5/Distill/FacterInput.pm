package Distill::FacterInput;

use warnings;
use strict;
use JSON;
use LWP;
use YAML qw(Load);
use Digest::MD5 qw(md5_hex);
use base qw(Exporter);
use POSIX qw(strftime);
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
        foreach ( split /\n/, $facter_out ) {
            my ( $key, $value ) = split / => /;
            $facts{$key} = $value;
        }

        if ( $CONF{'facter.cache'} ) { facter_cache( $input{'host'}, \%facts ) }

        foreach my $fact ( @{ $CONF{'facter.facts'} } ) {
            $input{$fact} = $facts{$fact};
        }

        $input{'puppet_environment'} = $facts{'environment'};
    } else {
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

sub facter_cache($) {
    my $host = shift;
    my $facts_ref = shift;

    my $json = JSON->new->allow_nonref;

    my $dir = "client_facts";
    my $outputdir = $CONF{'main.outputdir'};
    if ( !-d "$outputdir/$dir" )       {mkdir "$outputdir/$dir"}
    if ( !-d "$outputdir/$dir/$host" ) {mkdir "$outputdir/$dir/$host"}

    # Get last MD5 to compare
    my $md5   = '';
    my @files = glob( "$outputdir/$dir/$host/*.md5sum" );
    if ( $#files >= 0 ) {
        my $last = pop @files;

        # Cache cleanup
        my $now  = time;
        my $days = $CONF{'main.cache-keep-days'} * 24 * 60 * 60;
        foreach my $file ( @files ) {
            my $created = ( stat( $file ) )[8];
            if ( $created < ( $now - $days ) ) {
                $DEBUG and info( "Removed cache file: $file" );
                unlink $file;
                $file =~ s/\.md5sum$/\.json/;
                $DEBUG and info( "Removed cache file: $file" );
                unlink $file;
            }
        }

        open my $fhandle, '<', "$last"
          or error( "Failed to open file: $last\n$!" );
        $md5 = <$fhandle>;
        close $fhandle or error( "Failed to close file: $last\n$!" );
    }

    my $datetime    = strftime "%Y%m%d%H%M%S", localtime;
    my $json_output = $json->pretty->encode( $facts_ref );
    my $md5_output  = md5_hex( $json_output );

    # Write new cache file if the result has changed
    if ( $md5 eq $md5_output ) {return}

    # Write JSON file
    my $file = $datetime . '.json';
    open my $fhandle, '>', "$outputdir/$dir/$host/$file"
      or error( "Failed to open file: $dir/$host/$file\n$!" );
    print $fhandle $json_output
      or error( "Failed to write to file: $dir/$host/$file\n$!" );
    close $fhandle or error( "Failed to close file: $dir/$host/$file\n$!" );
    $DEBUG and info( "Wrote output to: $dir/$host/$file" );

    # Write MD5 file
    $file = $datetime . '.md5sum';
    open $fhandle, '>', "$outputdir/$dir/$host/$file"
      or error( "Failed to open file: $dir/$host/$file\n$!" );
    print $fhandle $md5_output
      or error( "Failed to write to file: $dir/$host/$file\n$!" );
    close $fhandle or error( "Failed to close file: $dir/$host/$file\n$!" );
    $DEBUG and info( "Wrote output to: $dir/$host/$file" );
}

1;
