# Docker Integration

**Language / Язык**: [English](docker.md) | [Русский](../docker.md)

This document explains how to use wall-be with Docker for database backup and restore operations.

## Docker Setup

wall-be provides Docker support for easy deployment and integration with containerized databases.

### Prerequisites

- Docker installed on your system
- Docker Compose (for multi-container deployments)
- Basic knowledge of Docker concepts

## Using Pre-built Docker Images

wall-be offers pre-built Docker images that include WAL-G and all necessary dependencies:

```bash
docker pull mushroomsquad/wall-be:latest
# or specific database version
docker pull mushroomsquad/wall-be:mysql
docker pull mushroomsquad/wall-be:postgresql
```

## Running wall-be in Docker

### Basic Usage

To run wall-be commands in Docker:

```bash
docker run --rm \
  -v /path/to/config.env:/app/config.env \
  -v /path/to/backup/storage:/backup \
  mushroomsquad/wall-be:mysql \
  backup
```

### Accessing Host Databases

To back up a database running on the host machine:

```bash
docker run --rm \
  --network=host \
  -v /path/to/config.env:/app/config.env \
  -v /path/to/backup/storage:/backup \
  mushroomsquad/wall-be:postgresql \
  backup
```

## Docker Compose Integration

### Sample Docker Compose for MySQL

Create a `docker-compose.yml` file:

```yaml
version: '3'

services:
  mysql:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: password
      MYSQL_DATABASE: mydatabase
    volumes:
      - mysql_data:/var/lib/mysql
    ports:
      - "3306:3306"

  wall-be:
    image: mushroomsquad/wall-be:mysql
    depends_on:
      - mysql
    environment:
      WALG_MYSQL_HOST: mysql
      WALG_MYSQL_USER: root
      WALG_MYSQL_PASSWORD: password
      WALG_MYSQL_PORT: 3306
      WALG_FILE_PREFIX: /backup
    volumes:
      - backup_data:/backup

volumes:
  mysql_data:
  backup_data:
```

Start the services:

```bash
docker-compose up -d
```

### Sample Docker Compose for PostgreSQL

```yaml
version: '3'

services:
  postgres:
    image: postgres:14
    environment:
      POSTGRES_PASSWORD: postgres
      POSTGRES_USER: postgres
      POSTGRES_DB: postgres
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  wall-be:
    image: mushroomsquad/wall-be:postgresql
    depends_on:
      - postgres
    environment:
      PGHOST: postgres
      PGUSER: postgres
      PGPASSWORD: postgres
      PGDATABASE: postgres
      PGDATA: /var/lib/postgresql/data
      WALG_FILE_PREFIX: /backup
    volumes:
      - backup_data:/backup

volumes:
  postgres_data:
  backup_data:
```

## Scheduling Backups with Docker

### Using Docker Cron

You can set up scheduled backups using Docker's cron capabilities:

```yaml
services:
  wall-be-cron:
    image: mushroomsquad/wall-be:mysql
    depends_on:
      - mysql
    environment:
      WALG_MYSQL_HOST: mysql
      WALG_MYSQL_USER: root
      WALG_MYSQL_PASSWORD: password
      WALG_FILE_PREFIX: /backup
    volumes:
      - backup_data:/backup
    entrypoint: |
      /bin/sh -c '
        echo "0 2 * * * /app/wall-be.sh mysql backup" > /etc/crontabs/root
        crond -f -d 8
      '
```

### Using Host Cron with Docker

Alternatively, you can use the host's cron to run Docker containers:

```bash
0 2 * * * docker run --rm --network=host -v /path/to/config.env:/app/config.env -v /path/to/backup:/backup mushroomsquad/wall-be:postgresql backup
```

## Advanced Docker Configuration

### Custom Docker Network

```yaml
networks:
  backup_network:
    driver: bridge

services:
  postgres:
    networks:
      - backup_network
  
  wall-be:
    networks:
      - backup_network
```

### Environment Variables vs Config Files

