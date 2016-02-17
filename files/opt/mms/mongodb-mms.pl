#!/usr/bin/perl
use warnings;
use strict;
use Daemon::Control;
my $process=2;
 
exit Daemon::Control->new(
    name        => "MMS agent",
    lsb_start   => '$syslog $remote_fs',
    lsb_stop    => '$syslog',
    scan_name   => 'qr|/mongodb-mms-monitoring-agent|',
    lsb_sdesc   => 'Controleur MMS',
    lsb_desc    => 'Controleur MMS etendu',
    user        => 'mms',
    group       => 'mms',
    path        => '/usr/bin',
    directory   => '/usr/bin', 
    program     => '/usr/bin/mongodb-mms-monitoring-agent',
    program_args => [ '> /dev/null 2>&1' ],
 
    pid_file    => '/tmp/mms_agent.pid',
    stderr_file => '/tmp/mms_agent.out',
    stdout_file => '/tmp/mms_agent.out', 
    fork        => $process,
)->run;

