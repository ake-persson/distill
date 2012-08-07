#!/usr/bin/perl

use warnings;
use strict;
use FindBin qw($Bin);
use Config::Simple;
use CGI;

use lib "$Bin/../lib/perl5";
use Distill::Global qw( :DEFAULT );
use Distill::Hash qw( :DEFAULT );
use Distill::Logging qw( :DEFAULT );
use Distill::Update qw( :DEFAULT );
use Distill::Print qw( :DEFAULT );
use Distill::Hosts qw( :DEFAULT );

# Turn off buffering for STDOUT and STDERR
$| = 1;

# Default to umask 2, so that files will be group writable
umask 2;

# Arguments defaults
$DEBUG   = FALSE;
$LOGHTML = TRUE;
my $host = undef;

# CGI dispatch
my $dispatch = {
    '/client/get/enc'             => \&get_client_enc_yaml,
    '/client/enc/yaml'            => \&get_client_enc_yaml,
    '/client/get/enc_json'        => \&get_client_enc_json,
    '/client/enc/json'            => \&get_client_enc_json,
    '/client/enc/json/all'        => \&get_client_enc_json_all,
    '/client/get/json'            => \&get_client_json,
    '/client/json'                => \&get_client_json,
    '/client/json/all'            => \&get_client_json_all,
    '/client/get/yaml'            => \&get_client_yaml,
    '/client/yaml'                => \&get_client_yaml,
    '/client/has/parameter/json'  => \&has_parameter_json,
    '/client/has/class/json'      => \&has_class_json,
    '/client/puppet/all/json'     => \&puppet_hosts_json,
    '/client/puppet/json/all'     => \&puppet_hosts_json,
    '/client/cached/all/json'     => \&cached_hosts_json,
    '/client/cached/json/all'     => \&cached_hosts_json,
    '/client/cached/changed/json' => \&changed_hosts_json,
    '/client/cached/json/changed' => \&changed_hosts_json
};

# Read configuration file
if ( !-f $CONFIG ) {error "Configuration file doesn't exist: $CONFIG"}
my %conf_file;
Config::Simple->import_from( $CONFIG, \%conf_file );

# Merge configuration
%CONF = merge( \%CONF_DEFS, \%conf_file );

# Dispatch correct function
my $cgi  = CGI->new;
my $args = $cgi->Vars;

if ( exists $dispatch->{ $ENV{'PATH_INFO'} } ) {
    &{ $dispatch->{ $ENV{'PATH_INFO'} } }( $args );
} else {
    error "Missing dispatch: $ENV{'PATH_INFO'}";
}

sub get_client_enc_yaml {
    my $args = shift();

    if ( !exists $args->{'host'} ) {error( "Missing argument: host" )}

    update( $args->{'host'}, $CONF{'main.basedir'}, $CONF{'main.outputdir'}, $CONF{'main.sequence'} );

    print "Content-Type: text/yaml\n\n";
    print_enc_yaml( $args->{'host'}, $CONF{'main.outputdir'} );
}

sub get_client_enc_json {
    my $args = shift();

    if ( !exists $args->{'host'} ) {error( "Missing argument: host" )}

    update( $args->{'host'}, $CONF{'main.basedir'}, $CONF{'main.outputdir'}, $CONF{'main.sequence'} );

    print "Content-Type: text/json\n\n";
    print_enc_json( $args->{'host'}, $CONF{'main.outputdir'} );
}

sub get_client_enc_json_all {
    print "Content-Type: text/yaml\n\n";
    print_all_enc_json( $CONF{'main.outputdir'} );
}

sub get_client_json {
    my $args = shift();

    if ( !exists $args->{'host'} ) {error( "Missing argument: host" )}

    update( $args->{'host'}, $CONF{'main.basedir'}, $CONF{'main.outputdir'}, $CONF{'main.sequence'} );

    print "Content-Type: text/json\n\n";
    print_json( $args->{'host'}, $CONF{'main.outputdir'} );
}

sub get_client_json_all {
    print "Content-Type: text/json\n\n";
    print_all_json( $CONF{'main.outputdir'} );
}

sub get_client_yaml {
    my $args = shift();

    if ( !exists $args->{'host'} ) {error( "Missing argument: host" )}

    update( $args->{'host'}, $CONF{'main.basedir'}, $CONF{'main.outputdir'}, $CONF{'main.sequence'} );

    print "Content-Type: text/yaml\n\n";
    print_yaml( $args->{'host'}, $CONF{'main.outputdir'} );
}

sub has_parameter_json {
    my $args = shift();

    if ( !exists $args->{'parameter'} ) {error( "Missing argument: parameter" )}

    my $hosts_ref = host_has_parameter( $args->{'parameter'}, $CONF{'main.outputdir'} );

    print "Content-Type: text/yaml\n\n";
    my $json = JSON->new->allow_nonref;
    print $json->pretty->encode( $hosts_ref ) . "\n";
}

sub has_class_json {
    my $args = shift();

    if ( !exists $args->{'class'} ) {error( "Missing argument: class" )}

    my $hosts_ref = host_has_class( $args->{'class'}, $CONF{'main.outputdir'} );

    print "Content-Type: text/yaml\n\n";
    my $json = JSON->new->allow_nonref;
    print $json->pretty->encode( $hosts_ref ) . "\n";
}

sub puppet_hosts_json {
    my $hosts_ref = puppet_hosts();

    print "Content-Type: text/yaml\n\n";

    my $json = JSON->new->allow_nonref;
    print $json->pretty->encode( $hosts_ref ) . "\n";
}

sub cached_hosts_json {
    my $hosts_ref = all_hosts( $CONF{'main.outputdir'} );

    print "Content-Type: text/yaml\n\n";

    my $json = JSON->new->allow_nonref;
    print $json->pretty->encode( $hosts_ref ) . "\n";
}

sub changed_hosts_json {
    my $args = shift();

    if ( !exists $args->{'changed_since'} ) {error( "Missing argument: changed_since" )}

    my $time          = time;
    my $changed_since = $args->{'changed_since'};
    if ( $changed_since =~ /(\d+)-sec-ago/ ) {
        $time -= $1;
    } elsif ( $changed_since =~ /(\d+)-min-ago/ ) {
        $time -= $1 * 60;
    } elsif ( $changed_since =~ /(\d+)-(hour|hours)-ago/ ) {
        $time -= $1 * 60 * 60;
    } elsif ( $changed_since =~ /(\d+)-(day|days)-ago/ ) {
        $time -= $1 * 60 * 60 * 24;
    } elsif ( $changed_since =~ /(\d+)-(week|weeks)-ago/ ) {
        $time -= $1 * 60 * 60 * 24 * 7;
    } else {
        error "Unknown date format: $changed_since";
    }

    my $hosts_ref = changed_hosts( $time, $CONF{'main.outputdir'}, FALSE );

    print "Content-Type: text/yaml\n\n";
    my $json = JSON->new->allow_nonref;
    print $json->pretty->encode( $hosts_ref ) . "\n";
}
