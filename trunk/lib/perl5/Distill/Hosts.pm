package Distill::Hosts;

use warnings;
use strict;
use JSON;
use LWP;
use YAML qw(Load);
use base qw(Exporter);
use Distill::Global qw( :DEFAULT );
use Distill::Logging qw( :DEFAULT );

our @EXPORT = qw( host_has_class host_has_parameter all_hosts changed_hosts puppet_hosts );

sub host_has_parameter($$) {
    my ( $query, $outputdir ) = @_;
    my @hosts;

    my $json = JSON->new->allow_nonref;

    foreach my $dir ( glob "$outputdir/client_json/*" ) {
        my @files = glob "$dir/*.json";
        if ( $#files < 0 ) {next}

        my $file = $files[-1];

        open my $fhandle, '<', "$file"
          or error( "Failed to open file: $file\n$!" );
        local $/ = undef;
        my $content = <$fhandle>;
        close $fhandle
          or error( "Failed to close file: $file\n$!" );

        my $ref = $json->decode( $content );

        my ( $parameter, $value ) = split /=/, $query;

        if ( !exists $ref->{$parameter} ) {next}
        if ( defined $value and $ref->{$parameter} ne $value ) {next}

        my $host = $dir;
        $host =~ s/^.*\///;
        push @hosts, $host;
    }

    return \@hosts;
}

sub host_has_class($$) {
    my ( $class, $outputdir ) = @_;
    my @hosts;

    my $json = JSON->new->allow_nonref;

    foreach my $dir ( glob "$outputdir/client_json/*" ) {
        my @files = glob "$dir/*.json";
        if ( $#files < 0 ) {next}

        my $file = $files[-1];

        open my $fhandle, '<', "$file"
          or error( "Failed to open file: $file\n$!" );
        local $/ = undef;
        my $content = <$fhandle>;
        close $fhandle
          or error( "Failed to close file: $file\n$!" );

        my $ref = $json->decode( $content );

        my @keys = grep {$_ =~ /^$class\:\:/} keys %{$ref};

        if ( $#keys >= 0 ) {
            my $host = $dir;
            $host =~ s/^.*\///;
            push @hosts, $host;
        }
    }

    return \@hosts;
}

sub all_hosts($) {
    my ( $outputdir ) = @_;
    my @hosts;

    foreach my $dir ( glob "$outputdir/client_json/*" ) {
        my @files = glob "$dir/*.md5sum";
        if ( $#files < 0 ) {next}
        my $host = $dir;
        $host =~ s/^.*\///;
        push @hosts, $host;
    }

    return \@hosts;
}

sub changed_hosts($$) {
    my ( $time, $outputdir ) = @_;
    my @hosts;

    foreach my $dir ( glob "$outputdir/client_json/*" ) {
        my @files = glob "$dir/*.md5sum";
        if ( $#files < 0 ) {next}

        my $file    = $files[-1];
        my $created = ( stat( $file ) )[8];
        my $host    = $dir;
        $host =~ s/^.*\///;
        if ( $time < $created ) {push @hosts, $host}
    }

    return \@hosts;
}

sub puppet_hosts() {
    my $browser = LWP::UserAgent->new;
    $browser->timeout( $CONF{'main.puppet-timeout'} );
    $browser->default_header( 'Accept' => 'yaml' );

    my $url      = "https://$CONF{'main.puppet-server'}:8140/production/certificate_statuses/all";
    my $response = $browser->get( $url );
    if ( !$response->is_success ) {
        error( "Unable to get url: $url -- " . $response->status_line );
    }

    my $aref = Load( $response->content . "\n" );

    my @hosts;
    foreach my $href ( @{$aref} ) {
        push @hosts, $href->{'name'};
    }

    return \@hosts;
}

1;
