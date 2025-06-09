# Configuration Guide

**Language / Язык**: [English](configuration.md) | [Русский](../configuration.md)

This document describes how to configure wall-be for different databases and storage options.

## Configuration File

wall-be uses environment files (`.env`) for configuration. These files define environment variables that control the behavior of WAL-G and the backup process.

### Configuration File Location

When you run `./wall-be.sh <database> setup`, the script creates a default configuration file in the current directory:

- For MySQL: `config-mysql.env`
- For PostgreSQL: `config-postgresql.env`

You can also specify a custom configuration file using the `--config` parameter:

```bash
./wall-be.sh mysql backup --config /path/to/my/config.env
```

## Common Configuration Parameters

### Storage Configuration

wall-be supports multiple storage options for backups:

#### Amazon S3

```bash
WALG_S3_PREFIX=s3://my-bucket/backups
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
AWS_REGION=us-east-1
```

#### Google Cloud Storage

```bash
WALG_GS_PREFIX=gs://my-bucket/backups
GOOGLE_APPLICATION_CREDENTIALS=/path/to/credentials.json
```

#### Microsoft Azure

```bash
WALG_AZ_PREFIX=azure://my-container/backups
AZURE_STORAGE_ACCOUNT=your-account
AZURE_STORAGE_KEY=your-key
```

#### Local File System

```bash
WALG_FILE_PREFIX=/path/to/backup/directory
```

### Compression Settings

```bash
# Available methods: lz4, brotli, pgzip, none
WALG_COMPRESSION_METHOD=lz4

# Compression level (1-9)
WALG_COMPRESSION_LEVEL=3
```

### Retention Policy

Retention policies determine how long backups are kept:

```bash
# Number of full backups to retain
WALG_RETENTION_FULL_BACKUPS=7

# Keep backups for this many days
WALG_RETENTION_DAYS=30

# Maximum number of backups to keep
WALG_RETENTION_COUNT=10
```

### Performance Tuning

```bash
# Number of parallel upload workers
WALG_UPLOAD_CONCURRENCY=16

# Number of parallel download workers
WALG_DOWNLOAD_CONCURRENCY=10

# Disk I/O concurrency
WALG_UPLOAD_DISK_CONCURRENCY=2
```

### Notification Settings

Configure notifications for backup operations:

```bash
# Email notifications
BACKUP_ALERT_EMAIL=admin@example.com

# Slack webhook for notifications
BACKUP_SLACK_WEBHOOK=https://hooks.slack.com/services/xxx/yyy/zzz

# When to send notifications
BACKUP_ALERT_ON_SUCCESS=true
BACKUP_ALERT_ON_ERROR=true
```

## Database-Specific Configuration

### MySQL Configuration

```bash
# Database connection
WALG_MYSQL_HOST=localhost
WALG_MYSQL_USER=root
WALG_MYSQL_PASSWORD=password
WALG_MYSQL_PORT=3306

# Path to MySQL data directory
WALG_MYSQL_DATADIR=/var/lib/mysql
```

### PostgreSQL Configuration

```bash
# Database connection
PGHOST=localhost
PGUSER=postgres
PGPASSWORD=postgres
PGPORT=5432
PGDATABASE=postgres

# Path to PostgreSQL data directory
PGDATA=/var/lib/postgresql/data

# WAL settings
WALG_PG_WAL_SIZE=16777216
```

## Advanced Configuration

For more advanced configuration options, please refer to the database-specific documentation:

- [MySQL Advanced Configuration](../databases/en/mysql.md)
- [PostgreSQL Advanced Configuration](../databases/en/postgresql.md) 