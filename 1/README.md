# TP1 : Déploiement classique

## 0. Prérequis

**Setup de deux machines CentOS7 configurée de façon basique.**

* Partitionnement

    * Création du volume physique

        `pvcreate /dev/sdb`

    * Création du Volume Groupe 
        
        `vgcreate data /dev/sdb`

    * Création des Logical Volumes

        `lvcreate -L 2G data`
        `lvcreate -l +100%FREE data`

    * Création des dossiers de montage

        `mkdir /srv/site1 /srv/site2`

    * Formatage des partitions

        `mkfs.ext4 /dev/data/lvol0`
        `mkfs.ext4 /dev/data/lvol1`
        
    * Montage des partitions

        `mount /dev/data/lvol0 /srv/site1`
        `mount /dev/data/lvol1 /srv/site2`

    * Définition d'un montage automatique lors du boot de la machine
        
        Ajout des lignes `/dev/data/lvol0 /srv/site1 ext4 defaults 0 0` et `/dev/data/lvol1 /srv/site2 ext4 defaults 0 0` dans `/etc/fstab`
    
    * Vérification

        ```
        [root@node1 ~]# mount -av
        /                        : ignored
        /boot                    : already mounted
        swap                     : ignored
        /srv/data1               : already mounted
        /srv/data2               : already mounted
        ```

* Un accès internet

    * Activation de la carte NAT

* Un accès à un réseau local (les deux machines peuvent se ping)

    * Ping entre les VM

        ```
        [root@node1 ~]# ping 192.168.1.12
        PING 192.168.1.12 (192.168.1.12) 56(84) bytes of data.
        64 bytes from 192.168.1.12: icmp_seq=1 ttl=64 time=0.629 ms
        64 bytes from 192.168.1.12: icmp_seq=2 ttl=64 time=0.976 ms

        [root@node2 ~]# ping 192.168.1.11
        PING 192.168.1.11 (192.168.1.11) 56(84) bytes of data.
        64 bytes from 192.168.1.11: icmp_seq=1 ttl=64 time=0.434 ms
        64 bytes from 192.168.1.11: icmp_seq=2 ttl=64 time=0.470 ms
        ```
  
* Les machines doivent avoir un nom

    * Hostname des deux VM

        ```
        [root@node2 ~]# hostname
        node2.tp1.
        ```

* Les machines doivent pouvoir se joindre par leurs noms respectifs

    * Ajout d'un host des VM

        ```
        [root@node1 ~]# cat /etc/hosts
        192.168.1.12 node2.tp1.b2
        [root@node1 ~]# ping node2.tp1.b2
        PING node2.tp1.b2 (192.168.1.12) 56(84) bytes of data.
        64 bytes from node2.tp1.b2 (192.168.1.12): icmp_seq=1 ttl=64 time=0.583 ms

        [root@node2 ~]# cat /etc/hosts
        192.168.1.11 node1.tp1.b2
        [root@node2 ~]# ping node1.tp1.b2
        PING node1.tp1.b2 (192.168.1.11) 56(84) bytes of data.
        64 bytes from node1.tp1.b2 (192.168.1.11): icmp_seq=1 ttl=64 time=0.399 ms

        ```

* Un utilisateur administrateur est créé sur les deux machines (il peut exécuter des commandes sudo en tant que root)

    * Ajout d'un utilisateur

        ```
        [root@node1 ~]# adduser admin
        [root@node1 ~]# passwd admin
        Changing password for user admin.
        New password:
        BAD PASSWORD: The password is shorter than 8 characters
        Retype new password:
        passwd: all authentication tokens updated successfully.
        [root@node1 ~]# usermod -aG wheel admin
        [admin@node1 ~]$ sudo whoami
        root
        ```

