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

# Загрузка конфигурации
load_config

# Проверка установки WAL-G
check_walg_installed "wal-g-pg"

log "INFO" "Получение списка резервных копий PostgreSQL..."

# Проверка доступа к хранилищу
check_storage_access

# Определение команды wal-g
WALG_CMD="wal-g-pg"
if ! command -v "$WALG_CMD" &> /dev/null; then
    WALG_CMD="wal-g"
fi

# Вывод списка бэкапов
echo -e "${BLUE}=== Список доступных резервных копий для PostgreSQL ===${NC}"
$WALG_CMD backup-list

# Вывод размера хранилища, если возможно
STORAGE_SIZE=$(calculate_storage_size)
echo -e "${BLUE}=== Информация о хранилище ===${NC}"
echo -e "Тип хранилища: $(detect_storage_type)"
echo -e "Размер хранилища: $STORAGE_SIZE"

log "SUCCESS" "Список резервных копий PostgreSQL получен"