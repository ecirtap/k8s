# -*- mode: ruby -*-
# vi: set ft=ruby :

include stdlib

ensure_packages([
  'apt-transport-https',
  'ca-certificates',
  'curl',
  'software-properties-common',
  'gnupg2',
])

apt::source { 'k8s':
  comment  => 'This is the K8S repo',
  location => 'https://apt.kubernetes.io',
  release  => 'kubernetes-xenial',
  repos    => 'main',
  key      => {
    'id'     => '54A647F9048D5688D7DA2ABE6A030B21BA07F4FB',
    'source' => 'https://packages.cloud.google.com/apt/doc/apt-key.gpg',
  },
  include  => {
    'src' => false,
    'deb' => true,
  },
}

package { [
  'kubelet',
  'kubeadm',
  'kubectl']:
    require => Class['apt::update'],
}

file { '/etc/sysctl.d/k8s.conf':
  content => 'net.bridge.bridge-nf-call-iptables = 1',
  notify => Service['systemd-sysctl']
} 

file { '/etc/docker':
  ensure => directory
}

file { '/etc/docker/daemon.json':
  require => File['/etc/docker'],
  content => '
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}',
}

class { 'docklor': require => File['/etc/docker/daemon.json'] }

file { '/home/vagrant/.bash_aliases':
  content => "
source <(kubectl completion bash)
source <(kubeadm completion bash)
export HISTFILE=/vagrant/.bash_history_${::fqdn}
",
  require => Package['kubectl','kubeadm'],
}

service { 'systemd-sysctl':
  ensure => running
}

base::addgrouptouser { 'vagrant': require => Service['docker'], group   => 'docker' }

include master_workers

node /^worker\d+.my.machine$/ {
  class { '::nfs':
    client_enabled  => true,
  }
}

node 'master.my.machine' {
  ensure_packages([
    'openjdk-8-jre-headless',
  ])
  class { '::nfs':
    server_enabled => true,
  }
  nfs::server::export { '/srv':
    ensure  => 'mounted',
    clients => '*(rw,insecure,async,no_root_squash)',
  }
}
