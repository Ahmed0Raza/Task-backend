#!/bin/sh
echo "Backup ran at $(date)"

set -e  # Exit on error
set -u  # Error on unset vars

# === FLAGS ===
TARGET_DIR=""
DO_INCREMENTAL=false
DO_REPORT=false

# === ARGUMENT PARSING ===
while getopts ":d:ir" opt; do
  case $opt in
    d) TARGET_DIR="$OPTARG" ;;
    i) DO_INCREMENTAL=true ;;  # Accepted but not used
    r) DO_REPORT=true ;;
    \?) echo "Invalid option: -$OPTARG" >&2; exit 1 ;;
    :) echo "Option -$OPTARG requires an argument." >&2; exit 1 ;;
  esac
done

# === VALIDATION ===
if [ -z "$TARGET_DIR" ]; then
  echo "❌ ERROR: Target directory (-d) is required."
  exit 1
fi

if [ ! -d "$TARGET_DIR" ]; then
  echo "❌ ERROR: Target directory '$TARGET_DIR' does not exist."
  exit 2
fi

# === CONFIGURATION ===
DATE=$(date +"%Y%m%d")
TIME=$(date +"%H:%M:%S")
BASE_DIR=/app
BACKUP_DIR="$BASE_DIR/backups/incremental-$DATE"
LOG_FILE="$BASE_DIR/logs/backup-$DATE.log"
REPORT_FILE="$BASE_DIR/reports/report-$DATE.txt"
ARCHIVE_FILE="$BACKUP_DIR/backup_$(basename "$TARGET_DIR")_$DATE.tar.gz"

# === PREP ===
mkdir -p "$BACKUP_DIR" "$BASE_DIR/logs" "$BASE_DIR/reports"

# === LOG START ===
{
  echo "--------------------------------------------------"
  echo "[${DATE} ${TIME}] 🗃️  Starting Backup"
  echo "--------------------------------------------------"
  echo "📂 Target Directory : $TARGET_DIR"
  echo "📦 Backup Destination: $ARCHIVE_FILE"
  echo ""
} >> "$LOG_FILE"

# === BACKUP ===
echo "[${DATE} ${TIME}] 🔄 Archiving $TARGET_DIR..." >> "$LOG_FILE"
tar -czf "$ARCHIVE_FILE" -C "$(dirname "$TARGET_DIR")" "$(basename "$TARGET_DIR")" >> "$LOG_FILE" 2>&1
echo "[${DATE} ${TIME}] ✅ Backup completed." >> "$LOG_FILE"

# === REPORT (optional) ===
if $DO_REPORT; then
  {
    echo "--------------------------------------------------"
    echo "[${DATE} ${TIME}] 📄 Backup Report"
    echo "--------------------------------------------------"
    echo "🕒 Timestamp        : $DATE $TIME"
    echo "📂 Backed Up Dir    : $TARGET_DIR"
    echo "📁 Archive File     : $ARCHIVE_FILE"
    echo "📦 Archive Size     : $(du -sh "$ARCHIVE_FILE" | cut -f1)"
    echo ""
  } >> "$REPORT_FILE"
fi

# === DONE ===
echo "[${DATE} ${TIME}] ✅ Backup script completed successfully." >> "$LOG_FILE"

## === GIT BACKUP PUSH (Tags Only to backup branch) ===

# Start ssh-agent and add the SSH key
eval "$(ssh-agent -s)"
ssh-add /root/.ssh/id_backup_ed25519

# Add GitHub to known_hosts to prevent host verification prompts
mkdir -p ~/.ssh
ssh-keyscan github.com >> ~/.ssh/known_hosts

# Clone the repo shallowly and switch to the `backup` branch
rm -rf /tmp/repo
cd /tmp
git clone --depth=1 --branch=backup git@github.com:Ahmed0Raza/Task-backend.git repo
cd repo

# Configure Git
git config user.name "BackupBot"
git config user.email "imahmedraza4626@gmail.com"

# Create a tag only
TAG_NAME="backup-$DATE-$(echo $TIME | tr ':' '-')"
git tag -a "$TAG_NAME" -m "Backup taken on $DATE at $TIME"

# Push the tag to the `backup` branch
git push origin "$TAG_NAME"
