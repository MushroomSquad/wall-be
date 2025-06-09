# PostgreSQL с WAL-G

**Language / Язык**: [English](../en/databases/postgresql.md) | [Русский](postgresql.md)

Этот документ описывает использование wall-be для резервного копирования и восстановления PostgreSQL с помощью WAL-G.

## Содержание

- [Требования](#требования)
- [Установка](#установка)
- [Конфигурация](#конфигурация)
- [Создание резервных копий](#создание-резервных-копий)
- [Восстановление из резервной копии](#восстановление-из-резервной-копии)
- [Архивирование WAL](#архивирование-wal)
- [Планирование резервного копирования](#планирование-резервного-копирования)
- [Работа с Docker](#работа-с-docker)
- [Устранение неполадок](#устранение-неполадок)

## Требования

- PostgreSQL 9.6+
- Операционная система Linux
- Доступ к хранилищу (S3, GCS, Azure или локальная файловая система)
- Привилегии root для установки WAL-G и настройки PostgreSQL

## Установка

Для установки WAL-G для PostgreSQL используйте команду:

```bash
./wall-be.sh postgresql setup
```

Этот скрипт:

1. Загрузит и установит WAL-G
2. Настроит PostgreSQL для работы с WAL-G и архивированием WAL
3. Создаст необходимые конфигурационные файлы
4. Проверит доступ к хранилищу

## Конфигурация

### Конфигурационный файл

Основные параметры конфигурации находятся в файле `config/postgresql.env.template`:

```bash
# Подключение к PostgreSQL
PGHOST=localhost
PGPORT=5432
PGUSER=postgres
PGPASSWORD=postgres
PGDATABASE=postgres
PGDATA=/var/lib/postgresql/data

# Хранилище (раскомментируйте один из следующих вариантов)
WALG_S3_PREFIX=s3://bucket-name/postgresql
# WALG_GS_PREFIX=gs://bucket-name/postgresql
# WALG_AZ_PREFIX=azure://container-name/postgresql
# WALG_FILE_PREFIX=/path/to/backup/directory

# Сжатие
WALG_COMPRESSION_METHOD=lz4

# Хранение
WALG_RETAIN_FULL_BACKUPS=7

# Уведомления
BACKUP_ALERT_EMAIL=admin@example.com
BACKUP_SLACK_WEBHOOK=https://hooks.slack.com/services/xxx/yyy/zzz
BACKUP_ALERT_ON_SUCCESS=true
BACKUP_ALERT_ON_ERROR=true
```

### Конфигурация хранилища

#### Amazon S3

```bash
WALG_S3_PREFIX=s3://my-bucket/postgresql-backups
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
AWS_REGION=us-east-1
```

#### Google Cloud Storage

```bash
WALG_GS_PREFIX=gs://my-bucket/postgresql-backups
GOOGLE_APPLICATION_CREDENTIALS=/path/to/credentials.json
```

#### Microsoft Azure

```bash
WALG_AZ_PREFIX=azure://my-container/postgresql-backups
AZURE_STORAGE_ACCOUNT=your-account
AZURE_STORAGE_KEY=your-key
```

#### Локальное хранилище

```bash
WALG_FILE_PREFIX=/path/to/backup/directory
```

### Настройка архивирования WAL

WAL-G автоматически настраивает PostgreSQL для использования архивирования WAL. Следующие параметры будут добавлены в `postgresql.conf`:

```
wal_level = replica
archive_mode = on
archive_command = 'wal-g wal-push "%p"'
archive_timeout = 60
```

## Создание резервных копий

### Полная резервная копия

```bash
./wall-be.sh postgresql backup
```

### Проверка списка резервных копий

```bash
./wall-be.sh postgresql list
```

### Проверка целостности резервной копии

```bash
./wall-be.sh postgresql verify --name LATEST
```

## Восстановление из резервной копии

### Восстановление из последней резервной копии

```bash
./wall-be.sh postgresql restore --name LATEST
```

### Восстановление из определенной резервной копии

```bash
./wall-be.sh postgresql restore --name base_000000010000000000000001
```

### Восстановление на определенный момент времени (PITR)

```bash
./wall-be.sh postgresql restore --time "2023-04-15 14:30:00"
```

## Архивирование WAL

WAL-G автоматически обрабатывает архивирование WAL для PostgreSQL, что обеспечивает:

1. Непрерывное архивирование изменений данных
2. Возможность восстановления на произвольный момент времени (PITR)
3. Минимизация потерь данных в случае сбоя

### Проверка архивирования WAL

```bash
./wall-be.sh postgresql wal-verify
```

### Ручная отправка WAL-файла

```bash
./wall-be.sh postgresql wal-push /path/to/wal/file
```

### Получение WAL-файлов

```bash
./wall-be.sh postgresql wal-fetch wal_file /path/to/destination
```

## Планирование резервного копирования

### Настройка расписания через Cron

```bash
./wall-be.sh postgresql schedule --schedule "0 0 * * *"
```

### Примеры расписания

- Ежедневно в полночь: `0 0 * * *`
- Каждые 6 часов: `0 */6 * * *`
- Каждый понедельник в 3:00: `0 3 * * 1`

## Работа с Docker

### Запуск PostgreSQL с WAL-G в Docker

```bash
cd docker/postgresql
docker-compose up -d
```

### Конфигурация Docker версии

Все настройки выполняются через переменные окружения в `docker-compose.yml`.

## Устранение неполадок

### Распространенные проблемы

1. **Ошибка подключения к PostgreSQL**: Проверьте параметры подключения в конфигурационном файле.
2. **Ошибка доступа к хранилищу**: Проверьте конфигурацию хранилища и разрешения доступа.
3. **Ошибка архивирования WAL**: Убедитесь, что PostgreSQL имеет разрешения на выполнение команды архивирования.

### Журналы

- Журналы WAL-G находятся в `/var/log/wal-g/`
- Журналы PostgreSQL находятся в стандартной директории журналов PostgreSQL

### Диагностика

Для диагностики проблем используйте команду:

```bash
./wall-be.sh postgresql verify --verbose
```