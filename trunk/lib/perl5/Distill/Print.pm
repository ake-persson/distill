package Distill::Print;

use warnings;
use strict;
use JSON;
use YAML qw(Dump);
use LWP::Simple;
use base qw(Exporter);
use Distill::Global qw( :DEFAULT );
use Distill::Logging qw( :DEFAULT );

our @EXPORT =
  qw( print_enc_yaml print_enc_json print_all_enc_json print_yaml print_json print_all_json print_enc_url_yaml print_enc_url_json );

sub print_enc_yaml($$) {
    my ( $host, $outputdir ) = @_;

    my $json = JSON->new->allow_nonref;

    my $host_ref;

    my $dir  = 'client_enc_json';
    my $file = "$host.json";
    open my $fhandle, '<', "$outputdir/$dir/$file"
      or error( "Failed to open file: $dir/$file\n$!" );

    local $/ = undef;
    my $content = <$fhandle>;
    close $fhandle
      or error( "Failed to close file: $dir/$file\n$!" );

    my $ref = $json->decode( $content );
    print Dump $ref;
}

sub print_enc_json($$) {
    my ( $host, $outputdir ) = @_;

    my $json = JSON->new->allow_nonref;

    my $host_ref;

    my $dir  = 'client_enc_json';
    my $file = "$host.json";
    open my $fhandle, '<', "$outputdir/$dir/$file"
      or error( "Failed to open file: $dir/$file\n$!" );

    local $/ = undef;
    my $content = <$fhandle>;
    close $fhandle
      or error( "Failed to close file: $dir/$file\n$!" );

    my $ref = $json->decode( $content );
    print $json->pretty->encode( $ref );
}

sub print_all_enc_json($) {
    my $outputdir = shift;

    my $json = JSON->new->allow_nonref;

    my %hosts;

    my $dir = 'client_enc_json';
    foreach my $file ( glob "$outputdir/$dir/*.json" ) {
        open my $fhandle, '<', "$file"
          or error( "Failed to open file: $file\n$!" );
        local $/ = undef;
        my $content = <$fhandle>;
        close $fhandle
          or error( "Failed to close file: $file\n$!" );

        my $host = $file;
        $host =~ s/^.*\///;
        $host =~ s/\.json$//;

        $hosts{$host} = $json->decode( $content );
    }

    print $json->pretty->encode( \%hosts );
}

sub print_yaml($$) {
    my ( $host, $outputdir ) = @_;

    my $json = JSON->new->allow_nonref;

    my $host_ref;

    my $dir   = 'client_json';
    my @files = glob( "$outputdir/$dir/$host/*.json" );
    my $file  = $files[-1];

    open my $fhandle, '<', $file
      or error( "Failed to open file: $file\n$!" );
    local $/ = undef;
    my $content = <$fhandle>;
    close $fhandle
      or error( "Failed to close file: $file\n$!" );

    my $ref = $json->decode( $content );
    print Dump $ref;
}

sub print_json($$) {
    my ( $host, $outputdir ) = @_;

    my $json = JSON->new->allow_nonref;

    my $host_ref;

    my $dir   = 'client_json';
    my @files = glob( "$outputdir/$dir/$host/*.json" );
    my $file  = $files[-1];

    open my $fhandle, '<', $file
      or error( "Failed to open file: $file\n$!" );
    local $/ = undef;
    my $content = <$fhandle>;
    close $fhandle
      or error( "Failed to close file: $file\n$!" );

    print $content . "\n";
}

sub print_all_json($) {
    my $outputdir = shift;

    my $json = JSON->new->allow_nonref;

    my %hosts;

    my $dir = 'client_json';
    foreach my $host ( glob "$outputdir/$dir/*" ) {
        $host =~ s/^.*\///;

        my @files = glob( "$outputdir/$dir/$host/*.json" );
        if ( $#files < 0 ) {next}

        my $file = $files[-1];

        open my $fhandle, '<', $file
          or error( "Failed to open file: $file\n$!" );
        local $/ = undef;
        my $content = <$fhandle>;
        close $fhandle
          or error( "Failed to close file: $file\n$!" );

        $hosts{$host} = $json->decode( $content );
    }

    print $json->pretty->encode( \%hosts );
}

sub print_enc_url_yaml($$) {
    my ( $host, $url ) = @_;

    $url .= "/index.pl/client/get/enc?host=$host";
    my $html = get $url or error( "Unable to get url: $url" );
    print $html;
}

sub print_enc_url_json($$) {
    my ( $host, $url ) = @_;

    $url .= "/index.pl/client/get/enc_json?host=$host";
    my $html = get $url or error( "Unable to get url: $url" );
    print $html;
}

1;
