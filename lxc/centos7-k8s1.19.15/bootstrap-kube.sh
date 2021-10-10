#!/bin/bash

# Install docker from Docker-ce repository
echo "[TASK 1] Install docker container engine"
yum install -y -q yum-utils device-mapper-persistent-data lvm2 > /dev/null 2>&1
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo > /dev/null 2>&1
yum install -y -q docker-ce-20.10.9 >/dev/null 2>&1

# Enable docker service
echo "[TASK 2] Enable and start docker service"
systemctl enable docker >/dev/null 2>&1
systemctl start docker

# Add yum repo file for Kubernetes
echo "[TASK 3] Add yum repo file for kubernetes"
cat >>/etc/yum.repos.d/kubernetes.repo<<EOF
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=0
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
        https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

# Install Kubernetes
echo "[TASK 4] Install Kubernetes (kubeadm, kubelet and kubectl)"
yum install -y -q kubeadm-1.19.15 kubelet-1.19.15 kubectl-1.19.15 >/dev/null 2>&1

# Start and Enable kubelet service
echo "[TASK 5] Enable and start kubelet service"
systemctl enable kubelet >/dev/null 2>&1
echo 'KUBELET_EXTRA_ARGS="--fail-swap-on=false"' > /etc/sysconfig/kubelet
systemctl start kubelet >/dev/null 2>&1

# Install Openssh server
echo "[TASK 6] Install and configure ssh"
yum install -y -q openssh-server >/dev/null 2>&1
sed -i 's/.*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
systemctl enable sshd >/dev/null 2>&1
systemctl start sshd >/dev/null 2>&1

# Set Root password
echo "[TASK 7] Set root password"
echo "abc12345" | passwd --stdin root >/dev/null 2>&1

# Install additional required packages
echo "[TASK 8] Install additional packages"
yum install -y -q which net-tools sudo sshpass less >/dev/null 2>&1

# Hack required to provision K8s v1.15+ in LXC containers
mknod /dev/kmsg c 1 11
chmod +x /etc/rc.d/rc.local
echo 'mknod /dev/kmsg c 1 11' >> /etc/rc.d/rc.local

echo "[TASK 9] Update /etc/hosts file"
cat >>/etc/hosts<<EOF
192.168.100.100   k8s.cams7.ml
192.168.100.101   lb101.cams7-vaio.local
192.168.100.102   lb102.cams7-dell.local
192.168.100.103   lb103.cams7-qbex.local
192.168.100.111   kmaster111.cams7-vaio.local
192.168.100.112   kmaster112.cams7-vaio.local
192.168.100.113   kmaster113.cams7-vaio.local
192.168.100.114   kmaster114.cams7-dell.local
192.168.100.115   kmaster115.cams7-dell.local
192.168.100.116   kmaster116.cams7-dell.local
192.168.100.117   kmaster117.cams7-qbex.local
192.168.100.118   kmaster118.cams7-qbex.local
192.168.100.119   kmaster119.cams7-qbex.local
192.168.100.121   kworker121.cams7-vaio.local
192.168.100.122   kworker122.cams7-vaio.local
192.168.100.123   kworker123.cams7-vaio.local
192.168.100.124   kworker124.cams7-dell.local
192.168.100.125   kworker125.cams7-dell.local
192.168.100.126   kworker126.cams7-dell.local
192.168.100.127   kworker127.cams7-qbex.local
192.168.100.128   kworker128.cams7-qbex.local
192.168.100.129   kworker129.cams7-qbex.local
192.168.100.130   traefik.cams7.local
192.168.100.105   nfs.cams7.local
EOF

#######################################
# To be executed only on master nodes #
#######################################

if [[ $(hostname) =~ .*master.* ]]
then
  echo "[TASK 10] Pull required containers"
  kubeadm config images pull >/dev/null 2>&1
fi

if [[ $(hostname) =~ .*master111.* ]]
then

  # Initialize Kubernetes
  echo "[TASK 11] Initialize Kubernetes Cluster"
  kubeadm init  --control-plane-endpoint="k8s.cams7.ml:6443" --upload-certs --pod-network-cidr=10.244.0.0/16 --ignore-preflight-errors=all >> /root/kubeinit.log 2>&1

  # Copy Kube admin config
  echo "[TASK 12] Copy kube admin config to root user .kube directory"
  mkdir /root/.kube
  cp /etc/kubernetes/admin.conf /root/.kube/config

  # Deploy flannel network
  echo "[TASK 13] Deploy flannel network"
  kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml > /dev/null 2>&1

#  # Generate Cluster join command
#  echo "[TASK 13] Generate and save cluster join command to /joincluster.sh"
#  joinCommand=$(kubeadm token create --print-join-command 2>/dev/null) 
#  echo "$joinCommand --ignore-preflight-errors=all" > /joincluster.sh

fi

#######################################
# To be executed only on worker nodes #
#######################################

#if [[ $(hostname) =~ .*worker.* ]]
#then

#  # Join worker nodes to the Kubernetes cluster
#  echo "[TASK 9] Join node to Kubernetes Cluster"
#  sshpass -p "abc12345" scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no kmaster.lxd:/joincluster.sh /joincluster.sh 2>/tmp/joincluster.log
#  bash /joincluster.sh >> /tmp/joincluster.log 2>&1

#fi

