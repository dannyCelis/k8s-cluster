echo "# Configuración de Red Hat"
sudo subscription-manager clean
sudo subscription-manager register --username=[USERNAME] --password=[PASSWORD]
sudo subscription-manager repos --enable=rhel-8-for-x86_64-baseos-rpms --enable=rhel-8-for-x86_64-appstream-rpms

# echo "# Paso 0: Se crea el hostname de acuerdo al parametro enviado"
# echo $CRIO_VERSION
# if [ $# -ne 1 ]; then
#     echo "Uso: $0 <identificador>"
#     exit 1
# fi
# new_hostname="$1"
# hostnamectl set-hostname $new_hostname
# echo "El nombre de host se ha cambiado a: $new_hostname"

echo "# Paso 1: Deshabilitar la memoria swap"
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

echo "# Paso 2: Deshabilitar SELinux"
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

echo "# Paso 3: Instalar iproute y habilitar puertos - VALIDAR"
sudo yum install -y iproute-tc
sudo firewall-cmd --permanent --add-port=6443/tcp --add-port=2379-2380/tcp --add-port=10250/tcp --add-port=10259/tcp --add-port=10257/tcp
sudo firewall-cmd --reload

echo "#Paso 4: Instalar CRI-O"
sudo cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter
sudo cat << EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sudo sysctl --system
# VERSION=1.28
sudo curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable.repo https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/CentOS_8/devel:kubic:libcontainers:stable.repo
sudo curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable:cri-o:$CRIO_VERSION.repo https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:$CRIO_VERSION/CentOS_8/devel:kubic:libcontainers:stable:cri-o:$CRIO_VERSION.repo
sudo yum install cri-o cri-tools -y
sudo systemctl enable --now crio
sudo systemctl start crio

echo "# Paso 5: Instalar Kubernetes"
sudo cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.28/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.28/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF

sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
sudo systemctl enable --now kubelet
sudo systemctl start kubelet

echo "# Paso 6: Crear el cluster de Kubernetes"
sudo kubeadm init --apiserver-advertise-address=192.168.50.10 --pod-network-cidr=10.2.0.0/16 --cri-socket=unix:///var/run/crio/crio.sock
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
export KUBECONFIG=/etc/kubernetes/admin.conf

echo "# Paso 7: Instalar y configurar Calico"
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/tigera-operator.yaml
curl https://raw.githubusercontent.com/projectcalico/calico/v3.26.3/manifests/custom-resources.yaml -O
sudo sed -i 's/cidr: 192.168.0.0\/16/cidr: 10.2.0.0\/16/g' custom-resources.yaml
# sudo sed -i "s#cidr: 192.168.0.0/16#cidr: $POD_NETWORK_CIDR#g" custom-resources.yaml
cat custom-resources.yaml | grep "cidr:"
kubectl create -f custom-resources.yaml
kubectl get pods -n calico-system
