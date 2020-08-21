# -*- mode: ruby -*-
# vi: set ft=ruby :

class master_workers() {
  $base = scanf($::network_workers_start_base,'%d')[0]

  host { "master.${::network_domain}": ip => "${::network_prefix}.${base}", host_aliases => 'master' }

  range(1, $::number_of_workers).each |$i| {
    $n = $base+$i
    host { "worker${i}.${::network_domain}": ip => "${::network_prefix}.${n}", host_aliases => "worker${i}" }
  }

  # to set my ssh public key as an authorized key in each box
  if $::mypubkey != '' {
    $splitted = split($::mypubkey,' ')
    ssh_authorized_key { $splitted[2]:
      user => 'vagrant',
      type => 'rsa',
      key  => $splitted[1],
    }
  }

  # so we can ssh from one box to another
  exec { 'put vagrant insecure key in place':
    user    => vagrant,
    path    => ['/bin', '/usr/bin'],
    command => 'wget https://raw.githubusercontent.com/hashicorp/vagrant/master/keys/vagrant -O /home/vagrant/.ssh/id_rsa && chmod 600 /home/vagrant/.ssh/id_rsa',
    creates => '/home/vagrant/.ssh/id_rsa',
  }

  # no need to accept manually the host key
  file { '/home/vagrant/.ssh/config':
    owner   => vagrant,
    group   => vagrant,
    mode    => '0600',
    content => '
Host *
    StrictHostKeyChecking no
',
   }
}

