FROM alpine:latest

# Install required packages: bash, rsync, crond, git, openssh
RUN apk add --no-cache bash rsync busybox-suid git openssh

WORKDIR /app

# Copy your backup script and make it executable
COPY search_backup.sh .
RUN chmod +x search_backup.sh

# Copy cron job definition
COPY cronjob.txt .

# Set up crontab
RUN crontab cronjob.txt

# Ensure log directories exist
RUN mkdir -p /var/log /app/logs /app/backups /app/reports

# Start backup immediately and run crond
CMD ["sh", "-c", "./search_backup.sh -d /dbdata -i -r && crond -f -l 8"]
