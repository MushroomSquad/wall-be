#!/bin/bash
set -e

# Проверка наличия переменных окружения для WAL-G
if [ -n "$WALG_S3_PREFIX" ] || [ -n "$WALG_GS_PREFIX" ] || [ -n "$WALG_AZ_PREFIX" ] || [ -n "$WALG_FILE_PREFIX" ]; then
    echo "Обнаружена конфигурация WAL-G, настройка резервного копирования..."
    
    # Экспорт переменных окружения для WAL-G
    export PGHOST=${PGHOST:-localhost}
    export PGUSER=${PGUSER:-postgres}
    export PGPASSWORD=${PGPASSWORD:-$POSTGRES_PASSWORD}
    export PGPORT=${PGPORT:-5432}
    export PGDATABASE=${PGDATABASE:-postgres}
    export WALG_COMPRESSION_METHOD=${WALG_COMPRESSION_METHOD:-lz4}
    
    # Настройка PostgreSQL для архивирования WAL
    if [ -f "$PGDATA/postgresql.conf" ]; then
        # Настройка архивирования WAL
        echo "Настройка архивирования WAL..."
        cat >> "$PGDATA/postgresql.conf" << EOF
wal_level = replica
archive_mode = on
archive_command = 'wal-g wal-push "%p"'
archive_timeout = 60
EOF
    fi
    
    # Настройка cron для автоматического резервного копирования, если указан BACKUP_SCHEDULE
    if [ -n "$BACKUP_SCHEDULE" ]; then
        echo "Настройка расписания резервного копирования: $BACKUP_SCHEDULE"
        
        # Установка cron
        apt-get update && apt-get install -y cron
        
        # Создание скрипта для резервного копирования
        cat > /usr/local/bin/create_backup.sh << 'EOF'
#!/bin/bash
# Скрипт для создания резервной копии PostgreSQL через WAL-G
wal-g-pg backup-push $PGDATA
EOF
        chmod +x /usr/local/bin/create_backup.sh
        
        # Настройка задания cron
        echo "$BACKUP_SCHEDULE root /usr/local/bin/create_backup.sh > /proc/1/fd/1 2>&1" > /etc/cron.d/postgresql-backup
        chmod 0644 /etc/cron.d/postgresql-backup
        
        # Запуск cron
        service cron start
    fi
    
    # Восстановление из резервной копии при запуске, если указан RESTORE_FROM_BACKUP и директория PGDATA пуста
    if [ -n "$RESTORE_FROM_BACKUP" ] && [ -z "$(ls -A "$PGDATA" 2>/dev/null)" ]; then
        echo "Восстановление из резервной копии: $RESTORE_FROM_BACKUP"
        
        # Восстановление
        if [ "$RESTORE_FROM_BACKUP" = "LATEST" ]; then
            wal-g-pg backup-fetch "$PGDATA" LATEST
        else
            wal-g-pg backup-fetch "$PGDATA" "$RESTORE_FROM_BACKUP"
        fi
        
        # Создание файла recovery.signal для PostgreSQL 12+
        touch "$PGDATA/recovery.signal"
        
        # Настройка для восстановления WAL
        cat >> "$PGDATA/postgresql.conf" << EOF
restore_command = 'wal-g wal-fetch "%f" "%p"'
recovery_target_timeline = 'latest'
EOF
    fi
fi

# Запуск оригинального entrypoint
exec docker-entrypoint.sh "$@" 