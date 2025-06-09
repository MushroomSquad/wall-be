# MySQL/MariaDB с WAL-G

**Language / Язык**: [English](../en/databases/mysql.md) | [Русский](mysql.md)

Этот документ описывает использование wall-be для резервного копирования и восстановления MySQL/MariaDB с помощью WAL-G.

## Содержание

- [Требования](#требования)
- [Установка](#установка)
- [Конфигурация](#конфигурация)
- [Создание резервных копий](#создание-резервных-копий)
- [Восстановление из резервной копии](#восстановление-из-резервной-копии)
- [Планирование резервного копирования](#планирование-резервного-копирования)
- [Работа с Docker](#работа-с-docker)
- [Устранение неполадок](#устранение-неполадок)

## Требования

- MySQL 5.7+ или MariaDB 10.2+
- Операционная система Linux
- Доступ к хранилищу (S3, GCS, Azure или локальная файловая система)
- Привилегии root для установки WAL-G и настройки MySQL

## Установка

Для установки WAL-G для MySQL используйте команду:

```bash
./wall-be.sh mysql setup
```

Этот скрипт:

1. Загрузит и установит WAL-G
2. Настроит MySQL для работы с WAL-G
3. Создаст необходимые конфигурационные файлы
4. Проверит доступ к хранилищу

## Конфигурация

### Конфигурационный файл

Основные параметры конфигурации находятся в файле `config/mysql.env.template`:

```bash
# Подключение к MySQL
WALG_MYSQL_HOST=localhost
WALG_MYSQL_USER=root
WALG_MYSQL_PASSWORD=password
WALG_MYSQL_PORT=3306

# Хранилище (раскомментируйте один из следующих вариантов)
WALG_S3_PREFIX=s3://bucket-name/mysql
# WALG_GS_PREFIX=gs://bucket-name/mysql
# WALG_AZ_PREFIX=azure://container-name/mysql
# WALG_FILE_PREFIX=/path/to/backup/directory

# Сжатие
WALG_COMPRESSION_METHOD=lz4

# Хранение
WALG_RETAIN_FULL_BACKUPS=7
WALG_DELTA_MAX_STEPS=6
WALG_DELTA_ORIGIN=LATEST

# Уведомления
BACKUP_ALERT_EMAIL=admin@example.com
BACKUP_SLACK_WEBHOOK=https://hooks.slack.com/services/xxx/yyy/zzz
BACKUP_ALERT_ON_SUCCESS=true
BACKUP_ALERT_ON_ERROR=true
```

### Конфигурация хранилища

#### Amazon S3

```bash
WALG_S3_PREFIX=s3://my-bucket/mysql-backups
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
AWS_REGION=us-east-1
```

#### Google Cloud Storage

```bash
WALG_GS_PREFIX=gs://my-bucket/mysql-backups
GOOGLE_APPLICATION_CREDENTIALS=/path/to/credentials.json
```

#### Microsoft Azure

```bash
WALG_AZ_PREFIX=azure://my-container/mysql-backups
AZURE_STORAGE_ACCOUNT=your-account
AZURE_STORAGE_KEY=your-key
```

#### Локальное хранилище

```bash
WALG_FILE_PREFIX=/path/to/backup/directory
```

## Создание резервных копий

### Полная резервная копия

```bash
./wall-be.sh mysql backup
```

### Проверка списка резервных копий

```bash
./wall-be.sh mysql list
```

### Проверка целостности резервной копии

```bash
./wall-be.sh mysql verify --name LATEST
```

## Восстановление из резервной копии

### Восстановление из последней резервной копии

```bash
./wall-be.sh mysql restore --name LATEST
```

### Восстановление из определенной резервной копии

```bash
./wall-be.sh mysql restore --name base_000000010000000000000001
```

### Восстановление на определенный момент времени (PITR)

```bash
./wall-be.sh mysql restore --time "2023-04-15 14:30:00"
```

## Планирование резервного копирования

### Настройка расписания через Cron

```bash
./wall-be.sh mysql schedule --schedule "0 0 * * *"
```

### Примеры расписания

- Ежедневно в полночь: `0 0 * * *`
- Каждые 6 часов: `0 */6 * * *`
- Каждый понедельник в 3:00: `0 3 * * 1`

## Работа с Docker

### Запуск MySQL с WAL-G в Docker

```bash
cd docker/mysql
docker-compose up -d
```

### Конфигурация Docker версии

Все настройки выполняются через переменные окружения в `docker-compose.yml`.

## Устранение неполадок

### Распространенные проблемы

1. **Ошибка подключения к MySQL**: Проверьте параметры подключения в конфигурационном файле.
2. **Ошибка доступа к хранилищу**: Проверьте конфигурацию хранилища и разрешения доступа.
3. **Ошибка создания резервной копии**: Убедитесь, что MySQL имеет разрешения на запись во временную директорию.

### Журналы

- Журналы WAL-G находятся в `/var/log/wal-g/`
- Журналы MySQL находятся в стандартной директории журналов MySQL

### Диагностика

Для диагностики проблем используйте команду:

```bash
./wall-be.sh mysql verify --verbose
``` 