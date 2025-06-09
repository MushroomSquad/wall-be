# Начало работы

**Language / Язык**: [English](en/getting-started.md) | [Русский](getting-started.md)

## Введение

wall-be - это универсальный инструмент для управления резервными копиями различных баз данных с использованием [WAL-G](https://github.com/wal-g/wal-g). Это руководство поможет вам начать работу с базовой настройкой и операциями.

## Предварительные требования

Перед началом работы убедитесь, что у вас есть:

- Система Linux с оболочкой bash
- Доступ к одной из поддерживаемых баз данных (MySQL/MariaDB, PostgreSQL)
- Административные привилегии для операций с базой данных
- Учетная запись хранилища для резервных копий (S3, GCS, Azure) или локальное хранилище

## Установка

1. **Клонирование репозитория**:

```bash
git clone https://github.com/MushroomSquad/wall-be.git
cd wall-be
chmod +x wall-be.sh
```

2. **Настройка WAL-G для вашей базы данных**:

Для MySQL:
```bash
./wall-be.sh mysql setup
```

Для PostgreSQL:
```bash
./wall-be.sh postgresql setup
```

Это действие:
- Загрузит и установит WAL-G
- Создаст конфигурационный файл
- Настроит вашу базу данных для интеграции с WAL-G

3. **Редактирование конфигурационного файла**:

Скрипт настройки создает конфигурационный файл в текущем каталоге. Отредактируйте этот файл, чтобы указать данные подключения к базе данных и настройки хранилища:

```bash
nano config-mysql.env  # Для MySQL
# или
nano config-postgresql.env  # Для PostgreSQL
```

### Подробности ручной установки

Если вы предпочитаете установить WAL-G вручную:

1. **Установка зависимостей**

   Для Ubuntu/Debian:
   ```bash
   apt-get update
   apt-get install -y wget curl ca-certificates xtrabackup mysql-client
   ```

   Для CentOS/RHEL:
   ```bash
   yum install -y wget curl ca-certificates
   yum install -y https://repo.percona.com/yum/percona-release-latest.noarch.rpm
   yum install -y percona-xtrabackup-24 mysql
   ```

2. **Загрузка и установка WAL-G**

   ```bash
   # Определение последней версии
   LATEST_RELEASE=$(curl -s https://api.github.com/repos/wal-g/wal-g/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
   
   # Загрузка бинарного файла WAL-G
   wget "https://github.com/wal-g/wal-g/releases/download/${LATEST_RELEASE}/wal-g-mysql-${LATEST_RELEASE}-linux-amd64.tar.gz" -O /tmp/wal-g.tar.gz
   
   # Распаковка и установка
   tar -xzf /tmp/wal-g.tar.gz -C /tmp
   mv /tmp/wal-g-mysql /usr/local/bin/wal-g
   chmod +x /usr/local/bin/wal-g
   ```

3. **Создание пользователя для резервного копирования в MySQL**

   ```sql
   CREATE USER 'backup'@'localhost' IDENTIFIED BY 'your_password';
   GRANT RELOAD, LOCK TABLES, REPLICATION CLIENT, CREATE TABLESPACE, PROCESS, SUPER, CREATE, INSERT, SELECT ON *.* TO 'backup'@'localhost';
   FLUSH PRIVILEGES;
   ```

## Быстрый старт

### Создание резервной копии

```bash
./wall-be.sh mysql backup  # Для MySQL
# или
./wall-be.sh postgresql backup  # Для PostgreSQL
```

### Просмотр доступных резервных копий

```bash
./wall-be.sh mysql list  # Для MySQL
# или
./wall-be.sh postgresql list  # Для PostgreSQL
```

### Восстановление из резервной копии

```bash
./wall-be.sh mysql restore --name LATEST  # Для MySQL, восстановление из последней резервной копии
# или
./wall-be.sh postgresql restore --name LATEST  # Для PostgreSQL, восстановление из последней резервной копии
```

## Проверка установки

Чтобы проверить, что WAL-G правильно установлен и настроен:

1. Проверьте версию WAL-G:
   ```bash
   wal-g --version
   ```

2. Проверьте подключение к базе данных:
   ```bash
   source config-mysql.env
   mysql -e "SELECT 1" 
   ```

3. Проверьте список резервных копий (он, вероятно, будет пустым, если вы еще не создали резервные копии):
   ```bash
   source config-mysql.env
   wal-g backup-list
   ```

## Дальнейшие шаги

Теперь, когда у вас настроены основы, вы можете:

1. [Настроить политики хранения резервных копий](configuration.md)
2. [Настроить расписание резервного копирования](cron.md)
3. [Узнать об интеграции с Docker](docker.md)
4. [Изучить особенности конкретных баз данных](databases/mysql.md)

## Устранение неполадок

### Распространенные проблемы

1. **Команда WAL-G не найдена**
   - Убедитесь, что WAL-G правильно установлен в `/usr/local/bin/wal-g`
   - Проверьте, что файл имеет права на выполнение

2. **Невозможно подключиться к базе данных**
   - Проверьте ваши данные подключения в конфигурационном файле
   - Убедитесь, что пользователь имеет нужные разрешения

3. **Ошибки доступа к хранилищу**
   - Проверьте ваши учетные данные и разрешения для хранилища
   - Проверьте сетевое подключение к сервису хранения

Для более подробного устранения неполадок обратитесь к [Руководству по устранению неполадок](troubleshooting.md). 