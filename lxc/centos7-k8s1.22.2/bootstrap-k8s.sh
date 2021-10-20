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

##Update the OS and install yum-utils, bash completion, git, and more
echo "[TASK 02] Update the OS and install yum-utils, bash completion, git, and more"
yum update -y >/dev/null 2>&1 
yum install yum-utils nfs-utils bash-completion git -y -q >/dev/null 2>&1
 
##Disable firewall starting from Kubernetes v1.19 onwards
#systemctl disable firewalld --now 
 
## letting ipTables see bridged networks
echo "[TASK 03] Letting ipTables see bridged networks"
cat > /etc/modules-load.d/k8s.conf <<EOF
br_netfilter
EOF

cat > /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system >/dev/null 2>&1
 
##
## iptables config as specified by CRI-O documentation
# Create the .conf file to load the modules at bootup
echo "[TASK 04] Create the .conf file to load the modules at bootup"
cat > /etc/modules-load.d/crio.conf <<EOF
overlay
br_netfilter
EOF
 
#modprobe overlay
#modprobe br_netfilter
 
# Set up required sysctl params, these persist across reboots.
echo "[TASK 05] Set up required sysctl params, these persist across reboots"
cat > /etc/sysctl.d/99-kubernetes-cri.conf <<EOF
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
 
sysctl --system >/dev/null 2>&1
 
###
## Configuring Kubernetes repositories
echo "[TASK 06] Add yum repo file for kubernetes"
cat > /etc/yum.repos.d/kubernetes.repo <<EOF
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF
 
## Set SELinux in permissive mode (effectively disabling it)
#setenforce 0
#sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
 
### Disable swap
#swapoff -a
 
##make a backup of fstab
#cp -f /etc/fstab /etc/fstab.bak
 
##Renove swap from fstab
#sed -i '/swap/d' /etc/fstab
 
##Refresh repo list
echo "[TASK 07] Refresh repo list"
yum repolist -y >/dev/null 2>&1

echo "[TASK 08] Install CRI-O" 
## Install CRI-O binaries
##########################
 
#Operating system   $OS
#Centos 8   CentOS_8
#Centos 8 Stream    CentOS_8_Stream
#Centos 7   CentOS_7
 
#set OS version
OS=CentOS_7 
#set CRI-O
VERSION=1.22
 
# Install CRI-O
curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable.repo https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/devel:kubic:libcontainers:stable.repo >/dev/null 2>&1
curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable:cri-o:$VERSION.repo https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:$VERSION/$OS/devel:kubic:libcontainers:stable:cri-o:$VERSION.repo >/dev/null 2>&1
yum install cri-o -y -q >/dev/null 2>&1

echo "[TASK 09] Enable CRI-O"
systemctl daemon-reload
systemctl enable crio --now >/dev/null 2>&1
 
##Install Kubernetes, specify Version as CRI-O
echo "[TASK 10] Install Kubernetes (kubeadm, kubelet and kubectl)"
yum install -y -q kubelet-$VERSION.2-0 kubeadm-$VERSION.2-0 kubectl-$VERSION.2-0 --disableexcludes=kubernetes >/dev/null 2>&1

# Start and Enable kubelet service
echo "[TASK 11] Enable and start kubelet service"
systemctl enable kubelet >/dev/null 2>&1
echo 'KUBELET_EXTRA_ARGS="--fail-swap-on=false"' > /etc/sysconfig/kubelet
systemctl start kubelet

# Install Openssh server
echo "[TASK 12] Install and configure ssh"
yum install -y -q openssh-server >/dev/null 2>&1
sed -i 's/.*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
systemctl enable sshd
systemctl start sshd

# Set Root password
echo "[TASK 13] Set root password"
echo "abc12345" | passwd --stdin root >/dev/null 2>&1

# Install additional required packages
echo "[TASK 14] Install additional packages"
yum install -y -q which net-tools sudo sshpass less >/dev/null 2>&1

# Hack required to provision K8s v1.15+ in LXC containers
echo "[TASK 15] Hack required to provision K8s v1.15+ in LXC containers"
mknod /dev/kmsg c 1 11
chmod +x /etc/rc.d/rc.local
echo 'mknod /dev/kmsg c 1 11' >> /etc/rc.d/rc.local

echo "[TASK 16] Update /etc/hosts file"
cat >> /etc/hosts <<EOF
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
  echo "[TASK 17] Pull required containers"
  kubeadm config images pull >/dev/null 2>&1
fi




