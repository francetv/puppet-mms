# == Class: mms
#
# Installs the MongoDB MMS Monitoring agent
#
# === Parameters
#
# Document parameters here.
#
# [*api_key*]
#   Your mongodb API key. You can find your key by logging into MMS, navigating
#   to the "Settings" page and clicking "Api Settings". This parameter is
#   required.
#
# [*install_dir*]
#   The location where the mms agent will be installed.
#
# [*tmp_dir*]
#   The temporary location to where files will be downloaded before installation.
#
# [*mms_server*]
#   The server the agent should be talking to. You probably won't need to
#   change this.
#
# [*mms_user*]
#   The user you want MMS to run as. This user will be created for you.
#
# === Examples
#
# * Minimal installation with defaults
#
# class { mms:
#   api_key => '809ca70c71af0795fccec87aa10ed925'
# }
#
# === Authors
#
# Tyler Stroud <mailto:tyler@tylerstroud.com>
#
# === Copyright
#
# Copyright 2014 Tyler Stroud
#
class mms (
  $api_key,
  $install_dir  = '/usr/bin/', #$mms::params::install_dir,
  $tmp_dir      = $mms::params::tmp_dir,
  $mms_server   = $mms::params::mms_server,
  $mms_user     = $mms::params::mms_user
) inherits mms::params {
  package { ['perl']:
    ensure => installed
  }
  package { 'wget':
    ensure => installed
  }

#  file { $install_dir:
#    ensure  => directory,
#    mode    => '0755',
#    recurse => true,
#    owner   => $mms_user,
#    group   => $mms_user,
#    require => User[$mms_user]
#  }

  user { $mms_user :
    ensure => present
  }
   

#  file { '/opt/mms/mongodb-mms-monitoring-agent':
#    source  => "puppet:///modules/mms/opt/mms/mongodb-mms-monitoring-agent",
#    mode    => '0754',
#    owner   => $mms_user,
#    group   => $mms_user,
#    require => [File[$install_dir]]
#  }

  file { '/etc/mongodb-mms/monitoring-agent.config':
    source  => "puppet:///modules/mms/opt/mms/monitoring-agent.config",
    mode    => '0554',
    owner   => $mms_user,
    group   => $mms_user,
    require => [Exec['package-init']],
  }

  file { '/etc/mongodb-mms/mongodb-mms.pl':
    source  => "puppet:///modules/mms/opt/mms/mongodb-mms.pl",
    mode    => '0754',
    owner   => $mms_user,
    group   => $mms_user,
    notify  => Service['mongodb-mms'],
    require => [Exec['package-init']],
  }


  exec { 'package-install':
   command => "curl -OL https://cloud.mongodb.com/download/agent/monitoring/mongodb-mms-monitoring-agent_latest_amd64.deb; dpkg -i mongodb-mms-monitoring-agent_latest_amd64.deb; rm mongodb-mms-monitoring-agent_latest_amd64.deb",
   path    => ['/bin', '/usr/bin']
  }

  exec { 'package-init':
  command => "/bin/bash -c \"export PERL_MM_USE_DEFAULT=1\" ; /bin/bash -c \"export PERL_EXTUTILS_AUTOINSTALL=--defaultdeps\"; perl -MCPAN -e \"install Daemon::Control\"",
  path    => ['/bin', '/usr/bin'],
  require => [Exec['package-install']]
  } 
 
  exec { 'set-license-key':
    command => "sed -ie 's|@API_KEY@|${api_key}|' /etc/mongodb-mms/monitoring-agent.config",
    path    => ['/bin', '/usr/bin'],
    require => [File['/etc/mongodb-mms/monitoring-agent.config']]
  }

  exec { 'set-mms-server':
    command => "sed -ie 's|@MMS_SERVER@|${mms_server}|' /etc/mongodb-mms/monitoring-agent.config",
    path    => ['/bin', '/usr/bin'],
    require => [File['/etc/mongodb-mms/monitoring-agent.config']]
  }

  file { '/etc/init.d/mongodb-mms':
    content => template('mms/etc/init.d/mongodb-mms.erb'),
    mode    => 0755,
    owner   => 'root',
     group   => 'root',
    require => [Exec['set-license-key'], Exec['set-mms-server']]
  }
  service { 'mongodb-mms':
    enable => true,
    ensure => running,
    require => File['/etc/init.d/mongodb-mms']
  }
}
