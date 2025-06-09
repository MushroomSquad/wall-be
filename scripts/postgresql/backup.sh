#!/bin/bash
set -e

# Source configuration
if [ -f "$WALL_BE_CONFIG_FILE" ]; then
    source "$WALL_BE_CONFIG_FILE"
else
    echo "Configuration file not found. Please specify a config file with --config."
    exit 1
fi

LOG_FILE="/var/log/wal-g/pg-backup-$(date +%Y%m%d%H%M%S).log"
mkdir -p /var/log/wal-g

# Detect WAL-G binary path
WALG_BIN="${WALG_PG_BINPATH:-/usr/local/bin/wal-g}"

if [ ! -f "$WALG_BIN" ]; then
    # Try alternative paths
    if [ -f "/usr/local/bin/wal-g-pg" ]; then
        WALG_BIN="/usr/local/bin/wal-g-pg"
    elif [ -f "/usr/local/bin/wal-g" ]; then
        WALG_BIN="/usr/local/bin/wal-g"
    else
        echo "WAL-G binary not found. Please install WAL-G or specify WALG_PG_BINPATH."
        exit 1
    fi
fi

echo "Using WAL-G binary: $WALG_BIN"

# Function to send notification
send_notification() {
    local status=$1
    local message=$2
    local subject="PostgreSQL Backup $status"
    
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
    if ! sudo -u postgres $WALG_BIN backup-list 2>/dev/null | grep -q "$backup_name"; then
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
        sudo -u postgres $WALG_BIN backup-retain FULL "$WALG_RETENTION_FULL_BACKUPS" --confirm
    fi
    
    if [ -n "$WALG_RETENTION_DAYS" ]; then
        echo "Retaining backups made within $WALG_RETENTION_DAYS days..."
        sudo -u postgres $WALG_BIN backup-retain DAYS "$WALG_RETENTION_DAYS" --confirm
    fi
    
    if [ -n "$WALG_RETENTION_COUNT" ]; then
        echo "Retaining only $WALG_RETENTION_COUNT most recent backups..."
        sudo -u postgres $WALG_BIN backup-retain COUNT "$WALG_RETENTION_COUNT" --confirm
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
    echo "Starting PostgreSQL backup with WAL-G..."
    local start_time=$(date +%s)
    local backup_type="${1:-full}"
    local backup_name=$(create_backup_name "$backup_type")
    
    echo "Backup name: $backup_name"
    echo "Backup type: $backup_type"
    echo "Start time: $(date)"
    
    # Perform the backup
    if [ "$USE_WALG_UPLOAD" = "true" ]; then
        # Use WAL-G's built-in backup command
        echo "Using wal-g backup-push..."
        sudo -u postgres $WALG_BIN backup-push --permanent "$backup_name"
    else
        # For compatibility with older WAL-G versions
        echo "Using pg_basebackup with wal-g..."
        sudo -u postgres $WALG_BIN backup-push "$PGDATA"
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
    
    # Clean up old backups
    cleanup_old_backups
    
    # Send success notification
    send_notification "SUCCESS" "Backup $backup_name completed successfully. Duration: $duration seconds."
    
    echo "Backup process completed successfully."
    return 0
}

# Parse command line arguments
BACKUP_TYPE="full"
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
            echo "Usage: $0 [--type full|delta] [--name custom_backup_name]"
            exit 1
            ;;
    esac
done

# Execute backup and log output
{
    if [ -n "$CUSTOM_NAME" ]; then
        echo "Using custom backup name: $CUSTOM_NAME"
        sudo -u postgres $WALG_BIN backup-push --permanent "$CUSTOM_NAME"
    else
        perform_backup "$BACKUP_TYPE"
    fi
} 2>&1 | tee -a "$LOG_FILE"

exit ${PIPESTATUS[0]} 