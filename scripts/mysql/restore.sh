#!/bin/bash
set -e

# Source configuration
if [ -f "config.env" ]; then
    source config.env
else
    echo "config.env file not found. Please create it from the template."
    exit 1
fi

LOG_FILE="/var/log/wal-g/restore-$(date +%Y%m%d%H%M%S).log"
mkdir -p /var/log/wal-g

# Function to send notification
send_notification() {
    local status=$1
    local message=$2
    local subject="MySQL Restore $status"
    
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

# Function to check MySQL status
check_mysql_status() {
    if systemctl is-active --quiet mysql; then
        echo "MySQL is running. It will be stopped during restore."
        return 0
    elif systemctl is-active --quiet mariadb; then
        echo "MariaDB is running. It will be stopped during restore."
        return 0
    else
        echo "MySQL/MariaDB is not running. Continuing with restore."
        return 1
    fi
}

# Function to stop MySQL
stop_mysql() {
    echo "Stopping MySQL/MariaDB service..."
    if systemctl is-active --quiet mysql; then
        systemctl stop mysql
    elif systemctl is-active --quiet mariadb; then
        systemctl stop mariadb
    fi
    
    # Wait for MySQL to stop completely
    sleep 5
    
    # Double-check it's stopped
    if pgrep -x "mysqld" > /dev/null || pgrep -x "mariadbd" > /dev/null; then
        echo "ERROR: MySQL/MariaDB is still running. Please stop it manually and try again."
        exit 1
    fi
    
    echo "MySQL/MariaDB service stopped."
}

# Function to start MySQL
start_mysql() {
    echo "Starting MySQL/MariaDB service..."
    if [ -f /lib/systemd/system/mysql.service ]; then
        systemctl start mysql
    elif [ -f /lib/systemd/system/mariadb.service ]; then
        systemctl start mariadb
    fi
    
    # Wait for MySQL to start
    local max_attempts=30
    local attempt=0
    
    echo "Waiting for MySQL/MariaDB to start..."
    while [ $attempt -lt $max_attempts ]; do
        if mysqladmin ping --silent; then
            echo "MySQL/MariaDB started successfully."
            return 0
        fi
        
        attempt=$((attempt + 1))
        sleep 2
    done
    
    echo "ERROR: MySQL/MariaDB failed to start within the expected time."
    return 1
}

# Function to clear data directory
clear_data_directory() {
    echo "Clearing MySQL data directory: ${WALG_MYSQL_DATADIR}"
    
    # Safety check: don't delete root directory
    if [ "${WALG_MYSQL_DATADIR}" = "/" ] || [ -z "${WALG_MYSQL_DATADIR}" ]; then
        echo "ERROR: Invalid data directory. Aborting to prevent catastrophic deletion."
        exit 1
    fi
    
    # Remove everything except configuration files
    find "${WALG_MYSQL_DATADIR}" -mindepth 1 -not -name "*.cnf" -delete
    
    echo "Data directory cleared."
}

# Function to restore a backup
restore_backup() {
    local backup_name=$1
    local pitr_time=$2
    
    echo "Starting restore process..."
    echo "Backup to restore: $backup_name"
    
    # List available backups
    echo "Available backups:"
    wal-g backup-list
    
    # Verify backup exists
    if [ "$backup_name" != "LATEST" ] && ! wal-g backup-list | grep -q "$backup_name"; then
        echo "ERROR: Backup '$backup_name' not found."
        send_notification "FAILED" "Backup '$backup_name' not found during restore attempt."
        exit 1
    fi
    
    # Stop MySQL
    check_mysql_status && stop_mysql
    
    # Clear data directory
    clear_data_directory
    
    # Fetch and restore backup
    echo "Fetching backup $backup_name..."
    wal-g backup-fetch "$backup_name"
    
    # Check if we need to run prepare command
    if [ -n "$WALG_MYSQL_BACKUP_PREPARE_COMMAND" ]; then
        echo "Preparing backup with command: $WALG_MYSQL_BACKUP_PREPARE_COMMAND"
        eval "$WALG_MYSQL_BACKUP_PREPARE_COMMAND"
    fi
    
    # Fix permissions
    echo "Setting correct permissions on data directory..."
    chown -R mysql:mysql "${WALG_MYSQL_DATADIR}"
    
    # Start MySQL
    if ! start_mysql; then
        send_notification "FAILED" "Failed to start MySQL after restoring backup '$backup_name'."
        exit 1
    fi
    
    # Point-in-time recovery if requested
    if [ -n "$pitr_time" ]; then
        echo "Performing point-in-time recovery to: $pitr_time"
        
        # Fetch binlogs
        wal-g binlog-fetch --since "$backup_name" --until "$pitr_time"
        
        # Replay binlogs
        echo "Replaying binary logs..."
        wal-g binlog-replay --since "$backup_name" --until "$pitr_time"
        
        echo "Point-in-time recovery completed."
    fi
    
    echo "Restore process completed successfully."
    send_notification "SUCCESS" "Successfully restored backup '$backup_name'$([ -n "$pitr_time" ] && echo " with point-in-time recovery to $pitr_time")."
    return 0
}

# Check if WAL-G is installed
if ! command -v wal-g >/dev/null 2>&1; then
    echo "WAL-G is not installed. Please run setup.sh first."
    exit 1
fi

# Parse command line arguments
BACKUP_NAME="LATEST"
PITR_TIME=""

print_usage() {
    echo "Usage: $0 [--backup BACKUP_NAME] [--pitr TIMESTAMP]"
    echo ""
    echo "Options:"
    echo "  --backup BACKUP_NAME    Name of the backup to restore (default: LATEST)"
    echo "  --pitr TIMESTAMP        Point-in-time recovery timestamp in RFC3339 format"
    echo "                          (e.g., '2023-01-01T12:00:00Z')"
    echo ""
    echo "Examples:"
    echo "  $0                          # Restore the latest backup"
    echo "  $0 --backup full_db_20230101  # Restore a specific backup"
    echo "  $0 --backup LATEST --pitr '2023-01-01T12:00:00Z'  # Restore with PITR"
    exit 1
}

while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --backup)
            BACKUP_NAME="$2"
            shift 2
            ;;
        --pitr)
            PITR_TIME="$2"
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

# Confirm before proceeding
echo "WARNING: This will replace the current MySQL database with backup '$BACKUP_NAME'."
if [ -n "$PITR_TIME" ]; then
    echo "Point-in-time recovery will be performed to: $PITR_TIME"
fi
echo ""
echo "Are you sure you want to proceed? (yes/no)"
read -r confirm

if [ "$confirm" != "yes" ]; then
    echo "Restore cancelled."
    exit 0
fi

# Execute restore and log output
{
    restore_backup "$BACKUP_NAME" "$PITR_TIME"
} 2>&1 | tee -a "$LOG_FILE"

exit ${PIPESTATUS[0]} 