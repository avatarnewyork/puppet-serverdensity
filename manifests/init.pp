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

class serverdensity ($agent_key, $options=['']) {

  $repo_key = 'https://www.serverdensity.com/downloads/boxedice-public.key'

  if $osfamily == 'debian' {
    $install_repo_key = "curl $repo_key | apt-key add -"
    $repo_path = '/etc/apt/sources.list.d/sd-agent.list'
    $repo_file_name = 'sd-agent.list'
    #$update_pkg_manager = Class['apt']

    exec { 'sd run apt-update':
      require => File['server-density-repo'],
      before  => Package['sd-agent'],
      command => 'apt-get update',
      path    => '/usr/bin/',
    }

  } elsif $osfamily == 'redhat' {
    $install_repo_key = "rpm --import $repo_key"
    $repo_path = '/etc/yum.repos.d/serverdensity.repo'
    $repo_file_name = 'serverdensity.repo'
  }

	exec { 'server-density-repo-key':
		path    => '/bin:/usr/bin',
		command => $install_repo_key,
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
