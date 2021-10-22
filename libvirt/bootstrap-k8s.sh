#!/bin/bash

echo "[TASK 01] Disable and turn off SWAP"
sed -i '/swap/d' /etc/fstab
swapoff -a

echo "[TASK 02] Stop and Disable firewall"
systemctl disable --now ufw >/dev/null 2>&1

echo "[TASK 03] Enable and Load Kernel modules"
cat >>/etc/modules-load.d/containerd.conf<<EOF
overlay
br_netfilter
EOF
modprobe overlay
modprobe br_netfilter

echo "[TASK 04] Add Kernel settings"
cat >>/etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
EOF
sysctl --system >/dev/null 2>&1

echo "[TASK 05] Install containerd runtime"
apt update -qq >/dev/null 2>&1
apt install -qq -y containerd apt-transport-https >/dev/null 2>&1
mkdir /etc/containerd
containerd config default > /etc/containerd/config.toml
systemctl restart containerd
systemctl enable containerd >/dev/null 2>&1

echo "[TASK 06] Add apt repo for kubernetes"
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - >/dev/null 2>&1
apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main" >/dev/null 2>&1

echo "[TASK 07] Install Kubernetes components (kubeadm, kubelet and kubectl)"
apt install -qq -y kubeadm=1.22.0-00 kubelet=1.22.0-00 kubectl=1.22.0-00 >/dev/null 2>&1

echo "[TASK 08] Enable ssh password authentication"
sed -i 's/^PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config
echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config
systemctl reload sshd

echo "[TASK 09] Set root password"
echo -e "abc12345\nabc12345" | passwd root >/dev/null 2>&1
echo "export TERM=xterm" >> /etc/bash.bashrc

echo "[TASK 10] Update /etc/hosts file"
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

if [[ $(hostname) =~ .*master.* ]]
then
  echo "[TASK 11] Pull required containers"
  kubeadm config images pull >/dev/null 2>&1
fi