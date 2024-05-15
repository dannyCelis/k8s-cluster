# Define variables
CRIO_VERSION='1.28'
POD_NETWORK_CIDR='10.2.0.0/16'

Vagrant.configure("2") do |config|

  # Nodo de control
  config.vm.define "control_plane" do |node|
    node.vm.box = "generic/rhel8"
    node.vm.hostname = "control-plane"
    node.vm.network "private_network", ip: "192.168.50.10"
    # node.vm.provider "virtualbox" do |vb|
    #   vb.memory = "2048"
    #   vb.cpus = 2
    # end
    node.vm.provision "shell", path: "scripts/vg-kb-cluster-mp-RC.sh", env: {
      "CRIO_VERSION" => CRIO_VERSION,
      "POD_NETWORK_CIDR" => POD_NETWORK_CIDR
    }
  end

  # Nodo de trabajo
  config.vm.define "worker1" do |node|
    node.vm.box = "generic/rhel8"
    node.vm.hostname = "worker1"
    node.vm.network "private_network", ip: "192.168.50.11"
    # node.vm.provider "virtualbox" do |vb|
    #   vb.memory = "2048"
    #   vb.cpus = 2
    # end
    node.vm.provision "shell", path: "scripts/vg-kb-nodos-mp-RC.sh", env: {
      "CRIO_VERSION" => CRIO_VERSION,
      "POD_NETWORK_CIDR" => POD_NETWORK_CIDR
    }
  end

  config.vm.provider "virtualbox" do |vb|
    vb.memory = "6144" #"2048"
    vb.cpus = 4 #2
  end 

end

