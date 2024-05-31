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
        pg_dump -Fd -v -d "$database" -j 4 -Z0 -f "/app/backup/$database"
      fi
    done
    ;;
  MYSQL_MULTI)
    # echo mysql result
    mysql --host=$MYSQL_HOST --user=$MYSQL_USER --password="$MYSQL_PASSWORD" -s -N -e "$MYSQL_DBSELECT" | while read -r database; do
      # Skip information_schema, performance_schema, and sys databases
      if [ "$database" = "information_schema" ] || [ "$database" = "performance_schema" ] || [ "$database" = "sys" ]; then
        continue
      fi
      echo "Backing up $database"
      # database is not empty
      if [ -n "$database" ]; then
        # Use the mysqldump tool to create a backup of the database
        mysqldump --host=$MYSQL_HOST --user=$MYSQL_USER --single-transaction --password="$MYSQL_PASSWORD" --quick --lock-tables=false "$database" > "/app/backup/$database.sql"
        # Check that the file exists, otherwise throw error
        if [ ! -f "/app/backup/$database.sql" ]; then
          echo "Backup failed for $database"
          exit 1
        fi
      fi
    done
    ## if no database is found, exit with error
    if [ ! "$(ls -A /app/backup)" ]; then
      echo "No databases found"
      exit 1
    fi
    ;;
  MYSQL_SINGLE)
    echo "Backing up $MYSQL_DATABASE"
    # Use the mysqldump tool to create a backup of the database
    mysqldump --host=$MYSQL_HOST --user=$MYSQL_USER --single-transaction --password="$MYSQL_PASSWORD" --quick --lock-tables=false "$MYSQL_DATABASE" > "/app/backup/$MYSQL_DATABASE.sql"
    # Check that the file exists, otherwise throw error
    if [ ! -f "/app/backup/$MYSQL_DATABASE.sql" ]; then
      echo "Backup failed for $MYSQL_DATABASE"
      exit 1
    fi
    ;;
  MINIO_MULTI)
    # Use the minio client (mc) to create a backup of the bucket
    # shellcheck disable=SC2086
    mc alias set crewzone $S3_ENDPOINT "$S3_ACCESS" $S3_SECRET --api S3v4
    # mirror each s3 bucket to a local directory
    mc ls crewzone | awk '{print $5}' | while read bucket; do
      mc mirror --overwrite crewzone/$bucket /app/backup/$bucket
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
rm -rf /app/backup/*