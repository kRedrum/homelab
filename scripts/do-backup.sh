#!/bin/bash
set -euo pipefail

MARKER=".backup-ignore"

ENCRYPTION_KEY="${ENCRYPTION_KEY:-}"
RCLONE_REMOTE="${RCLONE_REMOTE:-}"
SRC_DIR="${SRC_DIR:-${SRC_DIRS:-}}"
DEST_DIR="${DEST_DIR:-}"
NTFY_TOPIC="${NTFY_TOPIC:-}"
MAX_TRANSFER="${MAX_TRANSFER:-750G}"
DRY_RUN="${DRY_RUN:-false}"

failed=0

usage() {
    echo "Usage: ${0##*/} -r <remote> -s <src_dirs> -e <encryption_key> [-d <dest_dir>] [-n <ntfy_topic>] [-D|--dry-run]"
    echo ""
    echo "Options:"
    echo "  -r <remote>          Google Drive / rclone remote (e.g. 'gdrive:' or 'gdrive:backups')"
    echo "  -s <src_dir>         Source directory to back up"
    echo "  -e <encryption_key>  Encryption key to encrypt data before uploading"
    echo "  -d <dest_dir>        Optional destination subdirectory under the remote"
    echo "  -n <ntfy_topic>      Optional ntfy topic for push notifications"
    echo "  -D                   Perform a trial run with no changes made"
    echo "  -h                   Show this help message"
}

die() {
    echo "Error: $*" >&2
    exit 1
}

# Parse command-line arguments
while getopts "r:e:d:s:n:Dh-:" opt; do
  case $opt in
  r) RCLONE_REMOTE="$OPTARG" ;;
  d) DEST_DIR="$OPTARG" ;;
  n) NTFY_TOPIC="$OPTARG" ;;
  s) SRC_DIR="$OPTARG" ;;
  e) ENCRYPTION_KEY="$OPTARG" ;;
  D) DRY_RUN=true ;;
  h) usage; exit 0 ;;
  *) usage; exit 1 ;;
  esac
done

# Check required tool
if ! command -v rclone >/dev/null 2>&1; then
    echo "Error: rclone is required but was not found. Please install rclone." >&2
    exit 2
fi

missing_vars=()
for var in RCLONE_REMOTE SRC_DIR ENCRYPTION_KEY; do
    if [ -z "${!var:-}" ]; then
        missing_vars+=("$var")
    fi
done

if [ ${#missing_vars[@]} -gt 0 ]; then
    echo "Error: Required variable(s) not set: ${missing_vars[*]}" >&2
    echo "Provide them via command-line options (-r, -s, -e) or environment variables." >&2
    usage
    exit 2
fi

if [ ! -d "$SRC_DIR" ]; then
    echo "Error: Source directory '$SRC_DIR' does not exist." >&2
    exit 1
fi

# Check optional configuration variables
if [ -z "$DEST_DIR" ]; then
    echo "Notice: DEST_DIR is not set. Backups will be placed directly under $RCLONE_REMOTE."
fi

if [ -z "$NTFY_TOPIC" ]; then
    echo "Notice: NTFY_TOPIC is not set. Push notifications will be skipped."
fi

OBSCURED_KEY="$(rclone obscure "$ENCRYPTION_KEY")"

if [[ "$RCLONE_REMOTE" == *: ]]; then
    remote_base="$RCLONE_REMOTE"
else
    remote_base="${RCLONE_REMOTE%/}/"
fi

dir_name="$(basename "${SRC_DIR%/}")"
if [ -n "$DEST_DIR" ]; then
    TARGET_REMOTE="${remote_base}${DEST_DIR%/}/${dir_name}"
else
    TARGET_REMOTE="${remote_base}${dir_name}"
fi

if [ "$DRY_RUN" = "true" ] || [ "$DRY_RUN" = "1" ]; then
    echo "Notice: DRY-RUN mode enabled. No changes will be made."
fi

echo "Backing up: $SRC_DIR -> $TARGET_REMOTE (encrypted)"
echo "---"

export RCLONE_CONFIG_BACKUP_CRYPT_TYPE="crypt"
export RCLONE_CONFIG_BACKUP_CRYPT_REMOTE="$TARGET_REMOTE"
export RCLONE_CONFIG_BACKUP_CRYPT_PASSWORD="$OBSCURED_KEY"
export RCLONE_CONFIG_BACKUP_CRYPT_PASSWORD2="$OBSCURED_KEY"
export RCLONE_CONFIG_BACKUP_CRYPT_FILENAME_ENCRYPTION="standard"
export RCLONE_CONFIG_BACKUP_CRYPT_DIRECTORY_NAME_ENCRYPTION="true"

rclone_flags=(
    --progress
    --delete-during
    --exclude-if-present "$MARKER"
    --exclude "$MARKER"
    --drive-stop-on-upload-limit
    --max-transfer "$MAX_TRANSFER"
)

if [ "$DRY_RUN" = "true" ]; then
    rclone_flags+=("--dry-run")
fi

if rclone sync "$SRC_DIR" "backup_crypt:" "${rclone_flags[@]}"; then
    echo "Backup of $SRC_DIR completed successfully."
    failed=0
else
    rc=$?
    echo "Error: rclone sync failed for $SRC_DIR (exit code $rc)." >&2
    failed=1
fi

# Push notification via ntfy if topic is configured
if [ -n "$NTFY_TOPIC" ]; then
    if [ "$failed" -eq 0 ]; then
        notification_title="Backup completed on $(hostname)"
        notification_message="Backup of $SRC_DIR completed successfully on $(hostname)."
        notification_tags="white_check_mark,floppy_disk"
        notification_priority="default"
    else
        notification_title="Backup failed on $(hostname)"
        notification_message="Backup failed for $SRC_DIR on $(hostname)."
        notification_tags="warning,floppy_disk"
        notification_priority="high"
    fi

    curl --fail --silent --show-error \
        -H "Title: $notification_title" \
        -H "Tags: $notification_tags" \
        -H "Priority: $notification_priority" \
        -d "$notification_message" \
        "https://ntfy.sh/${NTFY_TOPIC}" || echo "Warning: Failed to send ntfy notification" >&2
fi

exit "$failed"
