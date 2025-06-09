#!/bin/bash
set -e

# Source configuration
if [ -f "config.env" ]; then
    source config.env
else
    echo "config.env file not found. Please create it from the template."
    exit 1
fi

# Check if WAL-G is installed
if ! command -v wal-g >/dev/null 2>&1; then
    echo "WAL-G is not installed. Please run setup.sh first."
    exit 1
fi

# Parse command line arguments
FORMAT="table"

print_usage() {
    echo "Usage: $0 [--format FORMAT]"
    echo ""
    echo "Options:"
    echo "  --format FORMAT    Output format: table, json, or csv (default: table)"
    echo ""
    echo "Examples:"
    echo "  $0                  # List backups in table format"
    echo "  $0 --format json    # List backups in JSON format"
    echo "  $0 --format csv     # List backups in CSV format"
    exit 1
}

while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --format)
            FORMAT="$2"
            shift 2
            ;;
        --help)
            print_usage
            ;;
        *)
            echo "Unknown option: $1"
            print_usage
            ;;
    esac
done

# Get list of backups
echo "Retrieving backup list..."
BACKUP_LIST=$(wal-g backup-list 2>/dev/null)

if [ $? -ne 0 ]; then
    echo "Error: Failed to retrieve backup list."
    exit 1
fi

if [ -z "$BACKUP_LIST" ]; then
    echo "No backups found in the configured storage."
    exit 0
fi

# Count the backups
BACKUP_COUNT=$(echo "$BACKUP_LIST" | grep -v '^name' | wc -l)

echo "Found $BACKUP_COUNT backups."

# Format and display the output
case "$FORMAT" in
    json)
        # Convert to JSON format
        echo "{"
        echo "  \"backups\": ["
        echo "$BACKUP_LIST" | tail -n +2 | while read -r line; do
            name=$(echo "$line" | awk '{print $1}')
            last_modified=$(echo "$line" | awk '{print $2, $3}')
            wal_segment=$(echo "$line" | awk '{print $4}')
            
            # Check if this is the last line
            if [ "$(echo "$BACKUP_LIST" | tail -n +2 | tail -1)" = "$line" ]; then
                echo "    {\"name\": \"$name\", \"last_modified\": \"$last_modified\", \"wal_segment\": \"$wal_segment\"}"
            else
                echo "    {\"name\": \"$name\", \"last_modified\": \"$last_modified\", \"wal_segment\": \"$wal_segment\"},"
            fi
        done
        echo "  ]"
        echo "}"
        ;;
    csv)
        # Convert to CSV format
        echo "name,last_modified,wal_segment"
        echo "$BACKUP_LIST" | tail -n +2 | while read -r line; do
            name=$(echo "$line" | awk '{print $1}')
            last_modified=$(echo "$line" | awk '{print $2, $3}')
            wal_segment=$(echo "$line" | awk '{print $4}')
            
            echo "$name,\"$last_modified\",$wal_segment"
        done
        ;;
    table|*)
        # Display in table format (default)
        echo "$BACKUP_LIST"
        ;;
esac

# Display storage usage if possible
if [[ "$WALG_S3_PREFIX" == s3://* ]] && command -v aws >/dev/null 2>&1; then
    echo ""
    echo "Storage usage:"
    BUCKET=$(echo "$WALG_S3_PREFIX" | cut -d'/' -f3)
    PREFIX=$(echo "$WALG_S3_PREFIX" | cut -d'/' -f4-)
    
    echo "Calculating storage size..."
    STORAGE_SIZE=$(aws s3 ls --recursive "s3://$BUCKET/$PREFIX" --summarize | grep "Total Size" | awk '{print $3" "$4}')
    
    if [ -n "$STORAGE_SIZE" ]; then
        echo "Total storage used: $STORAGE_SIZE"
    else
        echo "Could not calculate storage size. Please ensure AWS CLI is installed and configured."
    fi
elif [[ "$WALG_GS_PREFIX" == gs://* ]] && command -v gsutil >/dev/null 2>&1; then
    echo ""
    echo "Storage usage:"
    
    echo "Calculating storage size..."
    STORAGE_SIZE=$(gsutil du -s "$WALG_GS_PREFIX" | awk '{print $1/1024/1024/1024 " GB"}')
    
    if [ -n "$STORAGE_SIZE" ]; then
        echo "Total storage used: $STORAGE_SIZE"
    else
        echo "Could not calculate storage size. Please ensure gsutil is installed and configured."
    fi
elif [[ "$WALG_FILE_PREFIX" == /* ]] && [ -d "$WALG_FILE_PREFIX" ]; then
    echo ""
    echo "Storage usage:"
    
    echo "Calculating storage size..."
    STORAGE_SIZE=$(du -sh "$WALG_FILE_PREFIX" | awk '{print $1}')
    
    if [ -n "$STORAGE_SIZE" ]; then
        echo "Total storage used: $STORAGE_SIZE"
    else
        echo "Could not calculate storage size."
    fi
fi

# Check for old backups
echo ""
echo "Backup retention information:"
if [ -n "$WALG_RETENTION_FULL_BACKUPS" ]; then
    echo "  Retention policy: Keep $WALG_RETENTION_FULL_BACKUPS full backups"
fi

if [ -n "$WALG_RETENTION_DAYS" ]; then
    echo "  Retention policy: Keep backups for $WALG_RETENTION_DAYS days"
fi

if [ -n "$WALG_RETENTION_COUNT" ]; then
    echo "  Retention policy: Keep $WALG_RETENTION_COUNT most recent backups"
fi

exit 0 