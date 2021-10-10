# Install Openssh server
echo "[TASK 1] Install and configure ssh"
apk update && apk add --no-cache openssh >/dev/null 2>&1 
rc-update add sshd >/dev/null 2>&1
sed -i 's/^PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config
echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config 
service sshd restart >/dev/null 2>&1

# Set Root password
echo "[TASK 2] Set root password"
echo -e "abc12345\nabc12345" | passwd root 
echo "export TERM=xterm" >> /etc/bash.bashrc

echo "[TASK 3] Update /etc/hosts file"
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

echo "[TASK 4] Install ucarp and haproxy"
apk update && apk add --no-cache ucarp haproxy >/dev/null 2>&1 

echo "[TASK 5] Configure ucarp"
ln -s /etc/init.d/ucarp /etc/init.d/ucarp.eth0
cat > /etc/ucarp/ucarp.pass <<EOF
abc12345
EOF

echo "[TASK 6] Configure haproxy"
cat >> /etc/haproxy/haproxy.cfg <<EOF

frontend traefik_http_bind
    bind *:80
#    bind [::]:80
    mode tcp
    option tcplog
    default_backend router_traefik_http

frontend traefik_https_bind
    bind *:443
#    bind [::]:443
    mode tcp
    option tcplog
    default_backend router_traefik_https

frontend k8s_bind 
    bind *:6443 
#    bind [::]:6443
    mode tcp
    option tcplog
    default_backend router_k8s

frontend nfs_bind 
    bind *:2049 
#    bind [::]:2049
    mode tcp
    option tcplog
    default_backend router_nfs

frontend postgres_bind
    bind *:5432
    mode tcp
    option tcplog
    default_backend router_postgres

frontend mongodb_bind
    bind *:27017
    mode tcp
    option tcplog
    default_backend router_mongodb

frontend redis_bind
    bind *:6379
    mode tcp
    option tcplog
    default_backend router_redis

backend router_traefik_http
    mode tcp
    option tcp-check
    server traefik traefik.cams7.local:80 check

backend router_traefik_https
    mode tcp
    option tcp-check
    server traefik traefik.cams7.local:443 check

backend router_k8s
    mode tcp 
    option tcp-check 
    balance roundrobin 
    server kmaster111 kmaster111.cams7-vaio.local:6443 check fall 3 rise 2
#    server kmaster112 kmaster112.cams7-vaio.local:6443 check fall 3 rise 2
#    server kmaster113 kmaster113.cams7-vaio.local:6443 check fall 3 rise 2
    server kmaster114 kmaster114.cams7-dell.local:6443 check fall 3 rise 2
#    server kmaster115 kmaster115.cams7-dell.local:6443 check fall 3 rise 2
#    server kmaster116 kmaster116.cams7-dell.local:6443 check fall 3 rise 2
    server kmaster117 kmaster117.cams7-qbex.local:6443 check fall 3 rise 2
#    server kmaster118 kmaster118.cams7-qbex.local:6443 check fall 3 rise 2
#    server kmaster119 kmaster119.cams7-qbex.local:6443 check fall 3 rise 2

backend router_nfs
    mode tcp
    option tcp-check
    server nfs nfs.cams7.local:2049 check

backend router_postgres
    mode tcp
    option tcp-check
    server nfs traefik.cams7.local:5432 check

backend router_mongodb
    mode tcp
    option tcp-check
    server nfs traefik.cams7.local:27017 check

backend router_redis
    mode tcp
    option tcp-check
    server nfs traefik.cams7.local:6379 check
EOF

rc-update add haproxy