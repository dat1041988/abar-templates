#!/usr/bin/env bash

# Check required variables are there
if [ -z "${OSS_PATH}" ]; then
  echo "$(date): ERROR: variable \$OSS_PATH is not set"
  exit 1
fi

if [ -z "${BACKUP_CONFIG}" ]; then
  echo "$(date): ERROR: variable \$BACKUP_CONFIG is not set"
  exit 1
fi

# Functions for backing up DBs
function backup_postgresql() {
  export PGPASSWORD=${password}
  pg_dump \
    --host=${host} \
    --port=${port} \
    --username=${user} \
    --dbname=${database} \
    --format=custom > backups/${backup_filename}
}

function backup_mysql() {
  export MYSQL_PWD=${password}
  mysqldump \
     --host=${host} \
     --port=${port} \
     --user=${user} \
     --compress \
     ${database} > backups/${backup_filename}
}

function backup_mongodb() {
  mongodump \
     --host=${host} \
     --port=${port} \
     --username=${user} \
     --password=${password} \
     --db=${database} \
     --archive=backups/${backup_filename}
}


echo "$(date): Taking backup..."

# Loop through each entry in the config file
backup_config=$(cat ${BACKUP_CONFIG} | jq '.backups')
config_count=$(echo $backup_config | jq '. | length')
for i in `seq 0 $((config_count - 1))`;
do
  # Parse the config file
  type=$(echo $backup_config | jq -r ".[$i].type")
  host=$(echo $backup_config | jq -r ".[$i].host")
  port=$(echo $backup_config | jq -r ".[$i].port")
  user=$(echo $backup_config | jq -r ".[$i].user")
  password=$(echo $backup_config | jq -r ".[$i].password")
  database=$(echo $backup_config | jq -r ".[$i].database")
  prefix=$(echo $backup_config | jq -r ".[$i].prefix")
  keep=$(echo $backup_config | jq -r ".[$i].backups_to_keep")

  # Generate a backup filename
  backup_filename=${prefix}$(date +"%Y%m%d%H%M%SUTC").dump

  echo "$(date): Taking backup of $type database $database..."

  # Take the dump
  error=""
  case "$type" in
    "postgresql") backup_postgresql;;
    "mysql") backup_mysql;;
    "mongodb") backup_mongodb;;
    *) error="Could not find type $type";;
  esac

  # Continue to next config if there's an error
  if [[ -n "$error" ]]; then
    echo "$(date): ERROR: Error taking backup of $type database $database: $error" >&2
    continue
  fi

  # Upload to OSS
  echo "$(date): Uploading backup for $type database $database to object storage..."
  ossutil cp backups/${backup_filename} oss://$OSS_PATH/$backup_filename
  # Remove dump from volume once it is backed up on OSS
  rm backups/${backup_filename}

  # Remove old backups on OSS
  echo "$(date): Deleting old backups for $type database $database..."
  backups_to_remove=$(ossutil ls oss://$OSS_PATH | awk -F' {2,}' '{ print $5 }' | grep "oss://$OSS_PATH/$prefix" | sort -nr | awk -v keep="$keep" 'NR > keep')
  echo $backups_to_remove | xargs -n1 -r ossutil rm

done

echo "$(date): DONE"
