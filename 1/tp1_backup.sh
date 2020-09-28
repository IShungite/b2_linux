#!/bin/bash

# === CONSTANT ===

PATH_SITE1="/srv/site1"
PATH_SITE2="/srv/site2"

PATH_BACKUP="/srv/backup/"

LOG_FILE="/var/log/backup.log"

PATH_ARG=$1

# === FUNCTION ===

function compress {
    SITE=$( echo $1 | cut -d'/' -f3)
    {
        tar -zcvpf ${PATH_BACKUP}${SITE}_$(date "+%Y%m%d_%H%M").tar.gz -P /srv/${SITE} 2>> ${LOG_FILE} 1>/dev/null
        delete_oldest ${SITE}
        echo $'\t' "${SITE} was compressed on $(date "+%b %m, %Y at %Hh%M")" >> ${LOG_FILE}
    } || {
        echo "/!\ - ERROR WHILE COMPRESS"
    }

}
function compress_all {
    compress ${PATH_SITE1}
    compress ${PATH_SITE2}
}
function delete_oldest {
    OLDEST_FILES=$(ls -1t ${PATH_BACKUP}$1* | grep .tar.gz | tail -n +8)
    for file in ${OLDEST_FILES}; do
        rm -f ${file}
        echo $'\t' "$(echo ${file} | cut -d'/' -f4) was deleted" >> ${LOG_FILE}
    done;
}

# === START ===

echo $'\n' "---- BACKUP SCRIPT START ----" >> ${LOG_FILE}

if [ ! -z ${PATH_ARG} ] && ([ ${PATH_ARG} == ${PATH_SITE1} ] || [ ${PATH_ARG} == ${PATH_SITE2} ]); then
    compress ${PATH_ARG}
elif [ ! -z ${PATH_ARG} ] && [ ${PATH_ARG} == "all" ]; then
    compress_all
else
    echo "Bad argument, use ${PATH_SITE1} | ${PATH_SITE1} | all"
    echo "---- BAD ARGUMENT | BACKUP SCRIPT END ----" >> ${LOG_FILE}
    exit 1
fi

echo "---- BACKUP SCRIPT END ----" >> ${LOG_FILE}
exit 0

# === END ===