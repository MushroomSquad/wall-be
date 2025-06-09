#!/bin/bash
set -e

# Source configuration
if [ -f "config-pg.env" ]; then
    source config-pg.env
else
    echo "config-pg.env file not found. Please create it from the template."
    exit 1
fi

echo "=== PostgreSQL WAL-G Setup ==="
echo "This script will install WAL-G and configure PostgreSQL for backup and restore operations."

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root or with sudo privileges."
    exit 1
fi

# Create directories
echo "Creating necessary directories..."
mkdir -p /var/log/wal-g
chmod 755 /var/log/wal-g

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
            apt-get install -y wget curl ca-certificates postgresql-client postgresql-common
            ;;
        "CentOS" | "Red Hat" | "Fedora" | "Amazon Linux")
            yum install -y wget curl ca-certificates postgresql postgresql-server
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
    
    # Download WAL-G binary for PostgreSQL
    WALG_URL="https://github.com/wal-g/wal-g/releases/download/${LATEST_RELEASE}/wal-g-pg-${LATEST_RELEASE}-linux-${ARCH}.tar.gz"
    echo "Downloading WAL-G from: $WALG_URL"
    
    wget -q "$WALG_URL" -O /tmp/wal-g.tar.gz
    tar -xzf /tmp/wal-g.tar.gz -C /tmp
    mv /tmp/wal-g-pg /usr/local/bin/wal-g-pg
    chmod +x /usr/local/bin/wal-g-pg
    rm /tmp/wal-g.tar.gz
    
    # Create a symlink for convenience
    ln -sf /usr/local/bin/wal-g-pg /usr/local/bin/wal-g
    
    echo "WAL-G installed at /usr/local/bin/wal-g-pg (symlinked to /usr/local/bin/wal-g)"
}

# Configure PostgreSQL
configure_postgresql() {
    echo "Configuring PostgreSQL for WAL-G..."
    
    # Check if PostgreSQL is installed and running
    if ! command -v psql > /dev/null; then
        echo "PostgreSQL is not installed. Please install PostgreSQL first."
        exit 1
    fi
    
    # Try to connect to PostgreSQL
    if ! sudo -u postgres psql -c "SELECT 1" > /dev/null 2>&1; then
        echo "Cannot connect to PostgreSQL. Make sure it's running."
        exit 1
    fi
    
    # Backup the postgresql.conf file
    PG_VERSION=$(sudo -u postgres psql -t -c "SHOW server_version;" | grep -oE '^[0-9]+')
    PG_CONF_DIR="/etc/postgresql/${PG_VERSION}/main"
    
    if [ ! -d "$PG_CONF_DIR" ]; then
        # Try to find the PostgreSQL configuration directory
        PG_CONF_DIR=$(sudo -u postgres psql -t -c "SHOW config_file;" | xargs dirname)
    fi
    
    if [ ! -d "$PG_CONF_DIR" ]; then
        echo "Could not determine PostgreSQL configuration directory."
        echo "Please modify the WAL archive settings manually."
        return
    fi
    
    PG_CONF="${PG_CONF_DIR}/postgresql.conf"
    PG_CONF_BAK="${PG_CONF}.bak.$(date +%Y%m%d%H%M%S)"
    
    echo "Creating backup of PostgreSQL configuration: $PG_CONF_BAK"
    cp "$PG_CONF" "$PG_CONF_BAK"
    
    # Check and modify WAL settings in postgresql.conf
    WAL_LEVEL=$(sudo -u postgres psql -t -c "SHOW wal_level;")
    ARCHIVE_MODE=$(sudo -u postgres psql -t -c "SHOW archive_mode;")
    
    if [[ "$WAL_LEVEL" != *"replica"* && "$WAL_LEVEL" != *"logical"* ]]; then
        echo "Setting wal_level to 'replica' in PostgreSQL configuration..."
        sudo -u postgres psql -c "ALTER SYSTEM SET wal_level = 'replica';"
    fi
    
    if [[ "$ARCHIVE_MODE" != *"on"* ]]; then
        echo "Setting archive_mode to 'on' in PostgreSQL configuration..."
        sudo -u postgres psql -c "ALTER SYSTEM SET archive_mode = 'on';"
    fi
    
    # Set up archive command
    ARCHIVE_COMMAND="'wal-g wal-push %p'"
    echo "Setting archive_command to $ARCHIVE_COMMAND in PostgreSQL configuration..."
    sudo -u postgres psql -c "ALTER SYSTEM SET archive_command = $ARCHIVE_COMMAND;"
    
    # Set other recommended settings
    sudo -u postgres psql -c "ALTER SYSTEM SET archive_timeout = '60s';"
    sudo -u postgres psql -c "ALTER SYSTEM SET max_wal_senders = '3';"
    sudo -u postgres psql -c "ALTER SYSTEM SET max_wal_size = '1GB';"
    sudo -u postgres psql -c "ALTER SYSTEM SET min_wal_size = '80MB';"
    
    echo "PostgreSQL configuration updated. A restart is required for changes to take effect."
    echo "You can restart PostgreSQL with: sudo systemctl restart postgresql"
    
    # Create .pgpass file for password-less connection if password is provided
    if [ -n "$PGPASSWORD" ]; then
        PGPASS_FILE="/var/lib/postgresql/.pgpass"
        echo "Creating .pgpass file for PostgreSQL user..."
        echo "*:*:*:$PGUSER:$PGPASSWORD" > "$PGPASS_FILE"
        chown postgres:postgres "$PGPASS_FILE"
        chmod 600 "$PGPASS_FILE"
    fi
    
    # Create environment file for PostgreSQL user
    PG_ENV_FILE="/var/lib/postgresql/.wal-g.env"
    echo "Creating WAL-G environment file for PostgreSQL user..."
    cat config-pg.env > "$PG_ENV_FILE"
    chown postgres:postgres "$PG_ENV_FILE"
    chmod 600 "$PG_ENV_FILE"
    
    echo "WAL-G environment file created at $PG_ENV_FILE"
}

