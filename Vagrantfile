# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://vagrantcloud.com/search.
  config.vm.box = "alvistack/ubuntu-24.04"  # Ubuntu 24.04 LTS (Noble Numbat)

  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  # config.vm.box_check_update = false

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  # NOTE: This will enable public access to the opened port
  
  # Forward common ports for web services
  config.vm.network "forwarded_port", guest: 80, host: 8088
  config.vm.network "forwarded_port", guest: 443, host: 8443
  
  # Additional ports that might be needed for T-Guard services
  config.vm.network "forwarded_port", guest: 3000, host: 3000
  config.vm.network "forwarded_port", guest: 5000, host: 5000
  config.vm.network "forwarded_port", guest: 8000, host: 8000

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  config.vm.network "private_network", ip: "192.168.56.150"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network "public_network"

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  config.vm.synced_folder ".", "/vagrant"

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  
  config.vm.provider "virtualbox" do |vb|
    # Display the VirtualBox GUI when booting the machine
    vb.gui = true  # Enable GUI to see boot errors
    
    # Set VM name for easier identification
    vb.name = "t-guard-dev"
    
    # Customize the amount of memory and CPU on the VM:
    # T-Guard requires 4 CPU and 8GB RAM
    vb.memory = "8192"
    vb.cpus = 4
    
    # Other performance optimizations
    vb.customize ["modifyvm", :id, "--ioapic", "on"]
    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    
    # Disable 3D acceleration
    vb.customize ["modifyvm", :id, "--accelerate3d", "off"]
    
    # Disable USB
    vb.customize ["modifyvm", :id, "--usb", "off"]
    vb.customize ["modifyvm", :id, "--usbehci", "off"]
    
    # Virtualization engine settings
    vb.customize ["modifyvm", :id, "--vtxux", "on"]
    vb.customize ["modifyvm", :id, "--vtxvpid", "on"]
    vb.customize ["modifyvm", :id, "--nested-hw-virt", "on"]
    vb.customize ["modifyvm", :id, "--paravirtprovider", "kvm"]
    
    # Disable audio
    vb.customize ["modifyvm", :id, "--audio", "none"]
    
    # Disable shared clipboard and drag'n'drop
    vb.customize ["modifyvm", :id, "--clipboard-mode", "disabled"]
    vb.customize ["modifyvm", :id, "--draganddrop", "disabled"]
  end

  # Enable provisioning with a shell script to install prerequisites
  config.vm.provision "shell", inline: <<-SHELL
    # Update system
    apt-get update
    apt-get upgrade -y
    
    # Install basic tools
    apt-get install -y curl wget git build-essential
    
    # Install Docker
    apt-get install -y docker.io
    usermod -aG docker vagrant
    systemctl enable docker
    systemctl start docker

    # Install Docker Compose
    apt-get install -y docker-compose

    # Make the auto_install script executable
    chmod +x /vagrant/auto_install.sh
    
    echo "T-Guard development environment is ready!"
    echo "To automatically install T-Guard components (steps 1-6), run: /vagrant/auto_install.sh"
  SHELL
  
  # Optionally run the auto_install.sh script automatically
  # Uncomment the following line to run the installation automatically after VM is provisioned
  config.vm.provision "shell", path: "auto_install.sh", privileged: false
end
