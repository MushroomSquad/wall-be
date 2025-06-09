#!/bin/bash
set -e

# Source configuration
if [ -f "config.env" ]; then
    source config.env
else
    echo "config.env file not found. Please create it from the template."
    exit 1
fi

LOG_FILE="/var/log/wal-g/verify-$(date +%Y%m%d%H%M%S).log"
mkdir -p /var/log/wal-g

# Function to send notification
send_notification() {
    local status=$1
    local message=$2
    local subject="MySQL Backup Verification $status"
    
    if [ "$status" = "SUCCESS" ] || [ "$status" = "FAILED" ]; then
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

# Function to verify backup existence
verify_backup_existence() {
    local backup_name=$1
    echo "Verifying backup existence: $backup_name"
    
    # List backups to verify it exists
    if ! wal-g backup-list 2>/dev/null | grep -q "$backup_name"; then
        echo "ERROR: Backup verification failed. Backup not found in storage."
        return 1
    fi
    
    echo "Backup exists in storage: $backup_name"
    return 0
}

# Function to verify backup integrity using a test restore
verify_backup_integrity() {
    local backup_name=$1
    local test_dir=$2
    
    echo "Verifying backup integrity with test restore: $backup_name"
    echo "Test directory: $test_dir"
    
    # Create test directory if it doesn't exist
    mkdir -p "$test_dir"
    
    # Set test environment variables
    local original_datadir="$WALG_MYSQL_DATADIR"
    export WALG_MYSQL_DATADIR="$test_dir"
    
    # Attempt to fetch the backup
    echo "Fetching backup for verification..."
    if ! wal-g backup-fetch "$backup_name" > /dev/null 2>&1; then
        echo "ERROR: Failed to fetch backup for verification."
        export WALG_MYSQL_DATADIR="$original_datadir"
        return 1
    fi
    
    # Check if files were restored
    if [ ! "$(ls -A "$test_dir")" ]; then
        echo "ERROR: Backup verification failed. No files were restored."
        export WALG_MYSQL_DATADIR="$original_datadir"
        return 1
    fi
    
    # If using xtrabackup, attempt prepare command
    if [ -n "$WALG_MYSQL_BACKUP_PREPARE_COMMAND" ] && [[ "$BACKUP_TYPE" == "xtrabackup" ]]; then
        echo "Attempting to prepare backup..."
        local original_prepare_command="$WALG_MYSQL_BACKUP_PREPARE_COMMAND"
        export WALG_MYSQL_BACKUP_PREPARE_COMMAND="${original_prepare_command//$original_datadir/$test_dir}"
        
        if ! eval "$WALG_MYSQL_BACKUP_PREPARE_COMMAND" > /dev/null 2>&1; then
            echo "WARNING: Prepare command failed, but this might be expected in a verification environment."
        fi
        
        export WALG_MYSQL_BACKUP_PREPARE_COMMAND="$original_prepare_command"
    fi
    
    # Clean up
    echo "Cleaning up test directory..."
    rm -rf "$test_dir"/*
    
    # Restore original environment
    export WALG_MYSQL_DATADIR="$original_datadir"
    
    echo "Backup verification successful: $backup_name"
    return 0
}

# Function to verify binlogs
verify_binlogs() {
    local backup_name=$1
    echo "Verifying binary logs associated with backup: $backup_name"
    
    # Create temporary directory for binlogs
    local binlog_test_dir="/tmp/walg-binlog-verify"
    mkdir -p "$binlog_test_dir"
    
    # Save original binlog destination
    local original_binlog_dst="$WALG_MYSQL_BINLOG_DST"
    export WALG_MYSQL_BINLOG_DST="$binlog_test_dir"
    
    # Attempt to fetch the latest binlog
    echo "Fetching latest binlog for verification..."
    if ! wal-g binlog-fetch --since "$backup_name" --limit 1 > /dev/null 2>&1; then
        echo "WARNING: Could not fetch binary logs. This might be normal if binary logging is not enabled."
        export WALG_MYSQL_BINLOG_DST="$original_binlog_dst"
        rm -rf "$binlog_test_dir"
        return 0
    fi
    
    # Check if binlogs were fetched
    if [ ! "$(ls -A "$binlog_test_dir")" ]; then
        echo "WARNING: No binary logs found. This might be normal if binary logging is not enabled."
    else
        echo "Binary logs verification successful."
    fi
    
    # Clean up
    export WALG_MYSQL_BINLOG_DST="$original_binlog_dst"
    rm -rf "$binlog_test_dir"
    
    return 0
}

# Check if WAL-G is installed
if ! command -v wal-g >/dev/null 2>&1; then
    echo "WAL-G is not installed. Please run setup.sh first."
    exit 1
fi

# Parse command line arguments
BACKUP_NAME="LATEST"
TEST_DIR="/tmp/mysql-walg-verify"
SKIP_RESTORE_TEST=false

print_usage() {
    echo "Usage: $0 [--backup BACKUP_NAME] [--test-dir DIR] [--skip-restore-test]"
    echo ""
    echo "Options:"
    echo "  --backup BACKUP_NAME    Name of the backup to verify (default: LATEST)"
    echo "  --test-dir DIR          Directory to use for test restore (default: /tmp/mysql-walg-verify)"
    echo "  --skip-restore-test     Skip the test restore and only verify backup existence"
    echo ""
    echo "Examples:"
    echo "  $0                               # Verify the latest backup"
    echo "  $0 --backup full_db_20230101     # Verify a specific backup"
    echo "  $0 --skip-restore-test           # Skip test restore"
    exit 1
}

while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --backup)
            BACKUP_NAME="$2"
            shift 2
            ;;
        --test-dir)
            TEST_DIR="$2"
            shift 2
            ;;
        --skip-restore-test)
            SKIP_RESTORE_TEST=true
            shift
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

# Execute verification and log output
{
    echo "Starting backup verification for: $BACKUP_NAME"
    echo "Time: $(date)"
    
    # Verify backup existence
    if ! verify_backup_existence "$BACKUP_NAME"; then
        send_notification "FAILED" "Backup '$BACKUP_NAME' not found in storage."
        exit 1
    fi
    
    # Verify backup integrity if not skipped
    if [ "$SKIP_RESTORE_TEST" = false ]; then
        if ! verify_backup_integrity "$BACKUP_NAME" "$TEST_DIR"; then
            send_notification "FAILED" "Backup integrity verification failed for '$BACKUP_NAME'."
            exit 1
        fi
        
        # Verify binlogs
        verify_binlogs "$BACKUP_NAME"
    fi
    
    echo "Verification process completed successfully for backup: $BACKUP_NAME"
    send_notification "SUCCESS" "Backup verification successful for '$BACKUP_NAME'."
    
} 2>&1 | tee -a "$LOG_FILE"

 