# == Class: cvmfs::install
#
# Install cvmfs from a yum repository.
#
# === Parameters
#
# [*cvmfs_version*]
#   Is passed the cvmfs package instance to ensure the
#   cvmfs package with latest, present or an exact version.
#
# === Authors
#
# Steve Traylen <steve.traylen@cern.ch>
#
# === Copyright
#
# Copyright 2012 CERN
#
class cvmfs::install (
  $cvmfs_version = $cvmfs::cvmfs_version,
  $cvmfs_cache_base = $cvmfs::cvmfs_cache_base,
  $cvmfs_yum_manage_repo = $cvmfs::cvmfs_yum_manage_repo,

) inherits cvmfs {

  if $cvmfs_yum_manage_repo {
    class{'::cvmfs::yum':}
  }

  # Create the cache dir if one is defined, otherwise assume default is in the package.
  # Require the package so we know the user is in place.
  # We need to change the selinux context of this new directory below.
  case $::operatingsystemmajrelease {
    5: { $cache_seltype = 'var_t' }
    default: { $cache_seltype = 'cvmfs_cache_t'}
  }

  # Compare the default value with the one from hiera if declared
  $default_cvmfs_cache_base  = '/var/lib/cvmfs'

  if $cvmfs_cache_base != $default_cvmfs_cache_base {
    file{$cvmfs_cache_base:
      ensure  => directory,
      owner   => cvmfs,
      group   => cvmfs,
      mode    => '0700',
      seltype => $cache_seltype,
      require => Package['cvmfs'],
    }
  }

  $_pkgrequire = $cvmfs_yum_manage_repo ? {
    true  => Yumrepo['cvmfs'],
    false => undef,
  }

  package{'cvmfs':
    ensure  => $cvmfs_version,
    require => $_pkgrequire,
  }


  # Create a file for the cvmfs
  file{'/etc/cvmfs/cvmfsfacts.yaml':
    ensure  => file,
    mode    => '0644',
    content => "---\n#This file generated by puppet and is used by custom facts only.\ncvmfs_cache_base: ${cvmfs_cache_base}\n",
    require => Package['cvmfs'],
  }
}

