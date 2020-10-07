#!/bin/bash
# it4
# 23/09/2020
# Simple pre backup script

# Informations about the User that must run this script
declare -r backup_user_name="backup"
declare -ri backup_user_uid=1003

# Target directory : the one we want to backup
declare -r target_path="${1}"

# Craft the backup full path and name
declare -r backup_destination_dir="/opt/backup/"

## PREFLIGHT CHECKS

# Force a specific user to run te script
if [[ ${EUID} -ne ${backup_user_uid} ]]; then
  log "ERROR" "This script must be run as \"${backup_user_name}\" user, which UID is ${backup_user_uid}. Exiting."
  exit 1
fi

# Check that the target dir actually exists and is readable
if [[ ! -d "${target_path}" ]]; then
  log "ERROR" "The target path ${target_path} does not exist. Exiting."
  exit 1
fi
if [[ ! -r "${target_path}" ]]; then
  log "ERROR" "The target path ${target_path} is not readable. Exiting."
  exit 1
fi

# Check that the destination dir actually exists ans is writable
if [[ ! -d "${backup_destination_dir}" ]]; then
  log "ERROR" "The destination dir ${backup_destination_dir} does not exist. Exiting."
  exit 1
fi
if [[ ! -w "${backup_destination_dir}" ]]; then
  log "ERROR" "The destination dir ${backup_destination_dir} is not writable. Exiting."
  exit 1
fi