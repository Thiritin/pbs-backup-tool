#!/bin/bash
set -e

# Define the status update URL
# shellcheck disable=SC2153
status_url=${STATUS_URL}

if [ -n "$status_url" ]; then
  # shellcheck disable=SC2064
  trap "curl -fs '$status_url?status=down&msg=FAILED'" ERR
fi

mkdir -p backup

# Check the backup source and run the appropriate backup client
#
# Multi: refers to backups that will either query for a list of databases or buckets
# Single: refers to backups that will only backup a single database or bucket
# Use file if you want to manually create your backup and just have it backuped. Mount it in the backup container and use the FILE option.
#
case $BACKUP_SOURCE in
  POSTGRES_MULTI)
    psql -tc "$PGDBSELECT" | while read -r database; do
      echo "Backing up $database"
      # database is not empty
      if [ -n "$database" ]; then
        # Use the pg_dump tool to create a backup of the database
        pg_dump -Fd -v -d "$database" -j 4 -Z0 -f "./backup/$database"
      fi
    done
    ;;
  MINIO_MULTI)
    # Use the minio client (mc) to create a backup of the bucket
    # shellcheck disable=SC2086
    mc alias set crewzone $S3_ENDPOINT "$S3_ACCESS" $S3_SECRET --api S3v4
    # mirror each s3 bucket to a local directory
    mc ls crewzone | awk '{print $5}' | while read bucket; do
      mc mirror --overwrite crewzone/$bucket ./backup/$bucket
    done
    ;;
  MONGO_SINGLE)
    # Use the mongodump tool to create a backup of the database
    mongodump --uri "$MONGO_URL" --out=/app/backup
    ;;
  FILE)
    # Use the mongodump tool to create a backup of the database
    echo "Performing file Backup"
    ;;
  *)
    echo "Invalid backup source: $BACKUP_SOURCE"
    exit 1
    ;;

esac

# Upload the backup to Proxmox backup client
proxmox-backup-client backup $BACKUP_ID.pxar:/app/backup --backup-id "$BACKUP_ID" --ns "$PBC_NAMESPACE" --skip-lost-and-found

# Send a status update
if [ -n "$status_url" ]; then
  curl -fs "$status_url?status=up&msg=OK"
fi

# Clean up the backup file
rm -rf ./backup/*