package Distill::Transform;

use warnings;
use strict;
use JSON;
use base qw(Exporter);
use Storable qw(dclone);
use Distill::Hash qw( :DEFAULT);
use Distill::Global qw( :DEFAULT );
use Distill::Logging qw( :DEFAULT );

our @EXPORT = qw( transform $DEBUG $LOGFILE );

sub transform($$$) {
    my ( $basedir, $input_ref, $sequence_ref ) = @_;

    my $json = JSON->new->allow_nonref;

    my %output = %{$input_ref};
    undef my %immutable;
    foreach my $templ ( @{$sequence_ref} ) {
        foreach my $templ_type ( ( 'shared', 'staged' ) ) {

            undef my @values;
            if ( ref( $input_ref->{$templ} ) eq 'ARRAY' ) {
                @values = @{ $input_ref->{$templ} };
            } else {
                push @values, $input_ref->{$templ};
            }

            foreach my $value ( @values ) {

                my $dir  = "template/$templ_type/$templ";
                my $file = lc( $value ) . ".json";
                $file =~ s/\s/_/g;
                $file =~ s/\//-/g;

                if ( !-d "$basedir/$dir" ) {
                    error( "Template directory doesn't exist: $dir" );
                }
                if ( !-f "$basedir/$dir/$file" ) {
                    $DEBUG and warn( "Template doesn't exist: $dir/$file" );
                    next;
                }

                $DEBUG and info( "Parsing template: $dir/$file" );

                open my $fhandle, '<', "$basedir/$dir/$file"
                  or error( "Failed to open file: $dir/$file\n$!" );

                local $/ = undef;
                my $content = <$fhandle>;
                close $fhandle
                  or error( "Failed to close file: $dir/$file\n$!" );

                my $ref = $json->decode( $content );

# Refactor code
                foreach my $key ( keys %{$ref} ) {
                    if ( exists $immutable{$key} ) {
                        $DEBUG and info2( "Ignoring key since it's immutable: $1" );
                        next;
                    } elsif ( $key =~ /^!:(.*)/ ) {
                        delete $output{$1};
                        $DEBUG and warn( "Operator !: is deprecated, please use u:" );
                        $DEBUG and info2( "Unsetting key: $1" );
                    } elsif ( $key =~ /^u:(.*)/ && ref( ${$ref}{$key} ) ne 'ARRAY' && ref( ${$ref}{$key} ) ne 'HASH' ) {
                        delete $output{$1};
                        $DEBUG and info2( "Unsetting key: $1" );
                    } elsif ( $key =~ /^u:(.*)/ && ref( ${$ref}{$key} ) eq 'ARRAY' ) {
                        foreach my $value ( @{ ${$ref}{$key} } ) {
                            @{ $output{$1} } = grep {$_ ne $value} @{ $output{$1} };
                        }
                        $DEBUG and info2( "Unsetting array items in key: $1" );
                    } elsif ( $key =~ /^u:(.*)/ && ref( ${$ref}{$key} ) eq 'HASH' ) {
                        foreach my $subkey ( keys %{ ${$ref}{$key} } ) {
                            delete ${ $output{$1} }{$subkey};
                        }
                        $DEBUG and info2( "Unsetting hash items in key: $1" );
                    } elsif ( $key =~ /^iu:(.*)/ && ref( ${$ref}{$key} ) ne 'ARRAY' && ref( ${$ref}{$key} ) ne 'HASH' ) {
                        $immutable{$1} = TRUE;
                        delete $output{$1};
                        $DEBUG and info2( "Immutable and unsetting key: $1" );
                    } elsif ( $key =~ /^iu:(.*)/ && ref( ${$ref}{$key} ) eq 'ARRAY' ) {
                        $immutable{$1} = TRUE;
                        foreach my $value ( @{ ${$ref}{$key} } ) {
                            @{ $output{$1} } = grep {$_ ne $value} @{ $output{$1} };
                        }
                        $DEBUG and info2( "Immutable and unsetting array items in key: $1" );
                    } elsif ( $key =~ /^iu:(.*)/ && ref( ${$ref}{$key} ) eq 'HASH' ) {
                        $immutable{$1} = TRUE;
                        foreach my $subkey ( keys %{ ${$ref}{$key} } ) {
                            delete ${ $output{$1} }{$subkey};
                        }
                        $DEBUG and info2( "Immutable and unsetting hash items in key: $1" );
                    } elsif ( $key =~ /^i:(.*)/ ) {
                        $immutable{$1} = TRUE;
                        $output{$1}    = ${$ref}{$key};
                        $DEBUG and info2( "Immutable and substituting key: $1" );
                    } elsif ( $key =~ /^m:(.*)/ && ref( ${$ref}{$key} ) eq 'ARRAY' ) {
                        push @{ $output{$1} }, @{ ${$ref}{$key} };
                        $DEBUG and info2( "Merging array key: $1" );
                    } elsif ( $key =~ /^m:(.*)/ && ref( ${$ref}{$key} ) eq 'HASH' ) {
                        %{ $output{$1} } = merge( $output{$1}, ${$ref}{$key} );
                        $DEBUG and info2( "Merging hash key: $1" );
                    } elsif ( $key =~ /^im:(.*)/ && ref( ${$ref}{$key} ) eq 'ARRAY' ) {
                        $immutable{$1} = TRUE;
                        push @{ $output{$1} }, @{ ${$ref}{$key} };
                        $DEBUG and info2( "Immutable and merging array key: $1" );
                    } elsif ( $key =~ /^im:(.*)/ && ref( ${$ref}{$key} ) eq 'HASH' ) {
                        $immutable{$1} = TRUE;
                        %{ $output{$1} } = merge( $output{$1}, ${$ref}{$key} );
                        $DEBUG and info2( "Immutable and merging hash key: $1" );
                    } elsif ( $key =~ /^e:(.*)/ ) {
                        $output{$1} = $output{ ${$ref}{$key} };
                        $DEBUG and warn( "Operator e: is deprecated, please use r:" );
                        $DEBUG and info2( "Expand variable into key: $1" );
                    } elsif ( $key =~ /^ie:(.*)/ ) {
                        $immutable{$1} = TRUE;
                        $output{$1} = $output{ ${$ref}{$key} };
                        $DEBUG and warn( "Operator ie: is deprecated, please use ir:" );
                        $DEBUG and info2( "Immutable and expand variable into key: $1" );
                    } elsif ( $key =~ /^r:(.*)/ ) {
                        $output{$1} = $output{ ${$ref}{$key} };
                        $DEBUG and info2( "Reference variable for key: $1" );
                    } elsif ( $key =~ /^ir:(.*)/ ) {
                        $immutable{$1} = TRUE;
                        $output{$1} = $output{ ${$ref}{$key} };
                        $DEBUG and info2( "Immutable and reference variable for key: $1" );
                    } elsif ( $key =~ /^c:(.*)/ ) {
                        $output{$1} = dclone($output{ ${$ref}{$key} });
                        $DEBUG and info2( "Copy variable into key: $1" );
                    } elsif ( $key =~ /^ic:(.*)/ ) {
                        $immutable{$1} = TRUE;
                        $output{$1} = dclone($output{ ${$ref}{$key} });
                        $DEBUG and info2( "Immutable and copy variable into key: $1" );
                    } else {
                        $output{$key} = ${$ref}{$key};
                        $DEBUG and info2( "Substituting key: $key" );
                    }
                }
            }
        }
    }

    return \%output;
}

1;
