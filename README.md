## Proxmox Backup Client - Docker Image Documentation

This Docker image contains a backup script to export data from several sources into a backup folder, and then uploads this data to the proxmox backup server.

### Variables

The script uses the following environment variables:

| Variable name | Purpose |
| --- | --- |
| `PBS_REPOSITORY` | The repository to store the backup. |
| `PBS_PASSWORD` | The password for the backup repository. |
| `PBS_ENCRYPTION_PASSWORD` | The encryption password for the backup. |
| `PBS_FINGERPRINT` | The fingerprint of the backup repository. |
| `PGHOST` | The hostname or IP address of the PostgreSQL server. |
| `PGPORT` | The port number on which the PostgreSQL server is listening. |
| `PGDATABASE` | The name of the PostgreSQL database. |
| `PGPASSWORD` | The password for connecting to the PostgreSQL server. |
| `PGUSER` | The username for connecting to the PostgreSQL server. |
| `PGDBSELECT` | The SQL command used to select the PostgreSQL databases to backup. |
| `S3_ENDPOINT` | The endpoint of the S3-compatible storage. |
| `S3_ACCESS` | The access key for the S3-compatible storage. |
| `S3_SECRET` | The secret key for the S3-compatible storage. |
| `MONGO_URL` | The URL for the MongoDB server. |
| `BACKUP_ID` | The ID for the backup job. |
| `BACKUP_SOURCE` | The source for the backup job (e.g. PostgreSQL, MongoDB). |
| `PBC_NAMESPACE` | The namespace for the backup job.

### Supported Backup Sources

1. PostgreSQL
2. MongoDB
3. MinIO
The BACKUP_SOURCE environment variable can be used to specify the backup source for your backup job. If you need to backup other types of data sources, you can modify the script or create a new Docker image that extends the Proxmox Backup Client image and adds support for your specific backup source.

### Usage

To use the Proxmox Backup Client Docker image, you can follow these steps:

1. Pull the Docker image from Docker Hub using the following command:
```
docker pull thiritin/proxmox-backup-client:v1.0.0
```
2. Create a Docker container using the following command:
```
docker run -d
-e PBS_REPOSITORY="mybackup@mybackup.com:443:backup"
-e PBS_PASSWORD="mybackuppassword"
-e PBS_ENCRYPTION_PASSWORD="myencryptionpassword"
-e PBS_FINGERPRINT="01:23:45:67:89:ab:cd:ef:01:23:45:67:89:ab:cd:ef:01:23:45:67"
-e PGHOST="postgres.example.com"
-e PGPORT="5432"
-e PGDATABASE="mydatabase"
-e PGPASSWORD="mypgpassword"
-e PGUSER="mypguser"
-e PGDBSELECT="SELECT datname FROM pg_database WHERE datistemplate = false;"
-e S3_ENDPOINT="https://s3.mybackup.com/"
-e S3_ACCESS="mys3accesskey"
-e S3_SECRET="mys3secretkey"
-e MONGO_URL="mongodb://mongodb.example.com:27017"
-e BACKUP_ID="mybackupjob"
-e BACKUP_SOURCE="PostgreSQL"
-e PBC_NAMESPACE="myapp/mybackupjob"
thiritin/proxmox-backup-client
```

In this command, you need to replace the environment variables with the appropriate values for your application.

3. If you need to customize the script, you can create a new Docker image that extends the Proxmox Backup Client image and modifies the script accordingly. Here's an example Dockerfile that modifies the script:
```
FROM thiritin/proxmox-backup-client

COPY myscript.sh /app/myscript.sh

CMD ["./myscript.sh"]

```

In this example, the myscript.sh file is copied to the /app directory inside the container, and is executed instead of the default start.sh script.

## Note
Please make sure that you have properly configured your Docker container and environment variables before using the Proxmox Backup Client Docker image. Also, make sure to modify the script based on your specific needs and use case.