# Test WAL-G configuration
test_walg() {
    echo "Testing WAL-G configuration..."
    
    # Source config.env again to ensure we have the latest settings
    source config-pg.env
    
    # Test WAL-G version
    echo "WAL-G version:"
    wal-g --version || wal-g-pg --version
    
    # Test connection to PostgreSQL
    echo "Testing PostgreSQL connection..."
    if sudo -u postgres psql -c "SELECT 1" > /dev/null 2>&1; then
        echo "PostgreSQL connection successful."
    else
        echo "Error: Could not connect to PostgreSQL. Please check your configuration."
        exit 1
    fi
    
    echo "WAL-G setup completed successfully!"
    echo "You can now create backups using pg_create_backup.sh"
}

# Create scripts directory and copy scripts
create_scripts() {
    echo "Creating PostgreSQL-specific scripts..."
    
    # Make PostgreSQL-specific versions of the scripts
    for script in create_backup.sh restore_backup.sh list_backups.sh verify_backup.sh schedule_backups.sh; do
        if [ -f "$script" ]; then
            PG_SCRIPT="pg_${script}"
            cp "$script" "$PG_SCRIPT"
            chmod +x "$PG_SCRIPT"
            # Replace config.env with config-pg.env in the script
            sed -i 's/config.env/config-pg.env/g' "$PG_SCRIPT"
            echo "Created $PG_SCRIPT"
        fi
    done
    
    echo "PostgreSQL-specific scripts created."
}

# Main execution
detect_os
install_dependencies
install_walg
configure_postgresql
create_scripts
test_walg

echo "Setup completed. Please review and update config-pg.env as needed."
echo "Next steps:"
echo "1. Restart PostgreSQL: sudo systemctl restart postgresql"
echo "2. Update config-pg.env with appropriate values"
echo "3. Run ./pg_create_backup.sh to create your first backup"
echo "4. Run ./pg_schedule_backups.sh to set up automatic backups" 