# MySQL/MariaDB with WAL-G

**Language / Язык**: [English](mysql.md) | [Русский](../../databases/mysql.md)

This document provides detailed information about using wall-be with MySQL and MariaDB databases.

## Prerequisites

- MySQL/MariaDB server installed and running
- Sufficient privileges to perform backup and restore operations
- WAL-G for MySQL installed (done automatically by the setup script)

## Configuration

### Minimal Configuration

Below is a minimal configuration example for MySQL backup:

```bash
# MySQL connection settings
WALG_MYSQL_HOST=localhost
WALG_MYSQL_USER=root
WALG_MYSQL_PASSWORD=password
WALG_MYSQL_PORT=3306

# Backup storage location
WALG_S3_PREFIX=s3://my-bucket/mysql-backups
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
AWS_REGION=us-east-1
```

Save this in a file named `config-mysql.env`.

### Advanced Configuration

For more advanced MySQL backup scenarios:

```bash
# MySQL connection settings
WALG_MYSQL_HOST=localhost
WALG_MYSQL_USER=root
WALG_MYSQL_PASSWORD=password
WALG_MYSQL_PORT=3306
WALG_MYSQL_DATADIR=/var/lib/mysql

# Xtrabackup configuration
WALG_MYSQL_BACKUP_PREPARE=true
WALG_MYSQL_SSL_CA=/path/to/ca.pem

# Backup performance
WALG_UPLOAD_CONCURRENCY=4
WALG_DOWNLOAD_CONCURRENCY=4
WALG_COMPRESSION_METHOD=lz4

# Retention settings
WALG_RETENTION_FULL_BACKUPS=5
WALG_RETENTION_DAYS=30
```

## Setting Up MySQL for Backup

The setup process configures your MySQL server for optimal backup with WAL-G:

```bash
./wall-be.sh mysql setup
```

This command:
1. Downloads and installs WAL-G for MySQL
2. Creates a default configuration file
3. Checks MySQL configuration

### Manual MySQL Configuration

To manually configure MySQL for optimal backup:

1. Enable binary logging in your MySQL configuration:

```
[mysqld]
log-bin=mysql-bin
binlog_format=ROW
server-id=1
```

2. Create a MySQL user with backup privileges:

```sql
CREATE USER 'backup'@'localhost' IDENTIFIED BY 'password';
GRANT RELOAD, LOCK TABLES, REPLICATION CLIENT, PROCESS, SUPER ON *.* TO 'backup'@'localhost';
FLUSH PRIVILEGES;
```

## Backup Operations

### Creating a Full Backup

```bash
./wall-be.sh mysql backup
```

### Creating a Backup with a Custom Name

```bash
./wall-be.sh mysql backup --name pre_migration_backup
```

### Listing Available Backups

```bash
./wall-be.sh mysql list
```

### Applying Retention Policies

```bash
./wall-be.sh mysql backup --apply-retention
```

## Restore Operations

### Restoring the Latest Backup

```bash
./wall-be.sh mysql restore --name LATEST
```

### Restoring a Specific Backup

```bash
./wall-be.sh mysql restore --name mysql_backup_20230415_120000
```

### Restoring to a Different Location

```bash
./wall-be.sh mysql restore --name LATEST --target-dir /var/lib/mysql-restored
```

### Restoring Specific Databases

```bash
./wall-be.sh mysql restore --name LATEST --databases "db1,db2,db3"
```

## Advanced Features

### Incremental Backups

While MySQL itself doesn't have built-in incremental backup functionality like PostgreSQL's WAL archiving, WAL-G provides a way to implement incremental backups using delta backups:

```bash
# Configure delta backups in config-mysql.env
WALG_DELTA_MAX_STEPS=5
WALG_DELTA_ORIGIN=LATEST
```

Then run backups as usual:

```bash
./wall-be.sh mysql backup
```

### Backup Verification

To verify a backup:

```bash
./wall-be.sh mysql verify --name LATEST
```

### Partial Restore

To restore only specific tables:

```bash
./wall-be.sh mysql restore --name LATEST --database my_database --tables "table1,table2"
```

## Troubleshooting MySQL Backups

### Common Issues

#### "Access denied" Error

**Solution**: Check MySQL user permissions and credentials.

#### "Cannot connect to MySQL server" Error

**Solution**: Verify MySQL is running and accessible from the host.

#### "Error: Binary log not enabled" Warning

**Solution**: Enable binary logging in your MySQL configuration.

For more troubleshooting help, see the [general troubleshooting guide](../../en/troubleshooting.md). 