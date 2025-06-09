# Руководство по конфигурации

**Language / Язык**: [English](en/configuration.md) | [Русский](configuration.md)

Этот документ описывает, как настроить wall-be для различных баз данных и вариантов хранения.

## Файл конфигурации

wall-be использует файлы окружения (`.env`) для конфигурации. Эти файлы определяют переменные окружения, которые управляют поведением WAL-G и процессом резервного копирования.

### Расположение файла конфигурации

Когда вы запускаете `./wall-be.sh <database> setup`, скрипт создает файл конфигурации по умолчанию в текущей директории:

- Для MySQL: `config-mysql.env`
- Для PostgreSQL: `config-postgresql.env`

Вы также можете указать пользовательский файл конфигурации, используя параметр `--config`:

```bash
./wall-be.sh mysql backup --config /path/to/my/config.env
```

## Общие параметры конфигурации

### Конфигурация хранилища

wall-be поддерживает несколько вариантов хранения для резервных копий:

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

#### Локальная файловая система

```bash
WALG_FILE_PREFIX=/path/to/backup/directory
```

### Настройки сжатия

```bash
# Доступные методы: lz4, brotli, pgzip, none
WALG_COMPRESSION_METHOD=lz4

# Уровень сжатия (1-9)
WALG_COMPRESSION_LEVEL=3
```

### Политика хранения

Политики хранения определяют, как долго сохраняются резервные копии:

```bash
# Количество полных резервных копий для хранения
WALG_RETENTION_FULL_BACKUPS=7

# Хранить резервные копии в течение этого количества дней
WALG_RETENTION_DAYS=30

# Максимальное количество резервных копий для хранения
WALG_RETENTION_COUNT=10
```

### Настройка производительности

```bash
# Количество параллельных загрузчиков
WALG_UPLOAD_CONCURRENCY=16

# Количество параллельных загрузчиков при скачивании
WALG_DOWNLOAD_CONCURRENCY=10

# Параллельность операций ввода-вывода на диске
WALG_UPLOAD_DISK_CONCURRENCY=2
```

### Настройки уведомлений

Настройте уведомления для операций резервного копирования:

```bash
# Уведомления по электронной почте
BACKUP_ALERT_EMAIL=admin@example.com

# Webhook Slack для уведомлений
BACKUP_SLACK_WEBHOOK=https://hooks.slack.com/services/xxx/yyy/zzz

# Когда отправлять уведомления
BACKUP_ALERT_ON_SUCCESS=true
BACKUP_ALERT_ON_ERROR=true
```

## Специфичные для баз данных конфигурации

### Конфигурация MySQL

```bash
# Подключение к базе данных
WALG_MYSQL_HOST=localhost
WALG_MYSQL_USER=root
WALG_MYSQL_PASSWORD=password
WALG_MYSQL_PORT=3306

# Путь к директории данных MySQL
WALG_MYSQL_DATADIR=/var/lib/mysql
```

### Конфигурация PostgreSQL

```bash
# Подключение к базе данных
PGHOST=localhost
PGUSER=postgres
PGPASSWORD=postgres
PGPORT=5432
PGDATABASE=postgres

# Путь к директории данных PostgreSQL
PGDATA=/var/lib/postgresql/data

# Настройки WAL
WALG_PG_WAL_SIZE=16777216
```

## Расширенная конфигурация

Для более сложных параметров конфигурации, пожалуйста, обратитесь к документации для конкретной базы данных:

- [Расширенная конфигурация MySQL](databases/mysql.md)
- [Расширенная конфигурация PostgreSQL](databases/postgresql.md) 