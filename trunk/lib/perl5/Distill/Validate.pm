package Distill::Validate;

use warnings;
use strict;
use JSON;
use base qw(Exporter);
use Distill::Hash qw( :DEFAULT);
use Distill::Global qw( :DEFAULT );
use Distill::Logging qw( :DEFAULT );

our @EXPORT = qw( validate $DEBUG $LOGFILE );

sub validate($) {
    my ( $input_ref ) = @_;

    foreach my $conf ( grep /^regex\./, keys %CONF ) {
        my $regex = $CONF{$conf};
        my ( $dummy, $field ) = split /\./, $conf, 2;

        if ( !defined $input_ref->{$field} ) {
            error "Required field isn't set: $field";
        } elsif ( !eval( "'$input_ref->{$field}' =~ /$regex/" ) ) {
            error "Field: $field with value: $input_ref->{$field} doesn't match regex: $regex";
        } else {
            $DEBUG and info "Field: $field with value: $input_ref->{$field} matches regex: $regex";
        }
    }

    return TRUE;
}

1;