* Vous n'utilisez QUE ssh pour administrer les machines

    * Fichier config de enp0s8

        ```
        [admin@node1 ~]$ cat /etc/sysconfig/network-scripts/ifcfg-enp0s8
        NAME=enp0s8
        DEVICE=enp0s8

        BOOTPROTO=static
        ONBOOT=yes

        IPADDR=192.168.1.11
        NETMASK=255.255.255.0
        ```
        
        * Status de ssh

        ```
        [admin@node1 ~]$ systemctl status sshd
        ? sshd.service - OpenSSH server daemon
        Loaded: loaded (/usr/lib/systemd/system/sshd.service; enabled; vendor preset: enabled)
        Active: active (running) since Wed 2020-09-23 12:21:22 CEST; 22min ago
            Docs: man:sshd(8)
                man:sshd_config(5)
        Main PID: 1081 (sshd)
        CGroup: /system.slice/sshd.service
                ??1081 /usr/sbin/sshd -D

        Sep 23 12:21:22 node1.tp1.b2 systemd[1]: Starting OpenSSH server daemon...
        Sep 23 12:21:22 node1.tp1.b2 sshd[1081]: Server listening on 0.0.0.0 port 22.
        Sep 23 12:21:22 node1.tp1.b2 sshd[1081]: Server listening on :: port 22.
        Sep 23 12:21:22 node1.tp1.b2 systemd[1]: Started OpenSSH server daemon.
        Sep 23 12:22:57 node1.tp1.b2 sshd[1346]: Accepted password for root from 192.168.1.1 port 52894 ssh2
        Sep 23 12:31:53 node1.tp1.b2 sshd[1373]: Accepted password for root from 192.168.1.1 port 52934 ssh2
        ```

    * Setup des des clés ssh

        **Sur le serveur**
        ```
        [root@node1 ~]# mkdir ~/.ssh
        [root@node1 ~]# touch ~/.ssh/authorized_keys
        [root@node1 ~]# chmod 700 ~/.ssh
        [root@node1 ~]# chmod 600 ~/.ssh/authorized_keys
        ```
        Modification du fichier ``/etc/ssh/sshd_config`
        ```
            PubkeyAuthentication yes
        ```

        **Sur le client**
        ```powershell
        PS C:\Users\ianis> ssh-keygen
        Generating public/private rsa key pair.
        Enter file in which to save the key (C:\Users\ianis/.ssh/id_rsa): C:\Users\ianis/.ssh/id_rsa_linux
        Enter passphrase (empty for no passphrase):
        Enter same passphrase again:
        Your identification has been saved in C:\Users\ianis/.ssh/id_rsa_linux.
        Your public key has been saved in C:\Users\ianis/.ssh/id_rsa_linux.pub.

        PS C:\Users\ianis> scp C:\Users\ianis/.ssh/id_rsa_linux.pub root@192.168.1.11:.ssh/authorized_keys
        root@192.168.1.11's password:
        id_rsa_linux.pub                                                                      100%  398   202.3KB/s   00:00
        ```

        Ajout dans le fichier de config de ssh (C:\Users\ianis\\.ssh\config) :
        ```
        Host 192.168.1.11
            IdentityFile C:\Users\ianis\.ssh\id_rsa_linux
        Host 192.168.1.12
            IdentityFile C:\Users\ianis\.ssh\id_rsa_linux
        ```


* le pare-feu est configuré pour bloquer toutes les connexions exceptées celles qui sont nécessaires

    * Affichage du pare-feu

        ```
        [root@node1 ~]# firewall-cmd --list-all
        public (active)
        target: default
        icmp-block-inversion: no
        interfaces: enp0s3 enp0s8
        sources:
        services: dhcpv6-client ssh
        ports: 22/tcp
        protocols:
        masquerade: yes
        forward-ports:
        source-ports:
        icmp-blocks:
        rich rules:
        ```

## I. Setup serveur Web

* Installer le serveur web NGINX sur node1.tp1.b2 (avec une commande yum install).
  
    ```
    [root@node1 ~]# yum install -y epel-release
    [root@node1 ~]# yum –y install nginx
    ```

* Faites en sorte que :
  
  * NGINX servent deux sites web, chacun possède un fichier unique index.html

    ```
    [root@node1 ~]# touch /srv/site1/index.html
    [root@node1 ~]# touch /srv/site2/index.html
    ```

  * Les sites web doivent se trouver dans /srv/site1 et /srv/site2
    * Les permissions sur ces dossiers doivent être le plus restrictif possible

        ```
        dr-x------.  3 nginx_user nginx_group 4096 Sep 24 10:12 site1
        dr-x------.  3 nginx_user nginx_group 4096 Sep 24 10:12 site2

        -r--------. 1 nginx_user nginx_group    13 Sep 24 10:12 index.html
        ```
    * Ces dossiers doivent appartenir à un utilisateur et un groupe spécifique

        Ajout d'un utilisateur `nginx_user` ayant pour mot de passe `nginx_user`
        ```
        [root@node1 ~]# adduser nginx_user
        [root@node1 ~]# passwd nginx_user

        [root@node1 ~]# groupadd nginx_group

        [root@node1 ~]# gpasswd -a nginx_user nginx_group

        [root@node1 ~]# chown nginx_user:nginx_group /srv/site1
        [root@node1 ~]# chown nginx_user:nginx_group /srv/site2
        [root@node1 ~]# chown nginx_user:nginx_group /srv/site1/index.html
        [root@node1 ~]# chown nginx_user:nginx_group /srv/site2/index.html
        ```

    * les sites doivent être servis en HTTPS sur le port 443 et en HTTP sur le port 80
        
        * n'oubliez pas d'ouvrir les ports firewall

            ```
            [root@node1 ~]# firewall-cmd --add-port=443/tcp --permanent
            success
            [root@node1 ~]# firewall-cmd --add-port=80/tcp --permanent
            success
            [root@node1 ~]# firewall-cmd --reload
            ```

        Génération d'une clé et d'un certificat
        ```
        [root@node1 ~]# openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 -keyout server.key -out server.crt
        Generating a 2048 bit RSA private key
        ..+++
        ......+++
        writing new private key to 'server.key'
        -----
        You are about to be asked to enter information that will be incorporated
        into your certificate request.
        What you are about to enter is what is called a Distinguished Name or a DN.
        There are quite a few fields but you can leave some blank
        For some fields there will be a default value,
        If you enter '.', the field will be left blank.
        -----
        Country Name (2 letter code) [XX]:
        State or Province Name (full name) []:
        Locality Name (eg, city) [Default City]:
        Organization Name (eg, company) [Default Company Ltd]:
        Organizational Unit Name (eg, section) []:
        Common Name (eg, your name or your server's hostname) []:node1.tp1.b2
        Email Address []:

        [root@node1 ~]# mv server.crt /etc/pki/tls/certs/node1.tp1.b2.crt
        [root@node1 ~]# mv server.key /etc/pki/tls/private/node1.tp1.b2.key
        ```

        Fichier de configuration de nginx
        ```
        [root@node1 ~]# cat /etc/nginx/nginx.conf
        user nginx_user;

        worker_processes 1;
        error_log nginx_error.log;
        pid /run/nginx.pid;

        events {
            worker_connections 1024;
        }

        http {
            server {
                listen 80;

                server_name node1.tp1.b2;

                location / {
                    return 301 /site1;
                }

                location /site1 {
                    alias /srv/site1;
                }
                location /site2 {
                    alias /srv/site2;
                }
            }
            server {
                listen 443 ssl;

                server_name node1.tp1.b2;
                ssl_certificate /etc/pki/tls/certs/node1.tp1.b2.crt;
                ssl_certificate_key /etc/pki/tls/private/node1.tp1.b2.key;

                location / {
                    return 301 /site1;
                }

                location /site1 {
                    alias /srv/site1;
                }
                location /site2 {
                    alias /srv/site2;
                }
            }
        }
        ```
*  Prouver que la machine node2 peut joindre les deux sites web

    ```
    [root@node2 ~]# curl -kL https://node1.tp1.b2/site1
    SITE 1
    [root@node2 ~]# curl -kL https://node1.tp1.b2/site2
    SITE 2
    ```

## II. Script de sauvegarde

* Ecrire un script

    **Caractéristiques du script**
    * s'appelle `tp1_backup.sh`
    * sauvegarde les deux sites web
    * c'est à dire qu'il crée une archive compressée pour chacun des sites
    * les noms des archives contiennent le nom du site sauvegardé ainsi que la date et heure de la sauvegarde
    * par exemple `site1_20200923_2358` (pour le 23 Septembre 2020 à 23h58)
    * Garde que 7 exemplaires de sauvegardes
    * à la huitième sauvegarde réalisée, la plus ancienne est supprimée
    * Le script sauvegarde un seul site à la fois en passant le dossier par argument
    * on peut donc appeler le script en faisant `tp1_backup.sh /srv/site1` afin de déclencher une sauvegarde de `/srv/site1`
    * Le script peut sauvegarder tous les sites en passant `all` comme argument
    * Le script écrit les logs dans le fichier `/var/log/backup.log`
    [Voir le script](tp1_backup.sh)

* Ajout d'un utilisateur `backup` ainsi que ses compléments necessaires au bon fonctionnement du script
  
    ```
    [root@node1 ~]# adduser backup
    [root@node1 ~]# passwd backup
    ```
    On ajoute le groupe nginx_group à l'utilisateur backup pour qu'il puisse intéragire avec les sites.
    ```
    [root@node1 ~]# gpasswd -a backup nginx_group
    ```
    Création d'un dossier `backup` où sera stocké les .tar.gz
    ```
    [root@node1 ~]# mkdir /srv/backup
    [root@node1 ~]# chown backup:backup /srv/backup
    [root@node1 ~]# chmod 700 /srv/backup
    ```
    Création d'un fichier de log où les logs du script seront stockés
    ```
    [root@node1 ~]# touch /var/log/backup.logs
    [root@node1 ~]# chown backup:backup /var/log/backup.logs
    [root@node1 ~]# chmod 700 /var/log/backup.logs
    ```
    Modification des droits des dossiers/fichiers
    ```
    [root@node1 ~]# ls -al /srv
    drwx------.  2 backup     backup       278 Sep 25 19:06 backup
    dr-xr-x---.  3 nginx_user nginx_group 4096 Sep 24 12:01 site1
    dr-xr-x---.  3 nginx_user nginx_group 4096 Sep 24 12:01 site2
    -rwx------.  1 backup     backup      1159 Sep 25 18:20 tp1_backup.sh

    [root@node1 ~]# ls -al /srv/site1
    -r--r-----. 1 nginx_user nginx_group     7 Sep 24 12:01 index.html
    dr--r-----. 2 nginx_user nginx_group 16384 Sep 23 11:42 lost+found
    ```


* Utiliser la crontab pour que le script s'exécute automatiquement toutes les heures.

    Modification du crontab de l'utilisateur `backup` avec la commande `crontab -u backup -e`, en ajoutant la ligne `0 * * * * sh /srv/tp1_backup.sh all` pour éxecuter le script toutes les heures.

* Créer une unité systemd qui permet de déclencher le script de backup

    Création du service
    ```
    [root@node1 ~]# vim /etc/systemd/system/backup.service
    [Unit]
    Description=Start backup every hours

    [Service]
    User=backup
    Restart=always
    RestartSec=3600s
    ExecStart=/bin/bash /srv/tp1_backup.sh all

    [root@node1 ~]# systemctl start backup
    [root@node1 ~]# systemctl status backup
    ? backup.service - Start backup every hours
    Loaded: loaded (/etc/systemd/system/backup.service; static; vendor preset: disabled)
    Active: activating (auto-restart) since Fri 2020-09-25 21:22:47 CEST; 6s ago
    Main PID: 6136 (code=exited, status=0/SUCCESS)
    ```
