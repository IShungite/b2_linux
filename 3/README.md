# TP3 : systemd

## I. Services systemd

### 1. Intro

🌞Utilisez la ligne de commande pour sortir les infos suivantes :

- afficher le nombre de services systemd dispos sur la machine
  ```
  systemctl list-unit-files -t service | grep .service | wc -l
  ```
- afficher le nombre de services systemd actifs ("running") sur la machine
  ```
  systemctl -t service --state=running | wc -l
  ```
- afficher le nombre de services systemd qui ont échoué ("failed") ou qui sont inactifs ("exited") sur la machine
  ```
  systemctl -t service --state=failed,exited | wc -l
  ```
- afficher la liste des services systemd qui démarrent automatiquement au boot ("enabled")
  ```
  systemctl list-unit-files -t service --state=enabled
  ```

### 2. Analyse d'un service

🌞Etudiez le service nginx.service

- déterminer le path de l'unité nginx.service
  ```
  systemctl status nginx
    Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
  ```
- afficher son contenu et expliquer les lignes qui comportent :
  ```
  systemctl cat nginx
  ```
  - ExecStart
    ```
    ExecStart=/usr/sbin/nginx
    ```
    Commande qui est lancé lorsqu'on tape `systemctl start nignx`
  - ExecStartPre
    ```
    ExecStartPre=/usr/bin/rm -f /run/nginx.pid
    ExecStartPre=/usr/sbin/nginx -t
    ```
    Commandes qui sont lancées avant le ExecStart
  - PIDFile
    ```
    PIDFile=/run/nginx.pid
    ```
    Le fichier où sera stocké le pid du processus
  - Type
    ```
    Type=forking
    ```
    Le type `forking` permet de dire aux processus enfants que le process est toujours en cours quand il est quitté.
  - ExecReload
    ```
    ExecReload=/bin/kill -s HUP $MAINPID
    ```
    Commande qui est lancé lorsqu'on tape `systemctl reload nginc`
  - Description
    ```
    Description=The nginx HTTP and reverse proxy server
    ```
    Description du service, sera affiché sur la première ligne lorsqu'on tape `systemctl status nginx`
  - After
    ```
    After=network.target remote-fs.target nss-lookup.target
    ```
    Le service se lancera après tous les services qui sont sur cette ligne

🌞Listez tous les services qui contiennent la ligne WantedBy=multi-user.target

```
grep -rnw /usr/lib/systemd/system /etc/systemd/system /run/systemd/system /usr/lib/systemd/system -e 'WantedBy=multi-user.target'
```

### 3. Création d'un service

#### A. Serveur web

🌞 Créez une unité de service qui lance un serveur web

- la commande pour lancer le serveur web est python3 -m http.server <PORT>
  ```
  ExecStart=/usr/bin/python3 -m http.server ${WEB_PORT}
  ```
- quand le service se lance, le port doit s'ouvrir juste avant dans le firewall
  ```
  ExecStartPre=+/usr/bin/firewall-cmd --add-port=${WEB_PORT}/tcp --permanent
  ```
  On ajout un `+` pour donner les droits
- quand le service se termine, le port doit se fermer juste après dans le firewall
  ```
  ExecStop=+/usr/bin/firewall-cmd --remove-port=${WEB_PORT}/tcp --permanent
  ```
- un utilisateur dédié doit lancer le service
  ```
  User=web
  ```
- le service doit comporter une description
  ```
  Description=Web server description
  ```
- le port utilisé doit être défini dans une variable d'environnement (avec la clause Environment=)
  `Environment="WEB_PORT=8080"`
  fichier complet :

```
[Unit]
Description=Web server description

[Service]
User=web
Environment="WEB_PORT=8080"
ExecStartPre=+/usr/bin/firewall-cmd --add-port=${WEB_PORT}/tcp --permanent
ExecStartPre=+/usr/bin/firewall-cmd --reload
ExecStart=/usr/bin/python3 -m http.server ${WEB_PORT}
ExecStop=+/usr/bin/firewall-cmd --remove-port=${WEB_PORT}/tcp --permanent
ExecStop=+/usr/bin/firewall-cmd --reload

[Install]
WantedBy=multi-user.target
```

🌞 Lancer le service

- prouver qu'il est en cours de fonctionnement pour systemd

  ```
  [vagrant@node1 ~]$ sudo systemctl status web
  ? web.service - Web server description
  Loaded: loaded (/etc/systemd/system/web.service; static; vendor preset: disabled)
  Active: active (running) since Mon 2020-10-05 10:13:16 UTC; 2s ago
  Main PID: 4689 (python3)
  CGroup: /system.slice/web.service
          ?? 4689 /usr/bin/python3 -m http.server 8080
  ```

