#!/bin/bash
set -e

# Define the status update URL
status_url=${STATUS_URL}

trap "curl -fs '$status_url?status=down&msg=FAILED'" ERR

mkdir -p backup

# Define the backup filename
backup_filename="$BACKUP_SOURCE-$(date +%Y%m%d%H%M%S)"

# Check the backup source and run the appropriate backup client
case $BACKUP_SOURCE in
  POSTGRES)
    pbc_namespace=elbgoods/prg/crewzone
    psql -tc "SELECT datname FROM pg_database WHERE datistemplate = false AND (datname LIKE 'dev_%' OR datname LIKE 'staging_%' OR datname LIKE 'production_%');" | while read database; do
      echo "Backing up $database"
      # database is not empty
      if [ -n "$database" ]; then
        # Use the pg_dump tool to create a backup of the database
        pg_dump -Fd -v -d $database -j 4 -Z0 -f ./backup/$database
      fi
    done
    ;;
  MINIO)
    pbc_namespace=elbgoods/prg/crewzone
    # Use the minio client (mc) to create a backup of the bucket
    mc alias set crewzone $S3_ENDPOINT $S3_ACCESS $S3_SECRET --api S3v4
    # mirror each s3 bucket to a local directory
    mc ls crewzone | awk '{print $5}' | while read bucket; do
      mc mirror --overwrite crewzone/$bucket ./backup/$bucket
    done
    ;;
  MONGO)
    pbc_namespace=elbgoods/prg/crewzone
    # Use the mongodump tool to create a backup of the database
    mongodump --uri "$MONGO_URL" --out=/app/backup
    ;;
  *)
    echo "Invalid backup source: $BACKUP_SOURCE"
    exit 1
    ;;
esac

# Upload the backup to Proxmox backup client
proxmox-backup-client backup $BACKUP_ID.pxar:/app/backup --backup-id $BACKUP_ID --ns $PBC_NAMESPACE --skip-lost-and-found


# Send a status update
if [ -n "$status_url" ]; then
  curl -fs "$status_url?status=up&msg=OK"
fi

# Clean up the backup file
rm -rf ./backup/*