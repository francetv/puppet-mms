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
# [*download_url*]
#   The location from where to download the mms agent. You probably won't need
#   to change this.
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
  $install_dir  = $mms::params::install_dir,
  $download_url = $mms::params::download_url,
  $tmp_dir      = $mms::params::tmp_dir,
  $mms_server   = $mms::params::mms_server,
  $mms_user     = $mms::params::mms_user
) inherits mms::params {
  package { 'py/setuptools':

    ensure => installed
  }
  package { ['gcc', 'python-dev']:
    ensure => installed
  }
  package { 'wget':
    ensure => installed
  }
  exec { 'install-pymongo':
    command => 'easy_install -U pymongo',
    path    => ['/bin', '/usr/bin'],
    require => Package['python-setuptools']
  }

  exec { 'download-mms':
    command => "wget ${download_url} -P ${tmp_dir} -O monitoring-agent.tar.gz",
    path    => ['/bin', '/usr/bin'],
    require => Package['wget'],
    creates => '/tmp/monitoring-agent.tar.gz'
  }

  file { $install_dir:
    ensure  => directory,
    mode    => '0755',
    recurse => true,
    owner   => $mms_user,
    group   => $mms_user,
    require => User[$mms_user]
  }

  user { $mms_user :
    ensure => present
  }

  exec { 'install-mms':
    command => "tar -C ${install_dir} xzf /tmp/monitoring-agent.tar.gz",
    path    => ['/bin', '/usr/bin'],
    require => [Exec['download-mms'], File[$install_dir]]
  }

  exec { 'set-license-key':
    command => "sed -ie 's|@API_KEY@|${api_key}|' ${install_dir}/settings.py",
    path    => ['/bin', '/use/bin'],
    require => Exec['install-mms']
  }

  exec { 'set-mms-server':
    command => "sed -ie 's|@MMS_SERVER@|${mms_server}|' ${install_dir}/settings.py",
    path    => ['/bin', '/usr/bin'],
    require => Exec['install-mms']
  }

  file { '/etc/init.d/mongodb-mms':
    content => template('mms/etc/init.d/mongodb-mms.erb'),
    require => [Exec['set-license-key'], Exec['set-mms-server']]
  }

  service { 'mongodb-mms':
    enable => true,
    ensure => running,
    require => File['/etc/init.d/mongodb-mms']
  }
}
