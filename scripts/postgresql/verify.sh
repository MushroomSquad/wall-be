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
    echo "  --name <backup_name>   Имя бэкапа для проверки (по умолчанию: LATEST)"
    echo "  --help                 Вывод этой справки"
    echo ""
}

# Загрузка конфигурации
load_config

# Проверка установки WAL-G
check_walg_installed "wal-g-pg"

# Обработка аргументов
BACKUP_NAME="LATEST"

while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --name)
            BACKUP_NAME="$2"
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

log "INFO" "Проверка целостности резервной копии PostgreSQL: $BACKUP_NAME"

# Проверка доступа к хранилищу
check_storage_access

# Определение команды wal-g
WALG_CMD="wal-g-pg"
if ! command -v "$WALG_CMD" &> /dev/null; then
    WALG_CMD="wal-g"
fi

# Создание временной директории для проверки
TEMP_DIR=$(mktemp -d)
log "INFO" "Создана временная директория для проверки: $TEMP_DIR"

# Запуск проверки
log "INFO" "Запуск проверки резервной копии..."
set +e
if [ "$BACKUP_NAME" = "LATEST" ]; then
    $WALG_CMD backup-fetch "$TEMP_DIR" LATEST --verify
else
    $WALG_CMD backup-fetch "$TEMP_DIR" "$BACKUP_NAME" --verify
fi
VERIFY_RESULT=$?
set -e

# Удаление временной директории
log "INFO" "Удаление временной директории..."
rm -rf "$TEMP_DIR"

# Проверка результата
if [ $VERIFY_RESULT -eq 0 ]; then
    log "SUCCESS" "Резервная копия PostgreSQL '$BACKUP_NAME' успешно прошла проверку"
else
    log "ERROR" "Резервная копия PostgreSQL '$BACKUP_NAME' не прошла проверку"
    exit 1
fi 