# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.define "debian" do |m|
      m.vm.box = "wheezy64"
      m.vm.provision "shell", path: "bootstrap.sh"
      m.vm.synced_folder "~/.vim", "/home/vagrant/.vim"
  end
  config.vm.define "ubuntu" do |m|
      m.vm.box = "ubuntu/trusty64"
      m.vm.provision "shell", path: "bootstrap.sh"
      m.vm.synced_folder "~/.vim", "/home/vagrant/.vim"
  end
end
