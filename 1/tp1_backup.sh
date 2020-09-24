#!/bin/bash
function compress {
    SITE=$( echo $1 | cut -d'/' -f3)
    tar -zcvf ${SITE}_$(date "+%Y%m%d_%H%M").tar.gz -P /srv/${SITE} >> ${LOG_FILE}
    delete_oldest ${SITE}

}
function compress_all {
    compress ${PATH_SITE1}
    compress ${PATH_SITE2}
}
function delete_oldest {
    OLDEST_FILES=$(ls -1t $1* | tail -n +8)
    for file in ${OLDEST_FILES}; do
        rm -f ${file}
        echo "${file} was deleted" >> ${LOG_FILE}
    done;
}

PATH_ARG=$1

PATH_SITE1="/srv/site1"
PATH_SITE2="/srv/site2"

LOG_FILE="/var/log/backup.log"

echo "---- BACKUP SCRIPT START ----" >> ${LOG_FILE}

if [ ! -z ${PATH_ARG} ] && ([ ${PATH_ARG} == ${PATH_SITE1} ] || [ ${PATH_ARG} == ${PATH_SITE2} ]); then
    compress ${PATH_ARG}
elif [ ! -z ${PATH_ARG} ] && [ ${PATH_ARG} == "all" ]; then
    compress_all
else
    echo "Bad argument, use /srv/site1 | /srv/site2 | all"
    echo "---- FAIL | BACKUP SCRIPT END ----" >> ${LOG_FILE}
    exit 1
fi

echo "---- BACKUP SCRIPT END ----" >> ${LOG_FILE}
exit 0