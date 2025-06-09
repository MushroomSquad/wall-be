# Using wall-be with Docker

**Language / Язык**: [English](en/docker.md) | [Русский](docker.md)

This document describes how to use wall-be with Docker for various databases.

## General Information

wall-be предоставляет Docker-образы для всех поддерживаемых баз данных. Каждый образ включает:

- Предустановленную базу данных
- Предустановленный WAL-G
- Настроенную интеграцию между ними
- Поддержку автоматического резервного копирования
- Возможность восстановления из резервной копии при запуске

## MySQL in Docker

### Quick Start

```bash
cd docker/mysql
docker-compose up -d
```

### Configuration

The main configuration parameters are specified in `docker-compose.yml` via environment variables:

```yaml
environment:
  # MySQL configuration
  MYSQL_ROOT_PASSWORD: mysecretpassword
  MYSQL_DATABASE: mydb
  MYSQL_USER: user
  MYSQL_PASSWORD: password
  
  # WAL-G configuration
  WALG_S3_PREFIX: s3://my-bucket/mysql-backups
  AWS_ACCESS_KEY_ID: your-access-key
  AWS_SECRET_ACCESS_KEY: your-secret-key
  AWS_REGION: us-east-1
  
  # Backup configuration parameters
  WALG_COMPRESSION_METHOD: lz4
  WALG_DELTA_MAX_STEPS: 7
  
  # Backup schedule (cron format)
  BACKUP_SCHEDULE: "0 0 * * *"
  
  # Restore from backup on start
  RESTORE_FROM_BACKUP: LATEST
```

### Build Image

```bash
cd docker/mysql
docker build -t wall-be-mysql:latest .
```

### Manual Backup

```bash
docker exec wall-be-mysql wal-g backup-push
```

### View Backup List

```bash
docker exec wall-be-mysql wal-g backup-list
```

### Restore from Backup

```bash
# Stop container
docker stop wall-be-mysql

# Start with restore
docker run -d --name wall-be-mysql \
  -e RESTORE_FROM_BACKUP=LATEST \
  wall-be-mysql:latest
```

## PostgreSQL in Docker

### Quick Start

```bash
cd docker/postgresql
docker-compose up -d
```

### Configuration

The main configuration parameters are specified in `docker-compose.yml` via environment variables:

```yaml
environment:
  # PostgreSQL configuration
  POSTGRES_PASSWORD: mysecretpassword
  POSTGRES_USER: postgres
  POSTGRES_DB: postgres
  
  # WAL-G configuration
  WALG_S3_PREFIX: s3://my-bucket/postgresql-backups
  AWS_ACCESS_KEY_ID: your-access-key
  AWS_SECRET_ACCESS_KEY: your-secret-key
  AWS_REGION: us-east-1
  
  # Backup configuration parameters
  WALG_COMPRESSION_METHOD: lz4
  WALG_DELTA_MAX_STEPS: 7
  
  # Backup schedule (cron format)
  BACKUP_SCHEDULE: "0 0 * * *"
  
  # Restore from backup on start
  RESTORE_FROM_BACKUP: LATEST
```

### Build Image

```bash
cd docker/postgresql
docker build -t wall-be-postgresql:latest .
```

### Manual Backup

```bash
docker exec wall-be-postgresql wal-g-pg backup-push $PGDATA
```

### View Backup List

```bash
docker exec wall-be-postgresql wal-g-pg backup-list
```

### Restore from Backup

```bash
# Create new container with restore
docker run -d --name wall-be-postgresql-restored \
  -e RESTORE_FROM_BACKUP=LATEST \
  wall-be-postgresql:latest
```

## Using Different Types of Storage

### Amazon S3

```yaml
environment:
  WALG_S3_PREFIX: s3://my-bucket/backups
  AWS_ACCESS_KEY_ID: your-access-key
  AWS_SECRET_ACCESS_KEY: your-secret-key
  AWS_REGION: us-east-1
```

### Google Cloud Storage

```yaml
environment:
  WALG_GS_PREFIX: gs://my-bucket/backups
  # Mounting credentials.json file
volumes:
  - ./credentials.json:/credentials.json
  GOOGLE_APPLICATION_CREDENTIALS: /credentials.json
```

### Microsoft Azure

```yaml
environment:
  WALG_AZ_PREFIX: azure://my-container/backups
  AZURE_STORAGE_ACCOUNT: your-account
  AZURE_STORAGE_KEY: your-key
```

### Local Storage

```yaml
environment:
  WALG_FILE_PREFIX: /backups
volumes:
  - backups:/backups
```

## Monitoring and Notifications

To receive notifications about the state of backup operations, you can configure sending messages via email or Slack:

```yaml
environment:
  BACKUP_ALERT_EMAIL: admin@example.com
  BACKUP_SLACK_WEBHOOK: https://hooks.slack.com/services/xxx/yyy/zzz
  BACKUP_ALERT_ON_SUCCESS: "true"
  BACKUP_ALERT_ON_ERROR: "true"
```

## Tips and Recommendations

1. **Data Preservation**: Always mount a volume for data and backup directories to avoid data loss when recreating the container.

2. **Security**: Store sensitive data (passwords, access keys) in Docker secrets or external secret management systems.

3. **Test Restore Process**: Regularly test the restore process in a separate container to ensure it works correctly.

4. **Мониторинг**: Настройте мониторинг контейнеров и процессов резервного копирования с помощью таких инструментов, как Prometheus и Grafana. 