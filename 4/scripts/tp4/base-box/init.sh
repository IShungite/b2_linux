yum update -y
yum upgrade -y
yum install -y vim
sudo systemctl enable firewalld
sudo systemctl start firewalld
sudo setenforce 0
sed -i "s/SELINUX=enforcing/SELINUX=permissive/" /etc/selinux/config