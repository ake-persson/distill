package Distill::Hash;

use warnings;
use strict;
use base qw(Exporter);

our @EXPORT = qw( merge );

sub merge {
    my %result;

    if   ( !%{ $_[0] } ) {%result = ()}
    else                 {%result = %{ $_[0] }}
    shift;

    foreach my $ref ( @_ ) {
        for my $key ( keys %{$ref} ) {
            if ( defined $ref->{$key} ) {
                $result{$key} = $ref->{$key};
            }
        }
    }

    return %result;
}

1;
