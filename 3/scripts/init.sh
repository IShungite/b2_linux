nginxUser="web"
nginxGroup="web"

site1Path="/srv/site1"
site2Path="/srv/site2"

backupUser="backup_user"
backupGroup="backup_group"
backupPath="/opt/backup/"

mkdir "${site1Path}" "${site2Path}"

echo "SITE 1" > "${site1Path}/index.html"
echo "SITE 2" > "${site2Path}/index.html"

useradd ${nginxUser} -M -s /sbin/nologin
groupadd "${nginxGroup}"
gpasswd -a "${nginxUser}" "${nginxGroup}"

chown ${nginxUser}:${nginxGroup} "${site1Path}" -R
chown ${nginxUser}:${nginxGroup} "${site2Path}" -R

useradd ${backupUser} -M -s /sbin/nologin
groupadd "${backupGroup}"
gpasswd -a "${backupUser}" "${backupGroup}"

gpasswd -a ${backupUser} ${nginxGroup}

mkdir "${backupPath}"
chown ${backupUser}:${backupGroup} "${backupPath}"
chmod 750 "${backupPath}"

chmod 750 "${site1Path}" "${site2Path}"
chmod 440 "${site1Path}/index.html" "${site2Path}/index.html"
