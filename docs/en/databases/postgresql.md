# PostgreSQL with WAL-G

**Language / Язык**: [English](postgresql.md) | [Русский](../../databases/postgresql.md)

This document provides detailed information about using wall-be with PostgreSQL databases.

## Prerequisites

- PostgreSQL 10 or later
- Administrative access to the PostgreSQL server
- WAL-G for PostgreSQL installed (done automatically by the setup script)

## Configuration

### Minimal Configuration

Here's a minimal configuration example for PostgreSQL backup:

```bash
# PostgreSQL connection settings
PGHOST=localhost
PGUSER=postgres
PGPASSWORD=postgres
PGPORT=5432
PGDATABASE=postgres

# Data directory
PGDATA=/var/lib/postgresql/data

# Backup storage location
WALG_S3_PREFIX=s3://my-bucket/postgresql-backups
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
AWS_REGION=us-east-1
```

Save this in a file named `config-postgresql.env`.

### Advanced Configuration

For more advanced PostgreSQL backup scenarios:

```bash
# PostgreSQL connection settings
PGHOST=localhost
PGUSER=postgres
PGPASSWORD=postgres
PGPORT=5432
PGDATABASE=postgres
PGDATA=/var/lib/postgresql/data

# WAL archiving
WALG_PG_WAL_SIZE=16777216
WALG_UPLOAD_WAL_CONCURRENCY=2
USE_WALG_BACKUP=true
USE_WALG_RESTORE=true

# Performance
WALG_UPLOAD_CONCURRENCY=8
WALG_DOWNLOAD_CONCURRENCY=8
WALG_COMPRESSION_METHOD=brotli
WALG_COMPRESSION_LEVEL=3

# Retention settings
WALG_RETENTION_FULL_BACKUPS=7
WALG_RETENTION_DAYS=30
```

## Setting Up PostgreSQL for Backup

The setup process configures your PostgreSQL server for optimal backup with WAL-G:

```bash
./wall-be.sh postgresql setup
```

This command:
1. Downloads and installs WAL-G for PostgreSQL
2. Creates a default configuration file
3. Configures PostgreSQL for WAL archiving
4. Sets up the archive command

### Manual PostgreSQL Configuration

To manually configure PostgreSQL for WAL archiving:

1. Edit `postgresql.conf` to enable WAL archiving:

```
wal_level = replica
archive_mode = on
archive_command = '/path/to/wal-g wal-push %p'
archive_timeout = 60
```

2. Restart PostgreSQL to apply the changes.

## Backup Operations

### Creating a Full Backup

```bash
./wall-be.sh postgresql backup
```

### Creating a Backup with a Custom Name

```bash
./wall-be.sh postgresql backup --name pre_migration_backup
```

### Listing Available Backups

```bash
./wall-be.sh postgresql list
```

### Applying Retention Policies

```bash
./wall-be.sh postgresql backup --apply-retention
```

## Restore Operations

### Restoring the Latest Backup

```bash
./wall-be.sh postgresql restore --name LATEST
```

### Restoring a Specific Backup

```bash
./wall-be.sh postgresql restore --name base_000000010000000000000001
```

### Point-in-Time Recovery (PITR)

PostgreSQL's WAL archiving allows you to restore to any point in time:

```bash
./wall-be.sh postgresql restore --time "2023-04-15 14:30:00"
```

### Restoring to a Different Location

```bash
./wall-be.sh postgresql restore --name LATEST --target-dir /var/lib/postgresql/data-restored
```

## Advanced Features

### Continuous Archiving

With PostgreSQL, WAL-G continuously archives WAL segments to provide point-in-time recovery capability. This is enabled by default during setup.

To manually push a WAL segment:

```bash
./wall-be.sh postgresql wal-push /path/to/wal/segment
```

### Backup Verification

To verify a backup:

```bash
./wall-be.sh postgresql verify --name LATEST
```

### Partial Restore

To restore only specific databases:

```bash
./wall-be.sh postgresql restore --name LATEST --database my_database
```

## Troubleshooting PostgreSQL Backups

### Common Issues

#### "WAL segment not found" Error

**Solution**: Check that WAL archiving is properly configured and working.

#### "Archive command failed" Error

**Solution**: Verify the archive command in postgresql.conf and ensure WAL-G has proper permissions.

#### "Cannot connect to PostgreSQL server" Error

**Solution**: Check PostgreSQL is running and connection parameters are correct.

For more troubleshooting help, see the [general troubleshooting guide](../../en/troubleshooting.md). 