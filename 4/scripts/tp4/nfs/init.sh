#!/bin/bash
# IShungite
# 13/10/2020

yum install -y nfs-utils

mkdir /srv/folder1
chmod -R 755 /srv/folder1
chown nfsnobody:nfsnobody /srv/folder1/

echo "/srv/folder1 192.168.1.11(rw,sync)" >> /etc/exports

systemctl enable nfs-server
systemctl restart nfs-server