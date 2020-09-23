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

        `mkdir /srv/data1 /srv/data2`

    * Formatage des partitions

        `mkfs.ext4 /dev/data/lvol0`
        `mkfs.ext4 /dev/data/lvol1`
        
    * Montage des partitions

        `mount /dev/data/lvol0 /srv/data1`
        `mount /dev/data/lvol1 /srv/data2`

    * Définition d'un montage automatique lors du boot de la machine
        
        Ajout des lignes `/dev/data/lvol0 /srv/data1 ext4 defaults 0 0` et `/dev/data/lvol1 /srv/data2 ext4 defaults 0 0` dans `/etc/fstab`
    
    * Vérification

        ```bash
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

    ```bash
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

    ```bash
    [root@node2 ~]# hostname
    node2.tp1.
    ```

* Les machines doivent pouvoir se joindre par leurs noms respectifs

    * Ajout d'un host des VM

    ```bash
    [root@node2 ~]# cat /etc/hosts
    192.168.1.11 node1

    [root@node1 ~]# cat /etc/hosts
    192.168.1.12 node2
    ```

* Un utilisateur administrateur est créé sur les deux machines (il peut exécuter des commandes sudo en tant que root)

    * Ajout d'un utilisateur

    ```bash
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

    ```bash
    [admin@node1 ~]$ cat /etc/sysconfig/network-scripts/ifcfg-enp0s8
    NAME=enp0s8
    DEVICE=enp0s8

    BOOTPROTO=static
    ONBOOT=yes

    IPADDR=192.168.1.11
    NETMASK=255.255.255.0
    ```
    
    * Status de ssh

    ```bash
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


* le pare-feu est configuré pour bloquer toutes les connexions exceptées celles qui sont nécessaires

    * Affichage du pare-feu

    ```bash
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
