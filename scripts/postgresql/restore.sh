#!/bin/bash
set -e

# Source configuration
if [ -f "config-pg.env" ]; then
    source config-pg.env
else
    echo "config-pg.env file not found. Please create it from the template."
    exit 1
fi

LOG_FILE="/var/log/wal-g/pg-restore-$(date +%Y%m%d%H%M%S).log"
mkdir -p /var/log/wal-g

# Function to send notification
send_notification() {
    local status=$1
    local message=$2
    local subject="PostgreSQL Restore $status"
    
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

# Function to check PostgreSQL status
check_postgresql_status() {
    if systemctl is-active --quiet postgresql; then
        echo "PostgreSQL is running. It will be stopped during restore."
        return 0
    else
        echo "PostgreSQL is not running. Continuing with restore."
        return 1
    fi
}

# Function to stop PostgreSQL
stop_postgresql() {
    echo "Stopping PostgreSQL service..."
    systemctl stop postgresql
    
    # Wait for PostgreSQL to stop completely
    sleep 5
    
    # Double-check it's stopped
    if pgrep -x "postgres" > /dev/null; then
        echo "ERROR: PostgreSQL is still running. Please stop it manually and try again."
        exit 1
    fi
    
    echo "PostgreSQL service stopped."
}

# Function to start PostgreSQL
start_postgresql() {
    echo "Starting PostgreSQL service..."
    systemctl start postgresql
    
    # Wait for PostgreSQL to start
    local max_attempts=30
    local attempt=0
    
    echo "Waiting for PostgreSQL to start..."
    while [ $attempt -lt $max_attempts ]; do
        if sudo -u postgres psql -c "SELECT 1" >/dev/null 2>&1; then
            echo "PostgreSQL started successfully."
            return 0
        fi
        
        attempt=$((attempt + 1))
        sleep 2
    done
    
    echo "ERROR: PostgreSQL failed to start within the expected time."
    return 1
}

# Function to clear data directory
clear_data_directory() {
    echo "Clearing PostgreSQL data directory: ${PGDATA}"
    
    # Safety check: don't delete root directory
    if [ "${PGDATA}" = "/" ] || [ -z "${PGDATA}" ]; then
        echo "ERROR: Invalid data directory. Aborting to prevent catastrophic deletion."
        exit 1
    fi
    
    # Remove everything in the data directory
    rm -rf "${PGDATA:?}"/*
    
    echo "Data directory cleared."
}

# Function to create recovery configuration
create_recovery_conf() {
    local pitr_time=$1
    
    # For PostgreSQL 12 and newer, recovery settings are in postgresql.conf and standby.signal
    if [ -f "${PGDATA}/PG_VERSION" ]; then
        PG_VERSION=$(cat "${PGDATA}/PG_VERSION")
        if [ "${PG_VERSION}" -ge "12" ]; then
            echo "PostgreSQL version ${PG_VERSION} detected. Using recovery settings in postgresql.conf."
            
            # Create standby.signal if needed for PITR
            if [ -n "$pitr_time" ]; then
                touch "${PGDATA}/standby.signal"
                chown postgres:postgres "${PGDATA}/standby.signal"
                
                # Add recovery settings to postgresql.auto.conf
                sudo -u postgres bash -c "cat > ${PGDATA}/postgresql.auto.conf << EOF
# Recovery settings added by WAL-G restore script
recovery_target_time = '$pitr_time'
recovery_target_action = 'promote'
restore_command = 'wal-g wal-fetch \"%f\" \"%p\"'
EOF"
            fi
        else
            # For PostgreSQL 11 and older, use recovery.conf
            echo "PostgreSQL version ${PG_VERSION} detected. Using recovery.conf for recovery settings."
            
            if [ -n "$pitr_time" ]; then
                sudo -u postgres bash -c "cat > ${PGDATA}/recovery.conf << EOF
# Recovery settings added by WAL-G restore script
restore_command = 'wal-g wal-fetch \"%f\" \"%p\"'
recovery_target_time = '$pitr_time'
recovery_target_action = 'promote'
EOF"
            else
                sudo -u postgres bash -c "cat > ${PGDATA}/recovery.conf << EOF
# Recovery settings added by WAL-G restore script
restore_command = 'wal-g wal-fetch \"%f\" \"%p\"'
EOF"
            fi
            
            chown postgres:postgres "${PGDATA}/recovery.conf"
        fi
    else
        echo "WARNING: Could not determine PostgreSQL version. Recovery configuration may need to be adjusted manually."
    fi
}

# Function to restore a backup
restore_backup() {
    local backup_name=$1
    local pitr_time=$2
    
    echo "Starting restore process..."
    echo "Backup to restore: $backup_name"
    
    # List available backups
    echo "Available backups:"
    sudo -u postgres wal-g backup-list
    
    # Verify backup exists
    if [ "$backup_name" != "LATEST" ] && ! sudo -u postgres wal-g backup-list | grep -q "$backup_name"; then
        echo "ERROR: Backup '$backup_name' not found."
        send_notification "FAILED" "Backup '$backup_name' not found during restore attempt."
        exit 1
    fi
    
    # Stop PostgreSQL
    check_postgresql_status && stop_postgresql
    
    # Clear data directory
    clear_data_directory
    
    # Fetch and restore backup
    echo "Fetching backup $backup_name..."
    if [ "$USE_WALG_RESTORE" = "true" ]; then
        # Use WAL-G's built-in restore command
        sudo -u postgres wal-g backup-fetch "$PGDATA" "$backup_name"
    else
        # For compatibility with older WAL-G versions
        sudo -u postgres wal-g backup-fetch "$PGDATA" "$backup_name"
    fi
    
    # Fix permissions
    echo "Setting correct permissions on data directory..."
    chown -R postgres:postgres "${PGDATA}"
    chmod 0700 "${PGDATA}"
    
    # Create recovery configuration if PITR is requested
    if [ -n "$pitr_time" ]; then
        echo "Configuring for point-in-time recovery to: $pitr_time"
        create_recovery_conf "$pitr_time"
    fi
    
    # Create simple recovery configuration if no PITR
    if [ -z "$pitr_time" ]; then
        # For PostgreSQL 12+, we need to set restore_command
        if [ -f "${PGDATA}/PG_VERSION" ]; then
            PG_VERSION=$(cat "${PGDATA}/PG_VERSION")
            if [ "${PG_VERSION}" -ge "12" ]; then
                sudo -u postgres bash -c "cat > ${PGDATA}/postgresql.auto.conf << EOF
# Recovery settings added by WAL-G restore script
restore_command = 'wal-g wal-fetch \"%f\" \"%p\"'
EOF"
            fi
        fi
    fi
    
    # Start PostgreSQL
    if ! start_postgresql; then
        send_notification "FAILED" "Failed to start PostgreSQL after restoring backup '$backup_name'."
        exit 1
    fi
    
    # Wait for recovery to complete
    if [ -n "$pitr_time" ]; then
        echo "Waiting for point-in-time recovery to complete..."
        # Check for recovery completion
        local max_attempts=60
        local attempt=0
        
        while [ $attempt -lt $max_attempts ]; do
            # Check if still in recovery mode
            if ! sudo -u postgres psql -c "SELECT pg_is_in_recovery();" | grep -q "t"; then
                echo "Recovery completed successfully."
                break
            fi
            
            attempt=$((attempt + 1))
            sleep 5
            echo "Still in recovery mode... (attempt $attempt/$max_attempts)"
        done
        
        if [ $attempt -eq $max_attempts ]; then
            echo "WARNING: Recovery is taking longer than expected. Check PostgreSQL logs for details."
        fi
    fi
    
    echo "Restore process completed successfully."
    send_notification "SUCCESS" "Successfully restored backup '$backup_name'$([ -n "$pitr_time" ] && echo " with point-in-time recovery to $pitr_time")."
    return 0
}

# Check if WAL-G is installed
if ! command -v wal-g >/dev/null 2>&1 && ! command -v wal-g-pg >/dev/null 2>&1; then
    echo "WAL-G is not installed. Please run pg_setup.sh first."
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
echo "WARNING: This will replace the current PostgreSQL database with backup '$BACKUP_NAME'."
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