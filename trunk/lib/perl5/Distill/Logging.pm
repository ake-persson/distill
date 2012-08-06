package Distill::Logging;

use warnings;
use strict;
use POSIX qw(strftime);
use Term::ANSIColor;
use base qw(Exporter);
use Distill::Global qw( :DEFAULT );

our @EXPORT = qw( debug info info2 warn error ok fail $LOGFILE $LOGHMTL $EXIT_ON_ERROR );

our $LOGFILE;
our $LOGHTML;
our $EXIT_ON_ERROR = TRUE;

sub debug {
    my $msg = shift;

    if ( $LOGHTML ) {
        print STDERR "Content Type: text/html\n\n[DEBUG] $msg\n";
    } elsif ( $CONF{'main.no-color'} ) {
        print STDERR '[DEBUG] ', $msg, "\n";
    } else {
        print STDERR color( 'cyan' ), '[DEBUG] ', $msg, "\n", color( 'reset' );
    }

    if ( defined( $LOGFILE ) ) {
        my $date = strftime( '%F %T', localtime( time ) );
        print $LOGFILE "$date : [DEBUG] $msg\n";
    }
}

sub info {
    my $msg = shift;

    if ( $LOGHTML ) {
        print STDERR "Content Type: text/html\n\n[INFO] $msg\n";
    } elsif ( $CONF{'main.no-color'} ) {
        print STDERR '[INFO] ', $msg, "\n";
    } else {
        print STDERR color( 'green' ), '[INFO] ', $msg, "\n", color( 'reset' );
    }

    my $date = strftime( "%Y-%m-%d %H:%M:%S\n", localtime( time ) );
    if ( defined( $LOGFILE ) ) {
        my $date = strftime( '%F %T', localtime( time ) );
        print $LOGFILE "$date : [INFO] $msg\n";
    }
}

sub info2 {
    my $msg = shift;

    if ( $LOGHTML ) {
        print STDERR "Content Type: text/html\n\n[INFO2] $msg\n";
    } elsif ( $CONF{'main.no-color'} ) {
        print STDERR '[INFO2] ', $msg, "\n";
    } else {
        print STDERR color( 'cyan' ), '[INFO2] ', $msg, "\n", color( 'reset' );
    }

    my $date = strftime( "%Y-%m-%d %H:%M:%S\n", localtime( time ) );
    if ( defined( $LOGFILE ) ) {
        my $date = strftime( '%F %T', localtime( time ) );
        print $LOGFILE "$date : [INFO2] $msg\n";
    }
}

sub warn {
    my $msg = shift;

    if ( $LOGHTML ) {
        print STDERR "Content Type: text/html\n\n[WARNING] $msg\n";
    } elsif ( $CONF{'main.no-color'} ) {
        print STDERR '[WARNING] ', $msg, "\n";
    } else {
        print STDERR color( 'yellow' ), '[WARNING] ', $msg, "\n", color( 'reset' );
    }

    if ( defined( $LOGFILE ) ) {
        my $date = strftime( '%F %T', localtime( time ) );
        print $LOGFILE "$date : [WARNING] $msg\n";
    }
}

sub error {
    my $msg = shift;

    if ( $LOGHTML ) {
        print "Content Type: text/html\n\n[ERROR] $msg\n";
    } elsif ( $CONF{'main.no-color'} ) {
        print STDERR '[ERROR] ', $msg, "\n";
    } else {
        print STDERR color( 'red' ), '[ERROR] ', $msg, "\n", color( 'reset' );
    }

    if ( defined( $LOGFILE ) ) {
        my $date = strftime( '%F %T', localtime( time ) );
        print $LOGFILE "$date : [ERROR] $msg\n";
    }
    $EXIT_ON_ERROR and exit 1;
}

sub ok {
    my $msg = shift;
    print STDERR $msg, ': [ ', color( 'green' ), 'OK', color( 'reset' ), " ]\n";
    if ( defined( $LOGFILE ) ) {
        my $date = strftime( '%F %T', localtime( time ) );
        print $LOGFILE "$date : $msg : [ OK ]\n";
    }
}

sub fail {
    my $msg = shift;
    print STDERR $msg, ': [ ', color( 'red' ), 'FAILED', color( 'reset' ), " ]\n";
    if ( defined( $LOGFILE ) ) {
        my $date = strftime( '%F %T', localtime( time ) );
        print $LOGFILE "$date : $msg : [ FAILED ]\n";
    }
    $EXIT_ON_ERROR and exit 1;
}

1;
