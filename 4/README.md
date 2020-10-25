# TP4 : Déploiement de services

## 0. Prerequisites

La box utilisée lors du tp est une Centos 7, avec ce [script](scripts/tp4/base-box/init.sh) de lancé.

## I. Consignes générales

### Liste des hôtes

| Name             | IP           | Rôle        |
| ---------------- | ------------ | ----------- |
| `gitea.tp4.b2`   | 192.168.1.11 | Gitea       |
| `mariadb.tp4.b2` | 192.168.1.12 | MariaDB     |
| `nginx.tp4.b2`   | 192.168.1.13 | Nginx       |
| `nfs.tp4.b2`     | 192.168.1.14 | Serveur NFS |
