#!/bin/bash
set -e

# Load common utilities / Загрузка общих утилит
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common/utils.sh"
source "$SCRIPT_DIR/../common/storage.sh"

# Source configuration
if [ -f "config-pg.env" ]; then
    source config-pg.env
fi

# Функция для вывода справки
show_help() {
    echo "Использование: $0 [опции]"
    echo ""
    echo "Опции:"
    echo "  --schedule <cron_expression>   Выражение в формате cron (по умолчанию: 0 0 * * *)"
    echo "  --user <username>              Пользователь, от имени которого будет запускаться cron задание (по умолчанию: текущий пользователь)"
    echo "  --type <full|incremental>      Тип бэкапа (по умолчанию: full)"
    echo "  --help                         Вывод этой справки"
    echo ""
    echo "Примеры:"
    echo "  $0 --schedule \"0 0 * * *\"      Полный бэкап каждый день в полночь"
    echo "  $0 --schedule \"0 */6 * * *\" --type incremental   Инкрементальный бэкап каждые 6 часов"
    echo ""
}

# Загрузка конфигурации
load_config

# Обработка аргументов
CRON_SCHEDULE="0 0 * * *"
BACKUP_TYPE="full"
CRON_USER="$USER"

while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --schedule)
            CRON_SCHEDULE="$2"
            shift 2
            ;;
        --user)
            CRON_USER="$2"
            shift 2
            ;;
        --type)
            BACKUP_TYPE="$2"
            if [[ "$BACKUP_TYPE" != "full" && "$BACKUP_TYPE" != "incremental" ]]; then
                log "ERROR" "Недопустимый тип бэкапа: $BACKUP_TYPE. Допустимые значения: full, incremental"
                exit 1
            fi
            shift 2
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            log "ERROR" "Неизвестная опция: $1"
            show_help
            exit 1
            ;;
    esac
done

log "INFO" "Настройка расписания резервного копирования PostgreSQL..."

# Проверка установки WAL-G
check_walg_installed "wal-g-pg"

# Определение команды wal-g
WALG_CMD="wal-g-pg"
if ! command -v "$WALG_CMD" &> /dev/null; then
    WALG_CMD="wal-g"
fi

# Создание директории для скриптов
BACKUP_SCRIPTS_DIR="/etc/wall-be/postgresql"
check_directory "$BACKUP_SCRIPTS_DIR" "true"

# Создание скрипта для запуска бэкапа
BACKUP_SCRIPT="$BACKUP_SCRIPTS_DIR/backup.sh"
cat > "$BACKUP_SCRIPT" << EOF
#!/bin/bash
# Автоматически созданный скрипт резервного копирования PostgreSQL

# Загрузка переменных окружения
$(grep -E '^[A-Za-z0-9_]+=.+$' "$WALL_BE_CONFIG_FILE")

# Запуск резервного копирования
$WALG_CMD backup-push \$PGDATA

# Проверка результата
if [ \$? -eq 0 ]; then
    echo "Резервное копирование PostgreSQL успешно выполнено: \$(date)"
else
    echo "Ошибка при создании резервной копии PostgreSQL: \$(date)"
    exit 1
fi
EOF

chmod +x "$BACKUP_SCRIPT"
log "INFO" "Создан скрипт резервного копирования: $BACKUP_SCRIPT"

# Создание cron задания
CRON_JOB="$CRON_SCHEDULE $CRON_USER $BACKUP_SCRIPT > /var/log/postgresql-backup.log 2>&1"
CRON_FILE="/etc/cron.d/wall-be-postgresql-backup"

echo "$CRON_JOB" > "$CRON_FILE"
chmod 0644 "$CRON_FILE"

log "SUCCESS" "Расписание резервного копирования PostgreSQL настроено:"
log "INFO" "Расписание: $CRON_SCHEDULE"
log "INFO" "Пользователь: $CRON_USER"
log "INFO" "Тип бэкапа: $BACKUP_TYPE"
log "INFO" "Cron файл: $CRON_FILE"
log "INFO" "Лог-файл: /var/log/postgresql-backup.log" 