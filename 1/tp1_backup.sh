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
    tar -zcvf ${PATH_BACKUP}${SITE}_$(date "+%Y%m%d_%H%M").tar.gz -P /srv/${SITE} >> ${LOG_FILE}
    delete_oldest ${SITE}

}
function compress_all {
    compress ${PATH_SITE1}
    compress ${PATH_SITE2}
}
function delete_oldest {
    OLDEST_FILES=$(ls -1t ${PATH_BACKUP}$1* | grep .tar.gz | tail -n +8)
    for file in ${OLDEST_FILES}; do
        rm -f ${file}
        echo "${file} was deleted" >> ${LOG_FILE}
    done;
}

# === START ===

echo "---- BACKUP SCRIPT START ----" >> ${LOG_FILE}

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