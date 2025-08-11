#!/bin/sh

set -u  # Treat unset variables as error

# === FLAGS ===
TARGET_DIR=""
DO_INCREMENTAL=false
DO_REPORT=false
DO_DUMP_DB=false

# === ARG PARSING ===
while getopts ":d:irb" opt; do
  case $opt in
    d) TARGET_DIR="$OPTARG" ;;
    i) DO_INCREMENTAL=true ;;
    r) DO_REPORT=true ;;
    b) DO_DUMP_DB=true ;;
    \?) echo "Invalid option: -$OPTARG" >&2; exit 1 ;;
    :) echo "Option -$OPTARG requires an argument." >&2; exit 1 ;;
  esac
done

# === VALIDATION ===
if [ -z "$TARGET_DIR" ]; then
  echo "ERROR: Target directory (-d) is required."
  exit 1
fi

if [ ! -d "$TARGET_DIR" ]; then
  echo "ERROR: Target directory '$TARGET_DIR' does not exist."
  exit 2
fi

# === CONFIGURATION ===
DATE=$(date +"%Y%m%d")
TIME=$(date +"%H:%M:%S")
TIMESTAMP=$(date +"%s")
BASE_DIR=/app
BACKUP_DIR="$BASE_DIR/backups/incremental-$DATE"
LOG_FILE="$BASE_DIR/logs/backup-$DATE.log"
REPORT_FILE="$BASE_DIR/reports/report-$DATE.txt"
ARCHIVE_FILE="$BACKUP_DIR/backup_$(basename "$TARGET_DIR")_$DATE.tar.gz"
DB_DUMP_FILE="$BACKUP_DIR/fastapi_db_dump_$DATE.sql"

mkdir -p "$BACKUP_DIR" "$BASE_DIR/logs" "$BASE_DIR/reports"

# === LOAD ENV ===
if [ -f "$BASE_DIR/.env" ]; then
  export $(grep -v '^#' "$BASE_DIR/.env" | xargs)
fi

# Check required env vars, fail fast if missing
: "${USERNAME_GITHUB:?USERNAME_GITHUB is not set in .env}"
: "${TOKEN_GITHUB:?TOKEN_GITHUB is not set in .env}"
: "${EMAIL_GIT:?EMAIL_GIT is not set in .env}"
: "${POSTGRES_USER:?POSTGRES_USER is not set in .env}"
: "${POSTGRES_PASSWORD:?POSTGRES_PASSWORD is not set in .env}"
: "${POSTGRES_HOST:?POSTGRES_HOST is not set in .env}"

REPO_NAME="capstone-backup"
API_URL="https://api.github.com/repos/$USERNAME_GITHUB/$REPO_NAME"
REPO_URL="https://$USERNAME_GITHUB:$TOKEN_GITHUB@github.com/$USERNAME_GITHUB/$REPO_NAME.git"

# === LOG START ===
{
  echo "$TIMESTAMP | Backup process started at $DATE $TIME"
  echo "--------------------------------------------------"
  echo "[${DATE} ${TIME}] Starting Backup"
  echo "Target Directory: $TARGET_DIR"
  echo "Backup Destination: $ARCHIVE_FILE"
  [ "$DO_DUMP_DB" = true ] && echo "DB Dump File: $DB_DUMP_FILE"
  echo ""
} >> "$LOG_FILE"

cd "$BASE_DIR" || {
  echo "$TIMESTAMP | ERROR: Could not cd to $BASE_DIR" >> "$LOG_FILE"
  exit 1
}

# === CHECK OR CREATE REPO ===
echo "$TIMESTAMP | Checking GitHub repo $REPO_NAME" >> "$LOG_FILE"
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: token $TOKEN_GITHUB" "$API_URL")

if [ "$HTTP_STATUS" -ne 200 ]; then
  echo "$TIMESTAMP | Repo not found. Creating $REPO_NAME..." >> "$LOG_FILE"
  curl -s -H "Authorization: token $TOKEN_GITHUB" \
    -d "{\"name\":\"$REPO_NAME\",\"description\":\"Automated backup repository\"}" \
    https://api.github.com/user/repos > /dev/null || {
      echo "$TIMESTAMP | ERROR: Failed to create repo" >> "$LOG_FILE"
      exit 1
    }
  echo "$TIMESTAMP | Repo created successfully" >> "$LOG_FILE"
fi

# === SETUP GIT ===
if [ ! -d ".git" ]; then
  echo "$TIMESTAMP | Initializing git repo" >> "$LOG_FILE"
  git init
  git config user.name "BackupBot"
  git config user.email "$EMAIL_GIT"
  git remote add origin "$REPO_URL"
else
  echo "$TIMESTAMP | Git repo already initialized" >> "$LOG_FILE"
  git config user.name "BackupBot"
  git config user.email "$EMAIL_GIT"
  if ! git remote get-url origin >/dev/null 2>&1; then
    git remote add origin "$REPO_URL"
  else
    git remote set-url origin "$REPO_URL"
  fi
