FROM alpine:latest

# Install dependencies including postgresql-client for pg_dump
RUN apk add --no-cache bash rsync busybox-suid git openssh curl postgresql-client

# Set working directory
WORKDIR /app

# Copy necessary files
COPY search_backup.sh .
COPY cronjob.txt .
RUN echo -e "cronjob.txt\nsearch_backup.sh" > .gitignore

# Permissions
RUN chmod +x search_backup.sh

# Set up cron jobs
RUN crontab cronjob.txt

# Create needed directories
RUN mkdir -p /var/log /app/logs /app/backups /app/reports

# Run the backup script once, then start cron daemon
CMD ["sh", "-c", "./search_backup.sh -d /dbdata -i -r && crond -f -l 8"]
