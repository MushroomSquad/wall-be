# Устранение неполадок

**Language / Язык**: [English](en/troubleshooting.md) | [Русский](troubleshooting.md)

Этот документ содержит решения распространенных проблем, с которыми вы можете столкнуться при использовании wall-be.

## Диагностика проблем

При устранении неполадок WAL-G следуйте этим общим шагам:

1. Проверьте журналы ошибок
   - Журналы WAL-G: `/var/log/wall-be/` или `./logs/`
   - Журналы MySQL: обычно в `/var/log/mysql/error.log`
   - Журналы PostgreSQL: обычно в `/var/log/postgresql/postgresql-*.log`

2. Запустите команду с флагом отладки
   ```bash
   ./wall-be.sh mysql backup --debug
   ```

3. Проверьте конфигурацию
   ```bash
   ./wall-be.sh mysql verify-config
   ```

## Распространенные проблемы

### Ошибки настройки

#### Не удается найти/загрузить WAL-G

**Симптомы:**
- Ошибка "WAL-G not found" или "No such file or directory"

**Решения:**
1. Убедитесь, что WAL-G установлен:
   ```bash
   which wal-g
   ```
2. Установите или загрузите WAL-G заново:
   ```bash
   ./wall-be.sh mysql setup
   ```

#### Ошибки конфигурации

**Симптомы:**
- Ошибка "Invalid or missing configuration" 
- Ошибка "Variable XYZ is not set"

**Решения:**
1. Проверьте свой файл конфигурации:
   ```bash
   cat config-mysql.env
   ```
2. Убедитесь, что все необходимые переменные установлены
3. Проверьте права доступа:
   ```bash
   chmod 600 config-mysql.env
   ```

### Ошибки создания резервных копий

#### Не удается подключиться к базе данных

**Симптомы:**
- Ошибка "Access denied for user"
- Ошибка "Connection refused"

**Решения:**
1. Проверьте учетные данные:
   ```bash
   mysql -u$WALG_MYSQL_USER -p$WALG_MYSQL_PASSWORD -h$WALG_MYSQL_HOST -P$WALG_MYSQL_PORT
   ```
2. Убедитесь, что MySQL работает:
   ```bash
   systemctl status mysql
   ```
3. Проверьте сетевые настройки, если база данных находится на другом сервере

#### Ошибки доступа к хранилищу

**Симптомы:**
- Ошибка "AccessDenied" или "NoSuchBucket"
- Ошибка "InvalidAccessKeyId"

**Решения:**
1. Для S3:
   - Проверьте переменные AWS_ACCESS_KEY_ID и AWS_SECRET_ACCESS_KEY
   - Убедитесь, что бакет существует и доступен
   - Проверьте права IAM

2. Для локального хранилища:
   - Проверьте, что путь существует:
     ```bash
     mkdir -p $(echo $WALG_FILE_PREFIX | cut -d: -f2)
     ```
   - Проверьте права доступа:
     ```bash
     chmod -R 755 $(echo $WALG_FILE_PREFIX | cut -d: -f2)
     ```

#### Ошибки XtraBackup

**Симптомы:**
- Ошибка "innobackupex failed with error code"
- Ошибка "xtrabackup: error"

**Решения:**
1. Убедитесь, что XtraBackup установлен:
   ```bash
   xtrabackup --version
   ```
2. Проверьте разрешения доступа к директории данных MySQL:
   ```bash
   ls -la /var/lib/mysql
   ```
3. Проверьте, достаточно ли свободного места на диске:
   ```bash
   df -h
   ```

### Ошибки восстановления

#### MySQL не запускается после восстановления

**Симптомы:**
- Ошибка "MySQL service failed to start"
- Ошибки в журнале MySQL после восстановления

**Решения:**
1. Проверьте журналы MySQL:
   ```bash
   tail -n 100 /var/log/mysql/error.log
   ```
2. Исправьте разрешения:
   ```bash
   chown -R mysql:mysql /var/lib/mysql
   ```
3. Проверьте совместимость версий:
   - Убедитесь, что восстановление выполняется на той же или совместимой версии MySQL

#### Неполное восстановление

**Симптомы:**
- Ошибка "Incomplete restore"
- Отсутствуют некоторые базы данных или таблицы

**Решения:**
1. Проверьте, была ли резервная копия полной:
   ```bash
   ./wall-be.sh mysql list
   ```
2. Проверьте место на диске:
   ```bash
   df -h
   ```
3. Проверьте права доступа к директории восстановления

### Ошибки PITR (Point-in-Time Recovery)

**Симптомы:**
- Ошибка "Binary log not found"
- Ошибка при воспроизведении бинарных логов

