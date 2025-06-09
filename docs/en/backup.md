# Backup Management

**Language / Язык**: [English](backup.md) | [Русский](../backup_management.md)

This document describes how to create and manage backups using wall-be.

## Creating Backups

wall-be provides a simple way to create backups for your databases.

### Full Backups

To create a full backup of your database:

```bash
./wall-be.sh mysql backup  # For MySQL
# or
./wall-be.sh postgresql backup  # For PostgreSQL
```

By default, this creates a backup with an automatically generated name. The backup includes all data necessary to restore your database to the point in time when the backup was created.

### Backup with Custom Name

You can specify a custom name for your backup:

```bash
./wall-be.sh mysql backup --name my_custom_backup
```

### Incremental Backups

For databases that support incremental backups (like PostgreSQL), wall-be automatically handles WAL archiving and incremental backup functionality.

To enable incremental backups for MySQL, configure delta settings in your configuration file:

```bash
WALG_DELTA_MAX_STEPS=7       # Number of delta backups between full backups
WALG_DELTA_ORIGIN=LATEST     # Base backup for delta chains
```

## Listing Backups

To see a list of available backups:

```bash
./wall-be.sh mysql list  # For MySQL
# or
./wall-be.sh postgresql list  # For PostgreSQL
```

This command displays:
- Backup names
- Creation time
- Backup size
- Backup type (full or incremental)

## Verifying Backups

It's important to regularly verify your backups to ensure they can be used for recovery.

### Basic Verification

```bash
./wall-be.sh mysql verify --name LATEST  # Verify the latest MySQL backup
# or
./wall-be.sh postgresql verify --name base_000000010000000000000001  # Verify a specific PostgreSQL backup
```

### Detailed Verification

For a more thorough verification including data integrity checks:

```bash
./wall-be.sh mysql verify --name LATEST --detailed
```

## Backup Retention

wall-be allows you to configure backup retention policies to automatically manage your backup storage.

Configure retention in your configuration file:

```bash
# Keep the 7 most recent full backups
WALG_RETENTION_FULL_BACKUPS=7

# Keep backups for 30 days
WALG_RETENTION_DAYS=30

# Keep 10 backups total
WALG_RETENTION_COUNT=10
```

To manually apply retention policies:

```bash
./wall-be.sh mysql backup --apply-retention
```

## Monitoring Backup Status

### Backup Logs

Backup logs are stored in:
- `/var/log/wall-be/` (when run as root)
- `./logs/` (when run as a regular user)

### Email Notifications

Configure email notifications in your configuration file:

```bash
BACKUP_ALERT_EMAIL=admin@example.com
BACKUP_ALERT_ON_SUCCESS=true
BACKUP_ALERT_ON_ERROR=true
```

### Slack Notifications

Configure Slack notifications:

```bash
BACKUP_SLACK_WEBHOOK=https://hooks.slack.com/services/xxx/yyy/zzz
```

## Troubleshooting Backups

If you encounter issues with backups, see the [Troubleshooting Guide](troubleshooting.md). 