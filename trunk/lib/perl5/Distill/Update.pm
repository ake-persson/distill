package Distill::Update;

use warnings;
use strict;
use JSON;
use base qw(Exporter);
use Sys::Hostname;
use POSIX qw(strftime);
use Digest::MD5 qw(md5_hex);
use File::Basename;
use Distill::Global qw( :DEFAULT );
use Distill::Hash qw( :DEFAULT );
use Distill::Logging qw( :DEFAULT );
use Distill::FacterInput qw( :DEFAULT );

#use Distill::DdbSaInput qw( :DEFAULT );
use Distill::HostInput qw( :DEFAULT );
use Distill::HostGroupInput qw( :DEFAULT );
use Distill::Validate qw( :DEFAULT );
use Distill::Transform qw( :DEFAULT );

our @EXPORT = qw( update clean_cache );

sub update($$$$) {
    my ( $host, $basedir, $outputdir, $sequence_ref ) = @_;

    my $json = JSON->new->allow_nonref;

    my %input;
    my $facter_ref;
    my $input_ref;

    $facter_ref = facter_input( $host );
    my $distill_environment = $CONF{'main.environment'};
    my $puppet_environment  = $facter_ref->{'puppet_environment'};
    if ( $CONF{'main.override-environment'} ) {
        $distill_environment = $puppet_environment;
        $DEBUG and info( "Overriding environment using Puppet facts: $distill_environment" );

        # Override main options from environment
        foreach ( keys %CONF ) {
            my ( $section, $key ) = split /\./;
            if ( $section eq $distill_environment ) {
                $CONF{"main.$key"} = $CONF{"$distill_environment.$key"};
                $DEBUG and info( "Overriding main.$key based on environment: $distill_environment" );

                if ( $key eq 'basedir' ) {
                    $basedir = $CONF{'main.basedir'};
                    if ( !-d $basedir ) {error( "Base directory doesn't exist: " . $basedir )}
                    $DEBUG and info( "Using base directory: " . $basedir );
                }

                if ( $key eq 'sequence' ) {
                    $sequence_ref = $CONF{'main.sequence'};
                    $DEBUG and info( "Substitution sequence: " . join ',', @{ $CONF{'main.sequence'} } );
                }

                if ( $key eq 'outputdir' ) {
                    $outputdir = $CONF{'main.outputdir'};
                    if ( !-d $outputdir ) {error( "Output directory doesn't exist: " . $outputdir )}
                    $DEBUG and info( "Using output directory: " . $outputdir );
                }
            }
        }
    }

 #    %input =
 #      merge( $facter_ref, ddb_sa_input( $host ), host_input( $host, $basedir ), host_group_input( $host, $basedir ) );
    %input =
      merge( $facter_ref, host_input( $host, $basedir ), host_group_input( $host, $basedir ) );
    $input{'default'}             = 'default';
    $input{'distill_server'}      = hostname;
    $input{'distill_environment'} = $distill_environment;

    # Merge Facter and Distill host groups
    my %host_groups = map {$_, 1} @{ $input{'facter_host_group'} };
    foreach ( @{ $input{'distill_host_group'} } ) {
        $host_groups{$_} = 1;
    }
    @{ $input{'host_group'} } = keys %host_groups;

    $input_ref = \%input;

    validate( $input_ref );

    my $output_ref = transform( $basedir, $input_ref, $sequence_ref );

    my $dir = "client_json";
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
    my $json_output = $json->pretty->encode( $output_ref );
    my $md5_output  = md5_hex( $json_output );

    if ( hostname eq $host ) {
        my $dir = "state";
        if ( !-d "$outputdir/$dir" ) {mkdir "$outputdir/$dir"}

        # Write JSON file
        my $file = 'last_run.json';
        open my $fhandle, '>', "$outputdir/$dir/$file"
          or error( "Failed to open file: $dir/$file\n$!" );
        print $fhandle $json_output
          or error( "Failed to write to file: $dir/$file\n$!" );
        close $fhandle or error( "Failed to close file: $dir/$file\n$!" );
        $DEBUG and info( "Wrote output to: $dir/$file" );
    }

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

    # Write JSON ENC file
    my %expand;
    foreach my $key ( keys %{$output_ref} ) {
        if ( $key =~ /::/ ) {
            my ( $class, $param ) = ( $key =~ /(.*)::(.*)/ );

            if ( $param eq '' && !exists( $expand{'classes'}{$class} ) ) {
                $expand{'classes'}{$class} = undef;
            } elsif ( $param ne '' ) {
                $expand{'classes'}{$class}{$param} = $output_ref->{$key};
            }

        } else {
            $expand{'parameters'}{$key} = $output_ref->{$key};
        }
    }

    $dir = "client_enc_json";
    if ( !-d "$outputdir/$dir" ) {mkdir "$outputdir/$dir"}

    $file = $host . '.json';
    open $fhandle, '>', "$outputdir/$dir/$file"
      or error( "Failed to open file: $dir/$file\n$!" );
    print $fhandle $json->pretty->encode( \%expand )
      or error( "Failed to write to file: $dir/$file\n$!" );
    close $fhandle or error( "Failed to close file: $dir/$file\n$!" );
    $DEBUG and info( "Wrote output to: $dir/$file" );
}

sub clean_cache($$) {
    my ( $hosts_ref, $outputdir ) = @_;

    my %hosts = map {$_ => TRUE} @{$hosts_ref};

    foreach my $dir ( glob( "$outputdir/client_json/*" ) ) {
        my $host = basename( $dir );

        if ( !-d $dir )             {next}
        if ( exists $hosts{$host} ) {next}
        $DEBUG and info( "Removing host from JSON cache: $host" );

        map {unlink} glob "$dir/*";
        rmdir $dir;
    }

    foreach my $file ( glob( "$outputdir/client_enc_json/*" ) ) {
        my $host = basename( $file );
        $host =~ s/\.json$//;

        if ( !-f $file )            {next}
        if ( exists $hosts{$host} ) {next}
        $DEBUG and info( "Removing host from JSON ENC cache: $host" );

        unlink $file;
    }
}

1;
