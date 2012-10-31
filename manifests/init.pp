# Class: serverdensity
# Notes:
#  This class is compatible with Debian and RedHat OS families only.
#  By Sergio Oliveira from Tracy Web Technologies.
#
# Actions:
#  - Adds to the apt/yum repository list
#  - Installs and configures the Server Density monitoring agent, sd-agent
#
# Sample Usage:
#
#  class { 'serverdensity':
#    agent_key => '6f5902ac237024bdd0c176cb93063dc4'
#  }

class serverdensity ($agent_key='', $acc_name, $options=['']) {

  $repo_key_fname = "boxedice-public.key"
  $repo_key = 'https://www.serverdensity.com/downloads/boxedice-public.key'

  if $osfamily == 'debian' {
    $wget_repo_key = ""
    $wget_cwd = ""
    $install_repo_key = "curl $repo_key | apt-key add -"
    $install_repo_key_stop_condition = 'apt-key list | grep -c "Server Density"'
    $repo_path = '/etc/apt/sources.list.d/sd-agent.list'
    $repo_file_name = 'sd-agent.list'
    #$update_pkg_manager = Class['apt']

    exec { 'sd run apt-update':
      require     => File['server-density-repo'],
      before      => Package['sd-agent'],
      command     => 'apt-get update',
      path        => '/usr/bin/',
      subscribe   => File['server-density-repo'],
      refreshonly => true,
    }

  } elsif $osfamily == 'redhat' {
    $wget_repo_key = "wget $repo_key"
    $wget_cwd = "/usr/local/src"
    #$install_repo_key = "rpm --import $repo_key"
    $install_repo_key = "rpm --import $wget_cwd/$repo_key_fname"
    $install_repo_key_stop_condition = undef
    $repo_path = '/etc/yum.repos.d/serverdensity.repo'
    $repo_file_name = 'serverdensity.repo'
  } 

  $serverdensity_addclient = "/usr/local/sbin/serverdensity_addclient.rb"
  $sduser = hiera("sduser")
  $sdpwd = hiera("sdpwd")
  $sdacct = hiera("sdacct")
  $sdkeyfile = "/etc/serverdensity.key"
  
  package {"rest-client":
    ensure => "latest",
    provider => gem,
  }
  
  file {$serverdensity_addclient :
    content => template("serverdensity/serverdensity_addclient.rb.erb"),
    mode => "0700",
    owner => "root",
    group => "root",
    require => Package["rest-client"],
    notify => Exec[$serverdensity_addclient],
  }

  exec {$serverdensity_addclient :
    path => '/bin:/usr/bin:/usr/local/sbin',
    unless => $install_repo_key_stop_condition,
    require => File[$serverdensity_addclient],
    refreshonly => true,
    notify => Exec['wget-server-density-repo-key'],
  }
  
  exec { 'wget-server-density-repo-key':
    path => '/bin:/usr/bin',
    cwd => $wget_cwd,
    command => $wget_repo_key,
    unless => $install_repo_key_stop_condition,
    notify => Exec["server-density-repo-key"],
  }
    
  exec { 'server-density-repo-key':
    path    => '/bin:/usr/bin',
    command => $install_repo_key,
    unless  => $install_repo_key_stop_condition,
    refreshonly => true,
  }

  file { 'server-density-repo':
    path    => $repo_path,
    mode    => '0644',
    source  => "puppet:///modules/serverdensity/$repo_file_name",
    require => Exec['server-density-repo-key']
  }

	package { 'sd-agent':
		ensure  => installed,
		require => File['server-density-repo'],
	}

	file { '/etc/sd-agent/config.cfg':
		content => template('serverdensity/config.cfg.erb'),
		mode    => '0644',
    notify  => Service['sd-agent'],
    require => Package['sd-agent'],
	}
	
	service { 'sd-agent':
		ensure  => running,
		enable  => true,
		require => File['/etc/sd-agent/config.cfg'],
	}
}
