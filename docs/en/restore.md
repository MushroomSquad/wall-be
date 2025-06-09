# Backup Restoration

**Language / Язык**: [English](restore.md) | [Русский](../restore.md)

This document describes how to restore databases from backups using wall-be.

## Basic Restore

### Restoring from the Latest Backup

To restore your database from the latest available backup:

```bash
./wall-be.sh mysql restore --name LATEST  # For MySQL
# or
./wall-be.sh postgresql restore --name LATEST  # For PostgreSQL
```

### Restoring from a Specific Backup

You can restore from a specific backup by providing its name:

```bash
./wall-be.sh mysql restore --name mysql_backup_20230415_120000
# or
./wall-be.sh postgresql restore --name base_000000010000000000000001
```

To get a list of available backups, use the list command:

```bash
./wall-be.sh mysql list
```

## Advanced Restore Options

### Point-in-Time Recovery (PITR)

For PostgreSQL, you can restore to a specific point in time:

```bash
./wall-be.sh postgresql restore --time "2023-04-15 14:30:00"
```

This will restore the database to the state it was in at the specified time, as long as the necessary WAL files are available.

### Restore to a Different Location

To restore to a different directory:

```bash
./wall-be.sh mysql restore --name LATEST --target-dir /path/to/restore/directory
```

### Restore with Different Database Parameters

You can specify different database parameters for the restored database:

```bash
./wall-be.sh postgresql restore --name LATEST --config-file /path/to/new/postgresql.conf
```

## Restore Verification

After restoration, it's recommended to verify that the database is functioning correctly:

```bash
./wall-be.sh mysql verify --restored
```

This will run basic consistency checks on the restored database.

## Partial Restore

### Restoring Specific Databases

For MySQL, you can restore specific databases:

```bash
./wall-be.sh mysql restore --name LATEST --databases "db1,db2,db3"
```

### Restoring Specific Tables

For MySQL, you can restore specific tables:

```bash
./wall-be.sh mysql restore --name LATEST --database db1 --tables "table1,table2"
```

## Troubleshooting Restore Issues

If you encounter issues during restore:

1. Check that the backup exists and is accessible
2. Verify that the database server is stopped before restore
3. Ensure you have sufficient disk space
4. Check permissions on the target directory
5. Review the logs for detailed error messages

For more detailed troubleshooting, see the [Troubleshooting Guide](troubleshooting.md). 