# == Class: jenkins_security
#
# Provides a means for puppet to generate/maintain Jenkins users and
#  configuration files.  Intended to be used in conjunction with the
#  puppet-jenkins module from PuppetForge, but can be used to generate
#  config files without requiring puppet-jenkins.
#
# === Parameters
#
# Document parameters here.
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#
#
# === Examples
#
#  class { jenkins_security: }
#
# === Authors
# Tim Rogers <virmitio@gmail.com>
#
# === Copyright
#
# Copyright 2014 Tim Rogers, unless otherwise noted.
#

class jenkins_security (
  $write_global_config = true,
  $base_path = $::osfamily ? {
               RedHat  => '/var/lib/jenkins',
               Suse    => '/var/lib/jenkins',
               Debian  => '/var/lib/jenkins',
               Windows => 'C:/ProgramData/jenkins',
               default => '/var/lib/jenkins'
             },
  $users = {},
  $debug = false,
  $user_defaults = undef,
) {
  if is_hash($user_devaults){
    $real_user_defaults = $user_devaults
  } else {
    $real_user_defaults = { base_path => $base_path, debug => $debug }
  }

#  if !defined(File["${base_path}"]){
#    file {"${base_path}":
#      ensure => directory,
#      owner  => 'jenkins',
#      group  => 'jenkins',
#      before => File["${base_path}/users"],
#    }
#  }
  if !defined(File["${base_path}/users"]){
    file {"${base_path}/users":
      ensure  => directory,
      owner   => 'jenkins',
      group   => 'jenkins',
      before  => Jenkins_security::Jenkins_user_config[keys($users)],
    }
  }

  create_resources('jenkins_security::jenkins_user_config', $users, $real_user_defaults)

  if $write_global_config {
    class {'jenkins_security::global_config':
      base_path => $base_path,
      require => Jenkins_security::Jenkins_user_config[keys($users)],
    }
  }

}
