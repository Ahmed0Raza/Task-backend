FROM alpine:latest
RUN apk add --no-cache bash rsync busybox-suid git openssh curl
WORKDIR /app
COPY search_backup.sh .
RUN chmod +x search_backup.sh
COPY cronjob.txt .
RUN crontab cronjob.txt
RUN mkdir -p /var/log /app/logs /app/backups /app/reports
CMD ["sh", "-c", "./search_backup.sh -d /dbdata -i -r && crond -f -l 8"]