**Решения:**
1. Убедитесь, что бинарное логирование включено:
   ```bash
   mysql -e "SHOW VARIABLES LIKE 'log_bin';"
   ```
2. Проверьте, что архивированы все необходимые двоичные логи:
   ```bash
   ./wall-be.sh mysql wal-fetch --timeline --since LATEST
   ```
3. Проверьте формат временной метки (должен быть "YYYY-MM-DD HH:MM:SS")

### Ошибки планирования

**Симптомы:**
- Запланированные резервные копии не выполняются
- Ошибки cron в журнале

**Решения:**
1. Проверьте настройки cron:
   ```bash
   crontab -l
   ```
2. Проверьте журналы cron:
   ```bash
   grep CRON /var/log/syslog
   ```
3. Убедитесь, что скрипт имеет права на исполнение:
   ```bash
   chmod +x wall-be.sh
   ```

## Специфичные проблемы баз данных

### MySQL

#### Ошибки бинарного логирования

**Симптомы:**
- Ошибка "Binary logging not enabled"
- Невозможность выполнить PITR

**Решения:**
1. Включите бинарное логирование в MySQL:
   ```bash
   echo -e "[mysqld]\nlog_bin = mysql-bin\nserver_id = 1" >> /etc/mysql/my.cnf
   systemctl restart mysql
   ```
2. Проверьте статус бинарного логирования:
   ```bash
   mysql -e "SHOW MASTER STATUS;"
   ```

#### Проблемы с правами доступа

**Симптомы:**
- Ошибка "Access denied" при резервном копировании
- Ошибка "Permission denied" при чтении/записи файлов данных

**Решения:**
1. Убедитесь, что пользователь MySQL имеет необходимые права:
   ```bash
   mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'backup'@'localhost' IDENTIFIED BY 'password' WITH GRANT OPTION;"
   mysql -e "FLUSH PRIVILEGES;"
   ```
2. Проверьте права доступа к файловой системе:
   ```bash
   chmod -R 750 /var/lib/mysql
   chown -R mysql:mysql /var/lib/mysql
   ```

### PostgreSQL

#### Ошибки архивирования WAL

**Симптомы:**
- Ошибка "WAL archiving failed"
- Предупреждение "pg_wal directory not accessible"

**Решения:**
1. Проверьте настройки PostgreSQL:
   ```bash
   grep "archive_mode\|archive_command\|wal_level" /etc/postgresql/*/main/postgresql.conf
   ```
2. Убедитесь, что режим архивирования включен:
   ```sql
   ALTER SYSTEM SET archive_mode = on;
   ALTER SYSTEM SET wal_level = 'replica';
   ALTER SYSTEM SET archive_command = 'wal-g wal-push "%p"';
   ```
3. Перезапустите PostgreSQL:
   ```bash
   systemctl restart postgresql
   ```

#### Ошибки доступа к директории данных

**Симптомы:**
- Ошибка "Permission denied" при чтении/записи в директорию PGDATA
- Ошибка "cannot access directory" во время восстановления

**Решения:**
1. Установите правильные права доступа:
   ```bash
   chown -R postgres:postgres /var/lib/postgresql/data
   chmod -R 700 /var/lib/postgresql/data
   ```
2. Убедитесь, что системный пользователь имеет доступ:
   ```bash
   sudo -u postgres touch /var/lib/postgresql/data/test_file
   ```

## Сбор информации для поддержки

Если вы не можете решить проблему самостоятельно, соберите следующую информацию для обращения в поддержку:

1. Выходные данные с отладочной информацией:
   ```bash
   ./wall-be.sh mysql backup --debug > debug_output.log 2>&1
   ```

2. Версии компонентов:
   ```bash
   wal-g --version
   mysql --version
   xtrabackup --version
   ```

3. Конфигурация (с удаленными чувствительными данными):
   ```bash
   grep -v "PASSWORD\|SECRET\|KEY" config-mysql.env
   ```

4. Журналы ошибок:
   ```bash
   tail -n 500 /var/log/wall-be/latest.log
   ```

## Полезные команды для диагностики

```bash
# Проверить подключение к MySQL
mysql -u$WALG_MYSQL_USER -p$WALG_MYSQL_PASSWORD -h$WALG_MYSQL_HOST -P$WALG_MYSQL_PORT -e "SELECT 1;"

# Проверить доступ к S3
aws s3 ls $WALG_S3_PREFIX

# Проверить свободное место
df -h

# Проверить права доступа к директории данных
ls -la /var/lib/mysql

# Проверить статус сервисов
systemctl status mysql
systemctl status postgresql

# Проверить открытые порты
netstat -tuln | grep 3306  # для MySQL
netstat -tuln | grep 5432  # для PostgreSQL
``` 