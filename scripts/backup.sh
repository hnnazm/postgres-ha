#!/bin/bash

set -euo pipefail  # Exit on error, unset variables as error, and pipefail
# set -x  # Uncomment this line for debugging to see command execution

# Set variables
BACKUP_DIR="/var/lib/pgsql/16/backups"
DB_NAME="beaconx"
CURRENT_DATE=$(date +%d)  # Only the day in DD format
WEEK_NUMBER=$(date +%U)  # Get the week number (00..53)
YEAR=$(date +%Y)

echo "[${CURRENT_DATE}] Running backup script"

# Remove existing backups for the current week
find "$BACKUP_DIR" -type f -name "$DB_NAME-$YEAR-$WEEK_NUMBER-*.sql" -exec rm {} \;

# Ensure we only keep the last 7 backups
BACKUP_COUNT=$(find "$BACKUP_DIR" -maxdepth 1 -type f -name "$DB_NAME-$YEAR-$WEEK_NUMBER-*.sql" | wc -l)

if [ "$BACKUP_COUNT" -ge 7 ]; then
    # Find and remove the oldest backup file
    OLDEST_FILE=$(find "$BACKUP_DIR" -maxdepth 1 -type f -name "$DB_NAME-$YEAR-$WEEK_NUMBER-*.sql" -print0 | xargs -0 ls -t | tail -n 1)
    echo "Removing oldest backup: $OLDEST_FILE"
    rm "$OLDEST_FILE"
fi

# Run pg_dump with the new naming convention
pg_dump -U repmgr "$DB_NAME" > "$BACKUP_DIR/$DB_NAME-$YEAR-$WEEK_NUMBER-$CURRENT_DATE.sql"
