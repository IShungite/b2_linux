#!/bin/bash
# IShungite
# 30/09/20

nginxUser="nginx_user"
nginxGroup="nginx_group"

Openssl config
sslCountry=""
sslState=""
sslLocality=""
sslOrganization=""
sslOrganizationalUnit=""
sslCommonName="$HOSTNAME"
sslEmail=""

pathSite1="/srv/site1"
pathSite2="/srv/site2"

mkdir "${pathSite1}" "${pathSite2}"

echo "SITE 1" > "${pathSite1}/index.html"
echo "SITE 2" > "${pathSite2}/index.html"

useradd ${nginxUser} -M -s /sbin/nologin

groupadd "${nginxGroup}"
gpasswd -a "${nginxUser}" "${nginxGroup}"

firewallStatus="$(systemctl is-active firewalld)"
if [ ! "${firewallStatus}" = "active" ]; then
    systemctl start firewalld
fi
firewall-cmd --add-port=80/tcp --permanent
firewall-cmd --add-port=443/tcp --permanent
firewall-cmd --reload

openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 \
    -subj "/C=${sslCountry}/ST=${sslState}/L=${sslLocality}/O=${sslOrganization}/OU=${sslOrganizationalUnit}/CN=${sslCommonName}/emailAddress=${sslEmail}/" \
    -keyout /etc/pki/tls/private/$HOSTNAME.key \
    -out /etc/pki/tls/certs/$HOSTNAME.crt

chmod 400 /etc/pki/tls/private/$HOSTNAME.key
chown ${nginxUser}:${nginxGroup} /etc/pki/tls/private/$HOSTNAME.key
chmod 444 /etc/pki/tls/certs/$HOSTNAME.crt
chown ${nginxUser}:${nginxGroup} /etc/pki/tls/certs/$HOSTNAME.crt

chown ${nginxUser}:${nginxGroup} "${pathSite1}" -R
chown ${nginxUser}:${nginxGroup} "${pathSite2}" -R

chmod 700 "${pathSite1}" "${pathSite2}"
chmod 400 "${pathSite1}/index.html" "${pathSite2}/index.html"

echo "worker_processes 1;
error_log nginx_error.log;
pid /run/nginx.pid;
user ${nginxUser};

events {
    worker_connections 1024;
}

http {
    server {
        listen 80;
        server_name $HOSTNAME;
        
        location / {
              return 301 /site1;
        }

        location /site1 {
            alias ${pathSite1};
        }

        location /site2 {
            alias ${pathSite2};
        }
    }
    server {
        listen 443 ssl;

        server_name $HOSTNAME;
        ssl_certificate /etc/pki/tls/certs/$HOSTNAME.crt;
        ssl_certificate_key /etc/pki/tls/private/$HOSTNAME.key;
        
        location / {
              return 301 /site1;
        }

        location /site1 {
            alias ${pathSite1};
        }

        location /site2 {
            alias ${pathSite2};
        }
    }
} " > /etc/nginx/nginx.conf

nginxStatus="$(systemctl is-active nginx)"
if [ "${nginxStatus}" = "active" ]; then
    systemctl restart nginx
else
    systemctl start nginx
fi