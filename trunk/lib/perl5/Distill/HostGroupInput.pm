package Distill::HostGroupInput;

use warnings;
use strict;
use JSON;
use base qw(Exporter);
use Distill::Global qw( :DEFAULT );
use Distill::Logging qw( :DEFAULT );

our @EXPORT = qw( host_group_input $DEBUG $LOGFILE );

sub host_group_input($$) {
    my %input;
    my $basedir;
    ( $input{'host'}, $basedir ) = @_;

    my $json = JSON->new->allow_nonref;

    my $dir = 'input/host_group';
    if ( !-d "$basedir/$dir" ) {
        error( "Host Group directory doesn't exist: $dir" );
    }

    foreach my $file ( glob( "$basedir/$dir/*.json" ) ) {
        $DEBUG and info( "Parsing host group: $file" );

        open my $fhandle, '<', $file
          or error( "Failed to open file: $file\n$!" );

        local $/ = undef;
        my $content = <$fhandle>;
        close $fhandle
          or error( "Failed to close file: $file\n$!" );

        my $ref = $json->decode( $content );

        my $name = $ref->{'name'};
        foreach my $host ( @{ $ref->{'hosts'} } ) {
            if ( $input{'host'} eq $host ) {push @{ $input{'host_group'} }, $name;}
        }
        push @{ $input{'host_group_list'} }, $name;
    }

    return \%input;
}

1;
