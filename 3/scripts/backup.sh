#!/bin/bash
# it4
# 23/09/2020
# Simple backup script

## VARIABLES

# Colors :D
declare -r NC="\e[0m"
declare -r B="\e[1m"
declare -r RED="\e[31m"
declare -r GRE="\e[32m"

# Target directory : the one we want to backup
declare -r target_path="${1}"
declare -r target_dirname=$(awk -F'/' '{ print $NF }' <<< "${target_path%/}")

# Craft the backup full path and name
declare -r backup_destination_dir="/opt/backup/"
declare -r backup_date="$(date +%y%m%d_%H%M%S)"
declare -r backup_filename="${target_dirname}_${backup_date}.tar.gz"
declare -r backup_destination_path="${backup_destination_dir}/${backup_filename}"

# Informations about the User that must run this script
declare -r backup_user_name="backup"
declare -ri backup_user_uid=1003
declare -ri backup_user_umask=077

# The quantity of backup to keep for each directory
declare -i backups_quantity=7
declare -ri backups_quantity=$((backups_quantity+1))

## FUNCTIONS

# Get timestamp in order to log
get_current_timestamp() {
  timestamp=$(date "+[%h %d %H:%M:%S]")
}

# Echo arguments with a timestamp
log() {
  log_level="${1}"
  log_message="${2}"

  get_current_timestamp

  if [[ "${log_level}" == "ERROR" ]]; then
    echo -e "${timestamp} ${B}${RED}[ERROR]${NC} ${log_message}" >&2

  elif [[ "${log_level}" == "INFO" ]]; then
    echo -e "${timestamp} ${B}[INFO]${NC} ${log_message}"

  fi
}

# Craft an archive, compress it, and store it in $backup_destination_dir
archive_and_compress() {

  dir_to_backup="${1}"

  log "INFO" "Starting backup."

  # Actually creates the compressed archive
  tar cvzf \
    "${backup_destination_path}" \
    "${dir_to_backup}" \
    --ignore-failed-read &> /dev/null

  # Test if the archive has been created successfully
  if [[ $? -eq 0 ]]
  then
    log "INFO" "${B}${GRE}Success.${NC} Backup ${backup_filename} has been saved to ${backup_destination_dir}."
  else 
    log "ERROR" "Backup ${backup_filename} has failed."

    # Even if tar has failed, it creates the archive, so we remove it in case of failure
    rm -f "${backup_destination_path}"

    exit 1
  fi
}


### CODE

# Set the backup user UMASK
umask ${backup_user_umask}

# Backup the site
archive_and_compress "${target_path}"
