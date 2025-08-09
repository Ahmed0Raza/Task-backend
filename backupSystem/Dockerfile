FROM alpine:latest
RUN apk add --no-cache bash rsync busybox-suid git openssh curl
WORKDIR /app
COPY search_backup.sh .
RUN chmod +x search_backup.sh
COPY cronjob.txt .
RUN crontab cronjob.txt
RUN mkdir -p /var/log /app/logs /app/backups /app/reports
CMD ["sh", "-c", "./search_backup.sh -d /dbdata -i -r && crond -f -l 8"]
FROM alpine:latest

# Install dependencies
RUN apk add --no-cache bash rsync busybox-suid git openssh curl

# Set working directory
WORKDIR /app

# Copy backup script
COPY search_backup.sh .
RUN chmod +x search_backup.sh

# Copy cronjob
COPY cronjob.txt .
RUN crontab cronjob.txt

# Copy .gitignore to ensure unwanted files aren't tracked in the backup repo
COPY .gitignore .

# Create required directories
RUN mkdir -p /var/log /app/logs /app/backups /app/reports

# Run backup script once, then start cron in foreground
CMD ["sh", "-c", "./search_backup.sh -d /dbdata -i -r && crond -f -l 8"]