- prouver que le serveur web est bien fonctionnel
  ```
  [vagrant@node1 ~]$ curl localhost:8080
  <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
  <html>
  <head>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
  <title>Directory listing for /</title>
  </head>
  <body>
  <h1>Directory listing for /</h1>
  <hr>
  <ul>
  <li><a href="bin/">bin@</a></li>
  <li><a href="boot/">boot/</a></li>
  <li><a href="dev/">dev/</a></li>
  <li><a href="etc/">etc/</a></li>
  <li><a href="home/">home/</a></li>
  <li><a href="lib/">lib@</a></li>
  <li><a href="lib64/">lib64@</a></li>
  <li><a href="media/">media/</a></li>
  <li><a href="mnt/">mnt/</a></li>
  <li><a href="opt/">opt/</a></li>
  <li><a href="proc/">proc/</a></li>
  <li><a href="root/">root/</a></li>
  <li><a href="run/">run/</a></li>
  <li><a href="sbin/">sbin@</a></li>
  <li><a href="srv/">srv/</a></li>
  <li><a href="swapfile">swapfile</a></li>
  <li><a href="sys/">sys/</a></li>
  <li><a href="tmp/">tmp/</a></li>
  <li><a href="usr/">usr/</a></li>
  <li><a href="var/">var/</a></li>
  </ul>
  <hr>
  </body>
  </html>
  ```

#### B. Sauvegarde

🌞 Créez une unité de service qui déclenche une sauvegarde avec votre script

- le script doit se lancer sous l'identité d'un utilisateur dédié
  ```
  User=backup
  ```
- le service doit utiliser un PID file
  ```
  PIDFile=/run/backup.pid
  ```
- le service doit posséder une description
  ```
  Description=Backup description
  ```
- vous éclaterez votre script en trois scripts :

  - un script qui se lance AVANT la sauvegarde, qui effectue les tests

    [Voir ici](scripts/backup_pre.sh)

  - script de sauvegarde

    [Voir ici](scripts/backup.sh)

  - un script qui s'exécute APRES la sauvegarde, et qui effectue la rotation (ne garder que les 7 sauvegardes les plus récentes)

    [Voir ici](scripts/backup_post.sh)

  - une fois fait, utilisez les clauses ExecStartPre, ExecStart et ExecStartPost pour les lancer au bon moment
    ```
    ExecStartPre=/usr/bin/sh /usr/scripts/backup_post.sh
    ExecStart=/usr/bin/sh /usr/scripts/backup.sh
    ExecStartPost=/usr/bin/sh /usr/scripts/backup_post.sh
    ```

backup.service complet

```
[Unit]
Description=Backup description
After=firewalld.service

[Service]
User=backup
PIDFile=/run/backup.pid
ExecStartPre=/usr/bin/rm -f /run/backup.pid
ExecStartPre=/usr/bin/sh /srv/backup_scripts/backup_post.sh
ExecStart=/usr/bin/sh /srv/backup_scripts/backup.sh /srv/site1
ExecStart=/usr/bin/sh /srv/backup_scripts/backup.sh /srv/site2
ExecStartPost=/usr/bin/sh /srv/backup_scripts/backup_post.sh

[Install]
WantedBy=multi-user.target
```

🌞Ecrire un fichier `.timer` systemd

```
[Unit]
Description=1 hour timer for backup

[Timer]
OnBootSec=0min
OnCalendar=0/1:00:00
Unit=one-hour.service

[Install]
WantedBy=basic.target
```

## II. Autres features

### 1. Gestion de boot

🌞 Utilisez systemd-analyze plot pour récupérer une diagramme du boot, au format SVG

- il est possible de rediriger l'output de cette commande pour créer un fichier .svg

```
systemd-analyze plot > plot.svg
```

- déterminer les 3 services les plus lents à démarrer

```
tuned.service (2.640s)
sshd-keygen@rsa.service (1.687s)
sssd.service (1.583s)
```

### 2. Gestion de l'heure-

🌞 Utilisez la commande timedatectl

```
[vagrant@node1 ~]$ timedatectl
               Local time: Wed 2020-10-07 09:20:12 UTC
           Universal time: Wed 2020-10-07 09:20:12 UTC
                 RTC time: Wed 2020-10-07 09:20:10
                Time zone: UTC (UTC, +0000)
System clock synchronized: yes
              NTP service: active
          RTC in local TZ: no
```

- déterminer votre fuseau horaire

```
Time zone: UTC (UTC, +0000)
```

- déterminer si vous êtes synchronisés avec un serveur NTP

```
NTP service: active
```

- changer le fuseau horaire

```
timedatectl set-timezone Europe/Paris
```

### 3. Gestion des noms et de la résolution de noms

🌞 Utilisez hostnamectl

```
[vagrant@node1 ~]$ hostnamectl
   Static hostname: node1.tp3.b2
         Icon name: computer-vm
           Chassis: vm
        Machine ID: 9c2685bab4ef42e4a3196e242a8dc16b
           Boot ID: 5ff82478e3214137bf4805c28acb9d6f
    Virtualization: oracle
  Operating System: CentOS Linux 8 (Core)
       CPE OS Name: cpe:/o:centos:centos:8
            Kernel: Linux 4.18.0-80.el8.x86_64
      Architecture: x86-64
```

- déterminer votre hostname actuel

```
Static hostname: node1.tp3.b2
```

- changer votre hostname

```
hostnamectl set-hostname node1.tp3.b2.newhostname
```
