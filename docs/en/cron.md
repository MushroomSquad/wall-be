# Scheduling Backups

**Language / Язык**: [English](cron.md) | [Русский](../cron.md)

This document explains how to set up scheduled backups using cron with wall-be.

## Setting Up Scheduled Backups

wall-be can be easily integrated with cron to automate your backup processes.

### Using the Built-in Scheduler

wall-be provides a scheduler command to simplify setting up cron jobs:

```bash
./wall-be.sh mysql schedule --interval daily
# or
./wall-be.sh postgresql schedule --interval weekly
```

Available intervals:
- `hourly`
- `daily`
- `weekly`
- `monthly`

### Custom Schedule with Cron Syntax

For more control, you can specify a custom cron schedule:

```bash
./wall-be.sh mysql schedule --cron "0 2 * * *"
```

This example schedules a backup every day at 2:00 AM.

## Viewing Scheduled Backups

To see all currently scheduled backups:

```bash
./wall-be.sh mysql schedule --list
# or
./wall-be.sh postgresql schedule --list
```

## Removing Scheduled Backups

To remove a scheduled backup:

```bash
./wall-be.sh mysql schedule --remove daily
# or
./wall-be.sh postgresql schedule --remove "0 2 * * *"
```

## Manual Cron Setup

If you prefer to set up cron jobs manually, you can add entries directly to your crontab:

```bash
crontab -e
```

Then add lines like:

```
# Daily MySQL backup at 2:00 AM
0 2 * * * /path/to/wall-be.sh mysql backup --config /path/to/config-mysql.env

# Weekly PostgreSQL backup on Sunday at 3:00 AM
0 3 * * 0 /path/to/wall-be.sh postgresql backup --config /path/to/config-postgresql.env
```

## Advanced Scheduling

### Retention Policies

You can combine scheduled backups with automatic retention policies:

```bash
./wall-be.sh mysql schedule --interval daily --apply-retention
```

This will create backups daily and automatically apply retention policies.

### Notification on Failure

To receive notifications only when a backup fails:

```bash
./wall-be.sh mysql schedule --interval daily --alert-on-error
```

Configure the email address or Slack webhook in your configuration file.

### Logging

Scheduled backups will log to:
- `/var/log/wall-be/` (when run as root)
- `./logs/` (when run as a regular user)

You can specify a custom log file:

```bash
./wall-be.sh mysql schedule --interval daily --log-file /path/to/logfile.log
```

## System Integration

### Systemd Timers

As an alternative to cron, you can use systemd timers for scheduling backups:

```bash
./wall-be.sh mysql schedule --use-systemd --interval daily
```

This will create and enable a systemd timer unit for the backup.

### Docker Scheduling

For Docker deployments, see the [Docker Integration Guide](docker.md) for scheduling options. 