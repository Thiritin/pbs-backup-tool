FROM debian:stable
RUN apt-get update \
    && apt-get install gnupg wget curl -y \
    && wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | apt-key add - \
    && wget https://enterprise.proxmox.com/debian/proxmox-release-bullseye.gpg -O /etc/apt/trusted.gpg.d/proxmox-release-bullseye.gpg \
    && echo "deb http://repo.mongodb.org/apt/debian bullseye/mongodb-org/6.0 main" | tee /etc/apt/sources.list.d/mongodb-org-6.0.list \
    && echo "deb http://download.proxmox.com/debian/pbs-client bullseye main" | tee /etc/apt/sources.list.d/pbs.list \
    && apt-get update \
    && apt-get --no-install-recommends install postgresql-client-13 mongodb-org-tools proxmox-backup-client -y \
    && apt-get remove wget gnupg -y \
    && apt-get autoremove -y \
    && apt-get clean
# Adduser App with uid and gid 1000 \
RUN curl https://dl.min.io/client/mc/release/linux-amd64/mc \
                 --create-dirs \
                 -o /usr/bin/mc \
        && chmod +x /usr/bin/mc
RUN groupadd --gid 1000 app \
    && adduser --uid 1000 --home /app --gid 1000 --disabled-password --gecos "" app
USER app
WORKDIR /app
RUN mkdir /app/backup

## Add backup script
ADD ./backup.sh /app/backup.sh

USER root
RUN chown -R app:app /app \
  && chmod -R 755 /app
CMD ["/bin/bash","-c","/app/backup.sh"]