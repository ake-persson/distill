package Distill::Global;

use strict;
use warnings;
use base qw( Exporter );

our @EXPORT = qw( TRUE FALSE $DEBUG $LOGHTML $LOGFILE $CONFIG %CONF %CONF_DEFS );

use constant {
    TRUE  => 1,
    FALSE => 0,
};

our $DEBUG   = FALSE;
our $LOGHTML = FALSE;
our $LOGFILE = undef;
our $CONFIG  = '/etc/distill/distill.conf';
our %CONF;
our %CONF_DEFS = (
    'main.silent'               => FALSE,
    'main.basedir'              => '/etc/distill',
    'main.outputdir'            => '/var/lib/distill',
    'main.logfile'              => '/var/log/distill/distill.log',
    'main.puppet-server'        => 'localhost',
    'main.puppet-timout'        => 15,
    'main.user'                 => 'puppetmaster',
    'main.group'                => 'puppetmaster',
    'main.sequence'             => ['default', 'operatingsystem', 'operatingsystemrelease'],
    'main.thread-count'         => 12,
    'main.cache-keep-days'      => 30,
    'main.environment'          => 'production',
    'main.override-environment' => FALSE,
    'main.use-staging'          => TRUE,
    'lookup.web-lookup'         => FALSE,
    'lookup.url'                => 'http://localhost/distill',
    'facter.cache'          => TRUE,
    'facter.facts'          => ['operatingsystem', 'operatingsystemrelease'],
    'facter.use-host-group' => FALSE,
    'facter.host-group'     => 'host_group',
    'facter.query-local'    => FALSE,
);

1;
