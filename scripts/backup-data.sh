#!/bin/bash
# Backup Paperclip data directory
# Usage: ./scripts/backup-data.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DATA_DIR="$PROJECT_ROOT/data"
BACKUP_DIR="$DATA_DIR/backups"

# Ensure backup directory exists
mkdir -p "$BACKUP_DIR"

# Generate timestamp
TIMESTAMP=$(date +%Y-%m-%d-%H%M%S)
BACKUP_FILE="$BACKUP_DIR/paperclip-$TIMESTAMP.tar.gz"

# Check if data exists
if [ ! -d "$DATA_DIR/pglite" ] && [ ! -d "$DATA_DIR/backups" ]; then
    echo "⚠️  No data to backup (data/ is empty)"
    exit 0
fi

# Create backup (exclude backups directory to avoid recursion)
echo "📦 Creating backup..."
tar -czf "$BACKUP_FILE" \
    --exclude="backups" \
    -C "$DATA_DIR" \
    . 2>/dev/null || true

# Check if backup was created
if [ -f "$BACKUP_FILE" ]; then
    SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    echo "✅ Backup created: $BACKUP_FILE ($SIZE)"
    echo ""
    echo "To restore on another machine:"
    echo "  mkdir -p data && tar -xzf paperclip-$TIMESTAMP.tar.gz -C data"
else
    echo "⚠️  Backup was empty or failed"
    exit 1
fi

# Cleanup old backups (keep last 10)
echo ""
echo "🧹 Cleaning up old backups (keeping last 10)..."
ls -t "$BACKUP_DIR"/paperclip-*.tar.gz 2>/dev/null | tail -n +11 | xargs -r rm
echo "Done."
