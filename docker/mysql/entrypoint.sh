#!/bin/bash
set -e

# Проверка наличия переменных окружения для WAL-G
if [ -n "$WALG_S3_PREFIX" ] || [ -n "$WALG_GS_PREFIX" ] || [ -n "$WALG_AZ_PREFIX" ] || [ -n "$WALG_FILE_PREFIX" ]; then
    echo "Обнаружена конфигурация WAL-G, настройка резервного копирования..."
    
    # Экспорт переменных окружения для WAL-G
    export WALG_MYSQL_HOST=${MYSQL_HOST:-localhost}
    export WALG_MYSQL_USER=${MYSQL_USER:-root}
    export WALG_MYSQL_PASSWORD=${MYSQL_PASSWORD:-$MYSQL_ROOT_PASSWORD}
    export WALG_MYSQL_PORT=${MYSQL_PORT:-3306}
    export WALG_COMPRESSION_METHOD=${WALG_COMPRESSION_METHOD:-lz4}
    
    # Настройка cron для автоматического резервного копирования, если указан BACKUP_SCHEDULE
    if [ -n "$BACKUP_SCHEDULE" ]; then
        echo "Настройка расписания резервного копирования: $BACKUP_SCHEDULE"
        
        # Установка cron
        apt-get update && apt-get install -y cron
        
        # Создание скрипта для резервного копирования
        cat > /usr/local/bin/create_backup.sh << 'EOF'
#!/bin/bash
# Скрипт для создания резервной копии MySQL через WAL-G
wal-g backup-push
EOF
        chmod +x /usr/local/bin/create_backup.sh
        
        # Настройка задания cron
        echo "$BACKUP_SCHEDULE root /usr/local/bin/create_backup.sh > /proc/1/fd/1 2>&1" > /etc/cron.d/mysql-backup
        chmod 0644 /etc/cron.d/mysql-backup
        
        # Запуск cron
        service cron start
    fi
    
    # Восстановление из резервной копии при запуске, если указан RESTORE_FROM_BACKUP
    if [ -n "$RESTORE_FROM_BACKUP" ]; then
        echo "Восстановление из резервной копии: $RESTORE_FROM_BACKUP"
        
        # Дожидаемся запуска MySQL
        echo "Ожидание запуска MySQL..."
        timeout=60
        while [ $timeout -gt 0 ]; do
            if mysqladmin ping -h"$WALG_MYSQL_HOST" -u"$WALG_MYSQL_USER" -p"$WALG_MYSQL_PASSWORD" &> /dev/null; then
                break
            fi
            timeout=$((timeout-1))
            sleep 1
        done
        
        if [ $timeout -eq 0 ]; then
            echo "Ошибка: MySQL не запустился в течение отведенного времени"
            exit 1
        fi
        
        # Восстановление
        if [ "$RESTORE_FROM_BACKUP" = "LATEST" ]; then
            wal-g backup-fetch
        else
            wal-g backup-fetch "$RESTORE_FROM_BACKUP"
        fi
    fi
fi

# Запуск оригинального entrypoint
exec docker-entrypoint.sh "$@" 