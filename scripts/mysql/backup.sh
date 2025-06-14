#!/bin/bash
set -e

# Source configuration
if [ -f "$WALL_BE_CONFIG_FILE" ]; then
    source "$WALL_BE_CONFIG_FILE"
else
    echo "Configuration file not found. Please specify a config file with --config."
    exit 1
fi

LOG_FILE="/var/log/wal-g/backup-$(date +%Y%m%d%H%M%S).log"
mkdir -p /var/log/wal-g

# Detect WAL-G binary path
WALG_BIN="${WALG_MYSQL_BINPATH:-/usr/local/bin/wal-g}"

if [ ! -f "$WALG_BIN" ]; then
    # Try alternative paths
    if [ -f "/usr/local/bin/wal-g-mysql" ]; then
        WALG_BIN="/usr/local/bin/wal-g-mysql"
    elif [ -f "/usr/local/bin/wal-g" ]; then
        WALG_BIN="/usr/local/bin/wal-g"
    else
        echo "WAL-G binary not found. Please install WAL-G or specify WALG_MYSQL_BINPATH."
        exit 1
    fi
fi

echo "Using WAL-G binary: $WALG_BIN"

# Function to send notification
send_notification() {
    local status=$1
    local message=$2
    local subject="MySQL Backup $status"
    
    if [ "$BACKUP_ALERT_ON_SUCCESS" = "true" ] && [ "$status" = "SUCCESS" ]; then
        # Send email notification
        if [ -n "$BACKUP_ALERT_EMAIL" ]; then
            echo "$message" | mail -s "$subject" "$BACKUP_ALERT_EMAIL"
        fi
        
        # Send Slack notification
        if [ -n "$BACKUP_SLACK_WEBHOOK" ]; then
            curl -s -X POST -H 'Content-type: application/json' \
                --data "{\"text\":\"$subject: $message\"}" \
                "$BACKUP_SLACK_WEBHOOK"
        fi
    elif [ "$BACKUP_ALERT_ON_ERROR" = "true" ] && [ "$status" = "FAILED" ]; then
        # Send email notification
        if [ -n "$BACKUP_ALERT_EMAIL" ]; then
            echo "$message" | mail -s "$subject" "$BACKUP_ALERT_EMAIL"
        fi
        
        # Send Slack notification
        if [ -n "$BACKUP_SLACK_WEBHOOK" ]; then
            curl -s -X POST -H 'Content-type: application/json' \
                --data "{\"text\":\"$subject: $message\"}" \
                "$BACKUP_SLACK_WEBHOOK"
        fi
    fi
}

# Function to verify backup
verify_backup() {
    local backup_name=$1
    echo "Verifying backup: $backup_name"
    
    # List backups to verify it exists
    if ! $WALG_BIN backup-list 2>/dev/null | grep -q "$backup_name"; then
        echo "ERROR: Backup verification failed. Backup not found in storage."
        return 1
    fi
    
    echo "Backup verification successful: $backup_name"
    return 0
}

# Function to clean up old backups
cleanup_old_backups() {
    echo "Cleaning up old backups based on retention policy..."
    
    # Delete old backups based on retention settings
    if [ -n "$WALG_RETENTION_FULL_BACKUPS" ]; then
        echo "Retaining only $WALG_RETENTION_FULL_BACKUPS full backups..."
        $WALG_BIN backup-retain FULL "$WALG_RETENTION_FULL_BACKUPS" --confirm
    fi
    
    if [ -n "$WALG_RETENTION_DAYS" ]; then
        echo "Retaining backups made within $WALG_RETENTION_DAYS days..."
        $WALG_BIN backup-retain DAYS "$WALG_RETENTION_DAYS" --confirm
    fi
    
    if [ -n "$WALG_RETENTION_COUNT" ]; then
        echo "Retaining only $WALG_RETENTION_COUNT most recent backups..."
        $WALG_BIN backup-retain COUNT "$WALG_RETENTION_COUNT" --confirm
    fi
    
    echo "Cleanup completed."
}

# Function to create backup name
create_backup_name() {
    local backup_type=$1
    local timestamp=$(date +%Y%m%d%H%M%S)
    local hostname=$(hostname -s)
    echo "${backup_type}_${hostname}_${timestamp}"
}

# Main backup function
perform_backup() {
    echo "Starting MySQL backup with WAL-G..."
    local start_time=$(date +%s)
    local backup_type="${1:-full}"
    local backup_name=$(create_backup_name "$backup_type")
    
    echo "Backup name: $backup_name"
    echo "Backup type: $backup_type"
    echo "Start time: $(date)"
    
    # Choose backup command based on backup type
    if [ "$backup_type" = "xtrabackup" ]; then
        echo "Using xtrabackup for backup..."
        $WALG_BIN xtrabackup-push --permanent "$backup_name"
    else
        echo "Using standard backup-push..."
        $WALG_BIN backup-push --permanent "$backup_name"
    fi
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    echo "Backup completed in $duration seconds."
    
    # Verify backup if enabled
    if [ "$WALG_VERIFY_BACKUPS" = "true" ]; then
        if ! verify_backup "$backup_name"; then
            send_notification "FAILED" "Backup verification failed for $backup_name. Duration: $duration seconds."
            exit 1
        fi
    fi
    
    # Upload binlog if available
    if command -v $WALG_BIN binlog-push >/dev/null 2>&1; then
        echo "Uploading binary logs..."
        $WALG_BIN binlog-push || true
    fi
    
    # Clean up old backups
    cleanup_old_backups
    
    # Send success notification
    send_notification "SUCCESS" "Backup $backup_name completed successfully. Duration: $duration seconds."
    
    echo "Backup process completed successfully."
    return 0
}

# Parse command line arguments
BACKUP_TYPE="${BACKUP_TYPE:-xtrabackup}"
CUSTOM_NAME=""

while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --type)
            BACKUP_TYPE="$2"
            shift 2
            ;;
        --name)
            CUSTOM_NAME="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--type xtrabackup|mysqldump] [--name custom_backup_name]"
            exit 1
            ;;
    esac
done

# Execute backup and log output
{
    if [ -n "$CUSTOM_NAME" ]; then
        echo "Using custom backup name: $CUSTOM_NAME"
        $WALG_BIN backup-push --permanent "$CUSTOM_NAME"
    else
        perform_backup "$BACKUP_TYPE"
    fi
} 2>&1 | tee -a "$LOG_FILE"

exit ${PIPESTATUS[0]} 