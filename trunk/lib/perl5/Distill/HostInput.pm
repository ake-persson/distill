package Distill::HostInput;

use warnings;
use strict;
use JSON;
use base qw(Exporter);
use Distill::Global qw( :DEFAULT );
use Distill::Logging qw( :DEFAULT );

our @EXPORT = qw( host_input $DEBUG $LOGFILE );

sub host_input($$) {
    my %input;
    my $basedir;
    ( $input{'host'}, $basedir ) = @_;

    my $json = JSON->new->allow_nonref;

    my $dir = 'input/host';
    if ( !-d "$basedir/$dir" ) {
        error( "Host directory doesn't exist: $dir" );
    }

    my $file = "$input{'host'}.json";

    if ( !-f "$basedir/$dir/$file" ) {
        $DEBUG and warn( "Host input doesn't exist: $dir/$file" );
        return \%input;
    }

    $DEBUG and info( "Parsing host input: $file" );

    open my $fhandle, '<', "$basedir/$dir/$file"
      or error( "Failed to open file: $basedir/$dir/$file\n$!" );

    local $/ = undef;
    my $content = <$fhandle>;
    close $fhandle
      or error( "Failed to close file: $file\n$!" );

    my $ref = $json->decode( $content );

    foreach my $key ( keys %{$ref} ) {
        $input{$key} = ${$ref}{$key};
    }

    return \%input;
}

1;
