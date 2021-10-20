#!/bin/bash
echo "[TASK 01] Configure static IP"
cat > /etc/sysconfig/network-scripts/ifcfg-eth0 <<EOF
TYPE=Ethernet
BOOTPROTO=none
IPADDR=192.168.100.111
PREFIX=24
GATEWAY=192.168.100.1
DNS1=192.168.100.1
DNS2=8.8.8.8
DNS3=8.8.4.4
DEFROUTE=yes
IPV4_FAILURE_FATAL=no
IPV6INIT=no
NAME=eth0
DEVICE=eth0
ONBOOT=yes
EOF
systemctl restart network

# Install docker from Docker-ce repository
echo "[TASK 02] Install docker container engine"
yum install -y -q yum-utils device-mapper-persistent-data lvm2 > /dev/null 2>&1
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo > /dev/null 2>&1
yum install -y -q docker-ce-20.10.9 >/dev/null 2>&1

# Enable docker service
echo "[TASK 03] Enable and start docker service"
systemctl enable docker >/dev/null 2>&1
systemctl start docker

# Add yum repo file for Kubernetes
echo "[TASK 04] Add yum repo file for kubernetes"
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
echo "[TASK 05] Install Kubernetes (kubeadm, kubelet and kubectl)"
yum install -y -q kubeadm-1.19.15 kubelet-1.19.15 kubectl-1.19.15 >/dev/null 2>&1

# Start and Enable kubelet service
echo "[TASK 06] Enable and start kubelet service"
systemctl enable kubelet >/dev/null 2>&1
echo 'KUBELET_EXTRA_ARGS="--fail-swap-on=false"' > /etc/sysconfig/kubelet
systemctl start kubelet

# Install Openssh server
echo "[TASK 07] Install and configure ssh"
yum install -y -q openssh-server >/dev/null 2>&1
sed -i 's/.*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
systemctl enable sshd
systemctl start sshd

# Set Root password
echo "[TASK 08] Set root password"
echo "abc12345" | passwd --stdin root >/dev/null 2>&1

# Install additional required packages
echo "[TASK 09] Install additional packages"
yum install -y -q which net-tools sudo sshpass less >/dev/null 2>&1

# Hack required to provision K8s v1.15+ in LXC containers
echo "[TASK 10] Hack required to provision K8s v1.15+ in LXC containers"
mknod /dev/kmsg c 1 11
chmod +x /etc/rc.d/rc.local
echo 'mknod /dev/kmsg c 1 11' >> /etc/rc.d/rc.local

echo "[TASK 11] Update /etc/hosts file"
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
192.168.100.12    nfs.cams7.local
EOF

#######################################
# To be executed only on master nodes #
#######################################

if [[ $(hostname) =~ .*master.* ]]
then
  echo "[TASK 12] Pull required containers"
  kubeadm config images pull >/dev/null 2>&1
fi