FROM alpine:latest

# Install required packages
RUN apk add --no-cache bash rsync busybox-suid

# Set working directory
WORKDIR /app

# Copy backup script and cronjob file
COPY search_backup.sh .
COPY cronjob.txt .

# Ensure the backup script is executable
RUN chmod +x search_backup.sh

# Create log directory and empty log file
RUN mkdir -p /var/log && touch /var/log/cron.log && chmod 666 /var/log/cron.log

# Install the cron job
RUN crontab cronjob.txt

# Start cron in the foreground when the container runs