class statsd ($graphite_host = "localhost", $graphite_port = 2003, $port = 8125, $debug = 0, $flush_interval = 60000) {
	$init_command = $operatingsystem ? {
                OpenSuSE  => "/etc/init.d/statsd restart",
                default => ""/sbin/stop statsd; /sbin/start statsd"",
        }
	$init_file = $operatingsystem ? {
                OpenSuSE  => "/etc/init.d/statsd",
                default => "/etc/init/statsd.conf",
        }
	$init_file_source = $operatingsystem ? {
                OpenSuSE  => "puppet:///modules/statsd/statsd.initd.systemv.suse",
                default => "puppet:///modules/statsd/statsd.init.upstart",
        }

	$main_package = $operatingsystem ? {
        	OpenSuSE  => "nodejs",
     		default => "nodejs-stable-release",
    	}
	$development_packages = $operatingsystem ? {            
                OpenSuSE  => "nodejs-devel",
                default => "nodejs-compat-symlinks",
        }

	package { $main_package:
		ensure => present;
	}
	package {
		$development_packages:
			require => Package[$development_packages],
			ensure => present;
		"npm":
			require => Package[$main_package],
			ensure => present;
	}
	exec { "npm-statsd":
	      command => "/usr/bin/npm install -g statsd",
	      refreshonly => true,
	      require => Package["npm"],
	      # you can trigger an update of statsd package by changing /etc/statsd.js, bit of a hack but works
	      subscribe => File["/etc/statsd.js"] 
	}

        file {
		$init_file:
                	ensure => file,
			owner   => "root",
			group   => "root",
			mode    => "0644",
                	source => $init_file_source;

		"/etc/statsd.js":
			ensure => file,
			content => template("statsd/statsd.js.erb");
	}
	exec { "restart-statsd":
		require => File[$init_file],
		subscribe  => [
				File[$init_file],
				File['/etc/statsd.js'],
				Exec['npm-statsd'],
				Package[$development_packages]
			],
		command => $init_command;
	}
}
