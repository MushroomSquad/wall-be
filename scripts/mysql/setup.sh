#!/bin/bash
set -e

# Source configuration
if [ -f "config.env" ]; then
    source config.env
else
    echo "config.env file not found. Please create it from the template."
    exit 1
fi

echo "=== MySQL WAL-G Setup ==="
echo "This script will install WAL-G and configure MySQL for backup and restore operations."

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root or with sudo privileges."
    exit 1
fi

# Create directories
echo "Creating necessary directories..."
mkdir -p /var/log/wal-g
mkdir -p ${WALG_MYSQL_BINLOG_DST}
chmod 755 /var/log/wal-g
chmod -R 755 ${WALG_MYSQL_BINLOG_DST}

# Function to detect OS
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    elif [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        OS=$DISTRIB_ID
        VER=$DISTRIB_RELEASE
    else
        OS=$(uname -s)
        VER=$(uname -r)
    fi
    echo "Detected OS: $OS $VER"
}

# Install dependencies based on OS
install_dependencies() {
    echo "Installing dependencies..."
    case $OS in
        "Ubuntu" | "Debian")
            apt-get update
            apt-get install -y wget curl ca-certificates xtrabackup mysql-client
            ;;
        "CentOS" | "Red Hat" | "Fedora" | "Amazon Linux")
            yum install -y wget curl ca-certificates
            # Install percona repository for xtrabackup
            yum install -y https://repo.percona.com/yum/percona-release-latest.noarch.rpm
            yum install -y percona-xtrabackup-24 mysql
            ;;
        *)
            echo "Unsupported OS: $OS. Please install dependencies manually."
            exit 1
            ;;
    esac
}

# Install WAL-G
install_walg() {
    echo "Installing WAL-G..."
    
    # Determine latest WAL-G version
    LATEST_RELEASE=$(curl -s https://api.github.com/repos/wal-g/wal-g/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    if [ -z "$LATEST_RELEASE" ]; then
        echo "Error: Could not determine the latest WAL-G release. Using default v2.0.1"
        LATEST_RELEASE="v2.0.1"
    fi
    
    echo "Latest WAL-G release: $LATEST_RELEASE"
    
    # Determine architecture
    ARCH=$(uname -m)
    if [ "$ARCH" = "x86_64" ]; then
        ARCH="amd64"
    elif [ "$ARCH" = "aarch64" ]; then
        ARCH="arm64"
    fi
    
    # Download WAL-G binary
    WALG_URL="https://github.com/wal-g/wal-g/releases/download/${LATEST_RELEASE}/wal-g-mysql-${LATEST_RELEASE}-linux-${ARCH}.tar.gz"
    echo "Downloading WAL-G from: $WALG_URL"
    
    wget -q "$WALG_URL" -O /tmp/wal-g.tar.gz
    tar -xzf /tmp/wal-g.tar.gz -C /tmp
    mv /tmp/wal-g-mysql /usr/local/bin/wal-g
    chmod +x /usr/local/bin/wal-g
    rm /tmp/wal-g.tar.gz
    
    echo "WAL-G installed at /usr/local/bin/wal-g"
}

# Configure MySQL
configure_mysql() {
    echo "Configuring MySQL for WAL-G..."
    
    # Extract username and password from WALG_MYSQL_DATASOURCE_NAME
    DB_USER=$(echo $WALG_MYSQL_DATASOURCE_NAME | cut -d':' -f1)
    DB_PASS=$(echo $WALG_MYSQL_DATASOURCE_NAME | cut -d':' -f2 | cut -d'@' -f1)
    
    # Create MySQL configuration backup
    MYSQL_CNF="/etc/mysql/my.cnf"
    if [ -f "/etc/mysql/mysql.conf.d/mysqld.cnf" ]; then
        MYSQL_CNF="/etc/mysql/mysql.conf.d/mysqld.cnf"
    fi
    
    cp "$MYSQL_CNF" "${MYSQL_CNF}.bak.$(date +%Y%m%d%H%M%S)"
    
    # Check if binary logging is enabled
    if ! grep -q "log_bin" "$MYSQL_CNF"; then
        echo "Enabling binary logging in MySQL configuration..."
        echo "" >> "$MYSQL_CNF"
        echo "# WAL-G Configuration added on $(date)" >> "$MYSQL_CNF"
        echo "log_bin = mysql-bin" >> "$MYSQL_CNF"
        echo "binlog_format = ROW" >> "$MYSQL_CNF"
        echo "sync_binlog = 1" >> "$MYSQL_CNF"
        echo "server_id = 1" >> "$MYSQL_CNF"
        echo "binlog_row_image = FULL" >> "$MYSQL_CNF"
        
        echo "MySQL configuration updated. A restart is required for changes to take effect."
    else
        echo "Binary logging is already enabled in MySQL configuration."
    fi
    
    # Create backup user if needed
    echo "Creating backup user in MySQL..."
    mysql -e "CREATE USER IF NOT EXISTS 'backup'@'localhost' IDENTIFIED BY 'backuppassword';"
    mysql -e "GRANT RELOAD, LOCK TABLES, REPLICATION CLIENT, CREATE TABLESPACE, PROCESS, SUPER, CREATE, INSERT, SELECT ON *.* TO 'backup'@'localhost';"
    mysql -e "FLUSH PRIVILEGES;"
    
    echo "MySQL backup user created."
    echo "Please update config.env with the backup user credentials."
}

# Test WAL-G configuration
test_walg() {
    echo "Testing WAL-G configuration..."
    
    # Source config.env again to ensure we have the latest settings
    source config.env
    
    # Test WAL-G version
    echo "WAL-G version:"
    wal-g --version
    
    # Test connection to MySQL
    echo "Testing MySQL connection..."
    if mysql -e "SELECT 1" > /dev/null 2>&1; then
        echo "MySQL connection successful."
    else
        echo "Error: Could not connect to MySQL. Please check your configuration."
        exit 1
    fi
    
    echo "WAL-G setup completed successfully!"
    echo "You can now create backups using create_backup.sh"
}

# Main execution
detect_os
install_dependencies
install_walg
configure_mysql
test_walg

echo "Setup completed. Please review and update config.env as needed."
echo "Next steps:"
echo "1. Update config.env with appropriate values"
echo "2. Run ./create_backup.sh to create your first backup"
echo "3. Run ./schedule_backups.sh to set up automatic backups" 