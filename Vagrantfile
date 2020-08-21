# -*- mode: ruby -*-
# vi: set ft=ruby :

unless Vagrant.has_plugin?("vagrant-disksize")
  raise 'vagrant-disksize plugin is required!'
end

mypubkeyfile = ENV['HOME']+"/.ssh/id_rsa.pub"

if File.file?(mypubkeyfile) then
  mypubkey = File.read(mypubkeyfile).chop()
else
  mypubkey = ''
end

puppet_opts = ENV['PUPPET_OPTS'] || '--show_diff'

number_of_workers = ENV['NUMBER_OF_WORKERS'] || 2
network_prefix = ENV['NETWORK_PREFIX'] || '10.1.14'
network_workers_start_base = ENV['NETWORK_WORKERS_START_BASE'] || 240
network_bridge_hostitf = ENV['NETWORK_BRIDGE_HOSTITF'] || 'en1: Wi-Fi (AirPort)'
network_gateway = ENV['NETWORK_GATEWAY'] || '10.1.14.1'
network_domain = ENV['NETWORK_DOMAIN'] || 'my.machine'
master_memory = ENV['MASTER_MEMORY'] || 2048
master_cpus = ENV['MASTER_CPUS'] || 2
worker_memory = ENV['WORKER_MEMORY'] || 2048
worker_cpus = ENV['WORKER_CPUS'] || 2

install_puppet = <<-SCRIPT
if ! command -v puppet > /dev/null ; then
  apt-get update && apt-get install -qqy puppet
  rm /etc/puppet/hiera.yaml
fi
SCRIPT

set_hostname = <<-SCRIPT
if [ "$(hostname -f)" != "$1" ] ; then
   hostnamectl set-hostname $1
fi
SCRIPT

Vagrant.configure("2") do |config|

  config.vm.provider :virtualbox do |vb|
    vb.customize ['guestproperty', 'set', :id, '/VirtualBox/GuestAdd/VBoxService/--timesync-set-threshold', 10000 ]
    vb.linked_clone = true if Gem::Version.new(Vagrant::VERSION) >= Gem::Version.new('1.8.0')
  end

  config.vm.provision :install_puppet, type: "shell", inline: install_puppet

  config.vm.provision :puppet_apply, type: "puppet" do |puppet|
    puppet.manifests_path = 'puppet/manifests'
    puppet.module_path = ['puppet/dev','puppet/modules','puppet/incubator']
    puppet.manifest_file = 'init.pp'
    puppet.hiera_config_path = 'puppet/hiera.yaml'
    puppet.facter = {
      'number_of_workers'          => number_of_workers,
      'network_prefix'             => network_prefix,
      'network_domain'             => network_domain,
      'network_workers_start_base' => network_workers_start_base,
      'frontend_ip'                => network_prefix+'.'+network_workers_start_base.to_s,
      'mypubkey'                   => mypubkey,
    }
  end

  config.ssh.insert_key = false

  config.vm.define 'master', primary: true do |box|
    box.vm.box = 'ubuntu/bionic64'
    box.vm.box_check_update = false
    master_ip = network_prefix+'.'+network_workers_start_base.to_s
    box.vm.network "public_network", ip: master_ip, bridge: network_bridge_hostitf
    box.vm.provision "shell", run: "always", inline: "ip route replace default via #{network_gateway} metric 1"
    box.vm.provider :virtualbox do |vb|
      vb.customize ['modifyvm', :id, '--memory', master_memory]
      vb.customize ["modifyvm", :id, "--cpus", master_cpus]
    end
    box.vm.provision :set_hostname, type: "shell", inline: set_hostname, args: 'master.' + network_domain
    box.vm.provision :puppet_apply, type: "puppet" do |puppet|
      puppet.options = [ puppet_opts ]
    end
    box.disksize.size = '40GB'
  end

  (1..number_of_workers.to_i).each do |i|
    box_name="worker" + i.to_s
    box_ip_name="worker" + i.to_s + '.' + network_domain
    box_ip=network_prefix+'.'+(network_workers_start_base.to_i+i).to_s
    config.vm.define box_name do |box|
      box.vm.box = 'ubuntu/bionic64'
      box.vm.box_check_update = false
      box.vm.network "public_network", ip: box_ip, bridge: network_bridge_hostitf
      box.vm.provision "shell", run: "always", inline: "ip route replace default via #{network_gateway} metric 1"
      box.vm.provider :virtualbox do |vb|
        vb.customize ['modifyvm', :id, '--memory', worker_memory]
        vb.customize ["modifyvm", :id, "--cpus", worker_cpus]
      end
      box.vm.provision :set_hostname, type: "shell", inline: set_hostname, args: box_ip_name
      box.vm.provision :puppet_apply, type: "puppet" do |puppet|
        puppet.options = [ puppet_opts ]
      end
    end
  end
end