You can use either environment variables in your Docker Compose file or mount a configuration file:

```yaml
services:
  wall-be:
    # Using environment variables
    environment:
      WALG_MYSQL_HOST: mysql
      WALG_MYSQL_USER: root
      # more variables...
    
    # OR using a mounted config file
    volumes:
      - ./config-mysql.env:/app/config.env
    command: mysql backup --config /app/config.env
```

## Best Practices

1. **Volume Management**: Use Docker volumes to store backups persistently
2. **Security**: Never include sensitive credentials in Dockerfiles
3. **Resource Limits**: Set appropriate memory and CPU limits
4. **Logging**: Configure proper log handling for backup operations
5. **Health Checks**: Implement health checks to monitor backup container status

## Troubleshooting Docker Deployments

### Common Issues

#### "Cannot connect to database" Error

**Solution**: Check network configuration and ensure the database is accessible from the container.

#### Permission Issues

**Solution**: Ensure mounted volumes have correct permissions.

#### Container Exits Immediately

**Solution**: Check logs with `docker logs <container_name>` and verify configuration.

## General Information

wall-be provides Docker images for all supported databases. Each image includes:

- Pre-installed database
- Pre-installed WAL-G
- Configured integration between them
- Support for automatic backups
- Ability to restore from backup at startup

## MySQL in Docker

### Quick Start

```bash
cd docker/mysql
docker-compose up -d
```

### Configuration

Main configuration parameters are specified in `docker-compose.yml` through environment variables:

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
  
  # Backup parameters
  WALG_COMPRESSION_METHOD: lz4
  WALG_DELTA_MAX_STEPS: 7
  
  # Backup schedule (cron format)
  BACKUP_SCHEDULE: "0 0 * * *"
  
  # Restore at startup
  RESTORE_FROM_BACKUP: LATEST
```

### Building the Image

```bash
cd docker/mysql
docker build -t wall-be-mysql:latest .
```

### Manual Backup

```bash
docker exec wall-be-mysql wal-g backup-push
```

### Viewing Backup List

```bash
docker exec wall-be-mysql wal-g backup-list
```

### Restoring from Backup

```bash
# Stop the container
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

Main configuration parameters are specified in `docker-compose.yml` through environment variables:

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
  
  # Backup parameters
  WALG_COMPRESSION_METHOD: lz4
  WALG_DELTA_MAX_STEPS: 7
  
  # Backup schedule (cron format)
  BACKUP_SCHEDULE: "0 0 * * *"
  
  # Restore at startup
  RESTORE_FROM_BACKUP: LATEST
```

### Building the Image

```bash
cd docker/postgresql
docker build -t wall-be-postgresql:latest .
```

### Manual Backup

```bash
docker exec wall-be-postgresql wal-g-pg backup-push $PGDATA
```

### Viewing Backup List

```bash
docker exec wall-be-postgresql wal-g-pg backup-list
```

### Restoring from Backup

```bash
# Create new container with restore
docker run -d --name wall-be-postgresql-restored \
  -e RESTORE_FROM_BACKUP=LATEST \
  wall-be-postgresql:latest
```

## Using Different Storage Types

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
  # Mount credentials.json file
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

To receive notifications about backup status, you can configure email or Slack notifications:

```yaml
environment:
  BACKUP_ALERT_EMAIL: admin@example.com
  BACKUP_SLACK_WEBHOOK: https://hooks.slack.com/services/xxx/yyy/zzz
  BACKUP_ALERT_ON_SUCCESS: "true"
  BACKUP_ALERT_ON_ERROR: "true"
```

## Tips and Recommendations

1. **Data Persistence**: Always mount a volume for data and backup directories to avoid data loss when recreating the container.

2. **Security**: Store sensitive data (passwords, access keys) in Docker secrets or external secret management services.

3. **Restore Testing**: Regularly test the restore process in a separate container to ensure it works correctly.

4. **Monitoring**: Set up monitoring for containers and backup processes using tools like Prometheus and Grafana. 