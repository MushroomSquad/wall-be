# Troubleshooting

**Language / Язык**: [English](troubleshooting.md) | [Русский](../troubleshooting.md)

This document provides solutions for common issues you might encounter when using wall-be.

## Common Issues

### Setup Issues

#### WAL-G Download Fails

**Symptoms:**
- Error message: "Failed to download WAL-G"

**Solutions:**
1. Check your internet connection
2. Verify that the download URL is accessible
3. Try downloading manually and placing in the `./bin` directory

#### Permission Denied

**Symptoms:**
- Error message: "Permission denied"

**Solutions:**
1. Make sure the script is executable: `chmod +x wall-be.sh`
2. Check permissions on config files and directories
3. Run with sudo if accessing system directories

### Configuration Issues

#### Invalid Configuration

**Symptoms:**
- Error message: "Invalid configuration" or "Missing required configuration"

**Solutions:**
1. Check your configuration file for syntax errors
2. Ensure all required parameters are set
3. Use the `--debug` flag to see detailed configuration information

#### Storage Connection Failed

**Symptoms:**
- Error message: "Failed to connect to storage"

**Solutions:**
1. Verify storage credentials
2. Check network connectivity to storage service
3. Ensure storage bucket/container exists and is accessible

### Backup Issues

#### Backup Creation Failed

**Symptoms:**
- Error message: "Backup failed" or "WAL-G exited with error"

**Solutions:**
1. Check database connectivity
2. Ensure sufficient disk space
3. Verify database user has sufficient privileges
4. Check the detailed log for specific errors

#### Slow Backup Performance

**Symptoms:**
- Backups take longer than expected

**Solutions:**
1. Adjust concurrency settings: `WALG_UPLOAD_CONCURRENCY`
2. Check network bandwidth to storage
3. Consider using compression: `WALG_COMPRESSION_METHOD=lz4`

### Restore Issues

#### Restore Failed

**Symptoms:**
- Error message: "Restore failed" or "Could not restore backup"

**Solutions:**
1. Ensure the specified backup exists
2. Check that the database server is stopped
3. Verify sufficient disk space
4. Check permissions on the target directory

#### Point-in-Time Recovery Failed

**Symptoms:**
- Error message: "Could not find WAL file for timeline"

**Solutions:**
1. Ensure all required WAL files are available
2. Check that the specified time is valid
3. Verify WAL archiving was enabled when backups were created

## Logging and Debugging

### Enabling Debug Mode

For detailed debugging information, use the `--debug` flag:

```bash
./wall-be.sh mysql backup --debug
```

### Checking Logs

Logs are stored in:
- `/var/log/wall-be/` (when run as root)
- `./logs/` (when run as a regular user)

### Common Log Messages

#### "No space left on device"

**Solution:** Free up disk space or specify a different temporary directory:

```bash
./wall-be.sh mysql backup --temp-dir /path/with/space
```

#### "Authentication failed"

**Solution:** Check your database or storage credentials in the configuration file.

## Database-Specific Issues

### MySQL Issues

#### Binary Logging Not Enabled

**Symptoms:**
- Warning: "Binary logging not enabled"

**Solution:** 
Enable binary logging in MySQL by editing my.cnf:

```
[mysqld]
log-bin=mysql-bin
server-id=1
```

### PostgreSQL Issues

#### WAL Archiving Failed

**Symptoms:**
- Error: "WAL archiving failed"

**Solution:**
Check PostgreSQL settings and permissions:

```
wal_level = replica
archive_mode = on
archive_command = 'true'
```

## Getting More Help

If you can't find a solution to your problem here:

1. Check the detailed logs
2. Run with `--debug` flag for more information
3. Open an issue on the GitHub repository
4. Check for similar issues that have been resolved 