fi

# === BRANCH SETUP ===
if git show-ref --quiet refs/heads/main; then
  GIT_BRANCH="main"
elif git show-ref --quiet refs/heads/master; then
  GIT_BRANCH="master"
else
  # Default to main branch creation
  GIT_BRANCH="main"
  git checkout -b main
fi
echo "$TIMESTAMP | Using branch $GIT_BRANCH" >> "$LOG_FILE"
git checkout "$GIT_BRANCH"
git pull origin "$GIT_BRANCH" 2>/dev/null || true

# === OPTIONAL DB DUMP ===
if [ "$DO_DUMP_DB" = true ]; then
  echo "$TIMESTAMP | Dumping fastapi DB" >> "$LOG_FILE"
  export PGPASSWORD="$POSTGRES_PASSWORD"
  pg_dump -U "$POSTGRES_USER" -h "$POSTGRES_HOST" fastapi > "$DB_DUMP_FILE" 2>>"$LOG_FILE" || {
    echo "$TIMESTAMP | ERROR: DB dump failed" >> "$LOG_FILE"
    exit 1
  }
  unset PGPASSWORD
  echo "$TIMESTAMP | DB dump complete" >> "$LOG_FILE"
fi

# === CREATE BACKUP ARCHIVE ===
echo "$TIMESTAMP | Creating backup archive" >> "$LOG_FILE"
tar -czf "$ARCHIVE_FILE" -C "$(dirname "$TARGET_DIR")" "$(basename "$TARGET_DIR")" >> "$LOG_FILE" 2>&1
echo "$TIMESTAMP | Archive created" >> "$LOG_FILE"

# === STAGE ALL CHANGES INCLUDING LOGS AND REPORTS ===
git add "$ARCHIVE_FILE"
if [ "$DO_DUMP_DB" = true ]; then
  git add "$DB_DUMP_FILE"
fi

# === GENERATE REPORT BEFORE COMMIT ===
echo "$TIMESTAMP | Generating backup report" >> "$LOG_FILE"

{
  echo "--------------------------------------------------"
  echo "[${DATE} ${TIME}] Backup Report"
  echo "--------------------------------------------------"
  echo "Timestamp     : $DATE $TIME"
  echo "Backed Up Dir : $TARGET_DIR"
  echo "Archive File  : $ARCHIVE_FILE"
  echo "Archive Size  : $(du -sh "$ARCHIVE_FILE" | cut -f1)"
  if [ "$DO_DUMP_DB" = true ]; then
    echo "DB Dump File  : $DB_DUMP_FILE"
    echo "DB Dump Size  : $(du -sh "$DB_DUMP_FILE" | cut -f1)"
  fi
  echo ""
} >> "$REPORT_FILE"

git add "$REPORT_FILE" "$LOG_FILE"

# === COMMIT AND PUSH IF CHANGES ===
if git diff --cached --quiet; then
  echo "$TIMESTAMP | No changes to commit" >> "$LOG_FILE"
  COMMIT_DONE=false
else
  echo "$TIMESTAMP | Changes detected, committing..." >> "$LOG_FILE"
  COMMIT_DONE=true

  # Get changed files for report summary
  CHANGED_FILES=$(git diff --cached --name-status)

  COMMIT_MSG="Backup update - $DATE $TIME"
  git commit -m "$COMMIT_MSG"
  git push origin "$GIT_BRANCH" || {
    echo "$TIMESTAMP | Push failed, attempting pull and retry" >> "$LOG_FILE"
    git pull origin "$GIT_BRANCH" --allow-unrelated-histories || true
    git push origin "$GIT_BRANCH"
  }
  echo "$TIMESTAMP | Changes pushed to remote" >> "$LOG_FILE"

  # Append changed files list to report
  {
    echo "Commit Status : Changes committed"
    echo "Commit Message: $COMMIT_MSG"
    echo "Changed Files :"
    echo "$CHANGED_FILES" | sed 's/^/  /'
  } >> "$REPORT_FILE"
  
  # Re-add report with changes and push updated report commit
  git add "$REPORT_FILE"
  git commit --amend --no-edit
  git push --force origin "$GIT_BRANCH"
fi

# === TAGGING ===
TAG_NAME="backup-$DATE-$(echo $TIME | tr ':' '-')"
git tag -a "$TAG_NAME" -m "Backup taken on $DATE at $TIME" 2>>"$LOG_FILE" || echo "$TIMESTAMP | Tag may already exist" >> "$LOG_FILE"
git push origin "$TAG_NAME" 2>>"$LOG_FILE" || echo "$TIMESTAMP | Tag push failed (may already exist)" >> "$LOG_FILE"

# === SUMMARY OUTPUT ===
echo "Backup process completed successfully at $DATE $TIME"
echo "Archive created: $ARCHIVE_FILE"
echo "Log file: $LOG_FILE"
echo "Report file: $REPORT_FILE"
echo "GitHub repository: https://github.com/$USERNAME_GITHUB/$REPO_NAME"

