#!/bin/bash
# IShungite
# 30/09/20

nginxUser="nginx_user"
nginxGroup="nginx_group"

backupUser="backup_user"
backupGroup="backup_group"
backupPath="/srv/backup"

# Openssl config
sslCountry=""
sslState=""
sslLocality=""
sslOrganization=""
sslOrganizationalUnit=""
sslCommonName="$HOSTNAME"
sslEmail=""

site1Path="/srv/site1"
site2Path="/srv/site2"

discordWebhook=""
discordDefaultChannel="netdata_alert"

useradd admin -m
usermod -aG wheel admin

mkdir "${site1Path}" "${site2Path}"

echo "SITE 1" > "${site1Path}/index.html"
echo "SITE 2" > "${site2Path}/index.html"

useradd ${nginxUser} -M -s /sbin/nologin
groupadd "${nginxGroup}"
gpasswd -a "${nginxUser}" "${nginxGroup}"

firewallStatus="$(systemctl is-active firewalld)"
if [ ! "${firewallStatus}" = "active" ]; then
    systemctl start firewalld
fi
firewall-cmd --add-port=80/tcp --permanent
firewall-cmd --add-port=443/tcp --permanent
firewall-cmd --add-port=19999/tcp --permanent  # Netdata
firewall-cmd --reload

openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 \
    -subj "/C=${sslCountry}/ST=${sslState}/L=${sslLocality}/O=${sslOrganization}/OU=${sslOrganizationalUnit}/CN=${sslCommonName}/emailAddress=${sslEmail}/" \
    -keyout /etc/pki/tls/private/$HOSTNAME.key \
    -out /etc/pki/tls/certs/$HOSTNAME.crt

chmod 400 /etc/pki/tls/private/$HOSTNAME.key
chown ${nginxUser}:${nginxGroup} /etc/pki/tls/private/$HOSTNAME.key
chmod 444 /etc/pki/tls/certs/$HOSTNAME.crt
chown ${nginxUser}:${nginxGroup} /etc/pki/tls/certs/$HOSTNAME.crt

chown ${nginxUser}:${nginxGroup} "${site1Path}" -R
chown ${nginxUser}:${nginxGroup} "${site2Path}" -R

chmod 700 "${site1Path}" "${site2Path}"
chmod 400 "${site1Path}/index.html" "${site2Path}/index.html"

echo "worker_processes 1;
error_log nginx_error.log;
pid /run/nginx.pid;
user ${nginxUser};

events {
    worker_connections 1024;
}

http {
    upstream netdata {
        server 127.0.0.1:19999;
        keepalive 64;
    }
    server {
        listen 80;
        server_name $HOSTNAME;
        
        location / {
              return 301 /site1;
        }

        location /site1 {
            alias ${site1Path};
        }

        location /site2 {
            alias ${site2Path};
        }

        location = /netdata {
            return 301 /netdata/;
        }
        location ~ /netdata/(?<ndpath>.*) {
            proxy_redirect off;
            proxy_set_header Host \$host;

            proxy_set_header X-Forwarded-Host \$host;
            proxy_set_header X-Forwarded-Server \$host;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_http_version 1.1;
            proxy_pass_request_headers on;
            proxy_set_header Connection \"keep-alive\";
            proxy_store off;
            proxy_pass http://netdata/\$ndpath\$is_args\$args;

            gzip on;
            gzip_proxied any;
            gzip_types *;
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
            alias ${site1Path};
        }

        location /site2 {
            alias ${site2Path};
        }

        location = /netdata {
            return 301 /netdata/;
        }
        location ~ /netdata/(?<ndpath>.*) {
            proxy_redirect off;
            proxy_set_header Host \$host;

            proxy_set_header X-Forwarded-Host \$host;
            proxy_set_header X-Forwarded-Server \$host;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_http_version 1.1;
            proxy_pass_request_headers on;
            proxy_set_header Connection \"keep-alive\";
            proxy_store off;
            proxy_pass http://netdata/\$ndpath\$is_args\$args;

            gzip on;
            gzip_proxied any;
            gzip_types *;
        }
    }
} " > /etc/nginx/nginx.conf

nginxStatus="$(systemctl is-active nginx)"
if [ "${nginxStatus}" = "active" ]; then
    systemctl restart nginx
else
    systemctl start nginx
fi

useradd ${backupUser} -M -s /sbin/nologin
groupadd "${backupGroup}"
gpasswd -a "${backupUser}" "${backupGroup}"

gpasswd -a ${backupUser} ${nginxGroup}
mkdir "${backupPath}"
chown ${backupUser}:${backupGroup} "${backupPath}"
chmod 750 "${backupPath}"
touch /var/log/backup.logs
chown ${backupUser}:${backupGroup} /var/log/backup.logs
chmod 600 /var/log/backup.logs

chmod 750 "${site1Path}" "${site2Path}"
chmod 440 "${site1Path}/index.html" "${site2Path}/index.html"

gpasswd -a ${nginxUser} ${backupGroup}

echo "[Unit]
Description=Start backup every hours

[Service]
User=backup
Restart=always
RestartSec=3600s
ExecStart=/bin/bash /srv/tp1_backup.sh all
" > /etc/systemd/system/backup.service
systemctl enable backup
systemctl start backup

bash <(curl -Ss https://my-netdata.io/kickstart.sh) --dont-wait

# Génération du fichier health_alarm_notify.conf
/etc/netdata/edit-config health_alarm_notify.conf
rm -rf /etc/netdata/.health_alarm_notify.conf.swp
# T'inquiète ça va bien se passer '-''

sed -i "s/DISCORD_WEBHOOK_URL=\"\"/DISCORD_WEBHOOK_URL=\"${discordWebhook}\"/" /etc/netdata/health_alarm_notify.conf
sed -i "s/DEFAULT_RECIPIENT_DISCORD=\"\"/DEFAULT_RECIPIENT_DISCORD=\"${discordDefaultChannel}\"/" /etc/netdata/health_alarm_notify.conf
