#!/bin/bash
set -e

# Source configuration
if [ -f "config.env" ]; then
    source config.env
else
    echo "config.env file not found. Please create it from the template."
    exit 1
fi

# Function to get absolute path
get_absolute_path() {
    local path="$1"
    echo "$(cd "$(dirname "$path")" && pwd)/$(basename "$path")"
}

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root or with sudo privileges."
    exit 1
fi

# Check if BACKUP_SCHEDULE is set
if [ -z "$BACKUP_SCHEDULE" ]; then
    echo "BACKUP_SCHEDULE is not set in config.env. Using default schedule (daily at 1:00 AM)."
    BACKUP_SCHEDULE="0 1 * * *"
fi

# Check if BACKUP_USER is set
if [ -z "$BACKUP_USER" ]; then
    echo "BACKUP_USER is not set in config.env. Using 'root' as default."
    BACKUP_USER="root"
fi

# Check if BACKUP_TYPE is set
if [ -z "$BACKUP_TYPE" ]; then
    echo "BACKUP_TYPE is not set in config.env. Using 'xtrabackup' as default."
    BACKUP_TYPE="xtrabackup"
fi

# Get the absolute path of scripts
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CREATE_BACKUP_SCRIPT=$(get_absolute_path "$SCRIPT_DIR/create_backup.sh")
CONFIG_ENV=$(get_absolute_path "$SCRIPT_DIR/config.env")

# Check if create_backup.sh exists and is executable
if [ ! -f "$CREATE_BACKUP_SCRIPT" ]; then
    echo "Error: $CREATE_BACKUP_SCRIPT does not exist."
    exit 1
fi

if [ ! -x "$CREATE_BACKUP_SCRIPT" ]; then
    echo "Making $CREATE_BACKUP_SCRIPT executable..."
    chmod +x "$CREATE_BACKUP_SCRIPT"
fi

# Create wrapper script that sources config and runs backup
WRAPPER_SCRIPT="/usr/local/bin/mysql-walg-backup"
cat > "$WRAPPER_SCRIPT" << EOF
#!/bin/bash
source "$CONFIG_ENV"
"$CREATE_BACKUP_SCRIPT" --type "$BACKUP_TYPE"
EOF

chmod +x "$WRAPPER_SCRIPT"

# Create cron job
CRON_FILE="/etc/cron.d/mysql-walg-backup"
echo "Creating cron job in $CRON_FILE..."

cat > "$CRON_FILE" << EOF
# MySQL WAL-G backup schedule
# Created on $(date)
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

$BACKUP_SCHEDULE $BACKUP_USER $WRAPPER_SCRIPT > /var/log/wal-g/cron-backup.log 2>&1
EOF

chmod 644 "$CRON_FILE"

# Create log rotation configuration
LOGROTATE_FILE="/etc/logrotate.d/mysql-walg"
echo "Creating log rotation configuration in $LOGROTATE_FILE..."

cat > "$LOGROTATE_FILE" << EOF
/var/log/wal-g/*.log {
    daily
    rotate 14
    compress
    delaycompress
    missingok
    notifempty
    create 0640 root root
}
EOF

chmod 644 "$LOGROTATE_FILE"

# Verify cron job installation
echo "Verifying cron job installation..."
if [ -f "$CRON_FILE" ]; then
    echo "Cron job installed successfully."
    echo "Schedule: $BACKUP_SCHEDULE"
    echo "Command: $WRAPPER_SCRIPT"
    echo "User: $BACKUP_USER"
    echo "Log: /var/log/wal-g/cron-backup.log"
else
    echo "Error: Failed to install cron job."
    exit 1
fi

# Test cron setup
echo "Testing cron setup (this won't actually run the backup)..."
if [ -x "$(command -v run-parts)" ]; then
    run-parts --test /etc/cron.d | grep mysql-walg-backup && echo "Cron setup test passed." || echo "Cron setup test failed."
else
    echo "run-parts command not found. Skipping cron test."
fi

echo "Backup schedule configured successfully."
echo "MySQL backups will run with the following schedule: $BACKUP_SCHEDULE"
echo ""
echo "To manually run a backup, execute:"
echo "  $CREATE_BACKUP_SCRIPT --type $BACKUP_TYPE"
echo ""
echo "To view scheduled cron jobs, run:"
echo "  crontab -l -u $BACKUP_USER" 