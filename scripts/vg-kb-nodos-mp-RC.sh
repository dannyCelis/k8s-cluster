echo "# Configuración de Red Hat"
sudo subscription-manager clean
sudo subscription-manager register --username=rgaguedo@gmail.com --password=Chimichanga01$
sudo subscription-manager repos --enable=rhel-8-for-x86_64-baseos-rpms --enable=rhel-8-for-x86_64-appstream-rpms

# echo "# Paso 0: Se crea el hostname de acuerdo al parametro enviado"
# if [ $# -ne 1 ]; then
#     echo "Uso: $0 <identificador>"
#     exit 1
# fi
# new_hostname="$1"
# hostnamectl set-hostname $new_hostname
# echo "El nombre de host se ha cambiado a: "$new_hostname

echo "# Paso 1: Deshabilitar la memoria swap"
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

echo "# Paso 2: Deshabilitar SELinux"
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

echo "# Paso 3: Instalar iproute y habilitar puertos"
sudo yum install -y iproute
sudo firewall-cmd --permanent --add-port=10250/tcp --add-port=30000-32767/tcp
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
# CRIO_VERSION=1.28
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