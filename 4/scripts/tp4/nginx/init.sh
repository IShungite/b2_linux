#!/bin/bash
# IShungite
# 13/10/2020


yum install -y epel-release
yum install -y nginx

echo "user nginx;

worker_processes 1;
error_log nginx_error.log;
pid /run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    server {

        listen 80;
        server_name git.example.com;

        location / {
            proxy_pass http://192.168.1.11:3000;
        }
    }
}" > /etc/nginx/nginx.conf

systemctl start nginx
systemctl enable nginx

firewall-cmd --add-port=80/tcp --permanent
firewall-cmd --reload