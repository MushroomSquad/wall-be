#!/bin/bash
set -e

# Определяем директории
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/config"
SCRIPTS_DIR="$SCRIPT_DIR/scripts"

# Загрузка файла с переводами
source "$SCRIPTS_DIR/common/i18n.sh"

# Colors for output / Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color / Без цвета

# Version / Версия
VERSION="1.0.0"

# Global variables / Глобальные переменные
DATABASE=""
ACTION=""
SUB_ACTION=""
CONFIG_FILE=""

# Help function / Функция вывода помощи
show_help() {
    echo -e "${CYAN}wall-be${NC} - $(t database_backup_tool)"
    echo ""
    echo -e "${YELLOW}$(t usage):${NC}"
    echo "  ./wall-be.sh <database> <action> [options]"
    echo ""
    echo -e "${YELLOW}$(t supported_databases):${NC}"
    echo "  mysql       - MySQL/MariaDB"
    echo "  postgresql  - PostgreSQL"
    echo ""
    echo -e "${YELLOW}$(t actions):${NC}"
    echo "  setup       - $(t action_setup)"
    echo "  backup      - $(t action_backup)"
    echo "  restore     - $(t action_restore)"
    echo "  list        - $(t action_list)"
    echo "  verify      - $(t action_verify)"
    echo "  schedule    - $(t action_schedule)"
    echo ""
    echo -e "${YELLOW}$(t options):${NC}"
    echo "  --config <file>  - $(t option_config)"
    echo "  --help           - $(t option_help)"
    echo "  --version        - $(t option_version)"
    echo ""
    echo -e "${YELLOW}$(t examples):${NC}"
    echo "  ./wall-be.sh mysql setup"
    echo "  ./wall-be.sh postgresql backup --config /path/to/my/config.env"
    echo "  ./wall-be.sh mysql restore --name my_backup"
    echo ""
}

# Function to check dependencies / Функция для проверки зависимостей
check_dependencies() {
    local deps=("$@")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -ne 0 ]; then
        echo -e "${RED}$(t error): $(t missing_deps): ${missing[*]}${NC}"
        exit 1
    fi
}

# Function to check script existence / Функция для проверки наличия скрипта
check_script() {
    local script="$1"
    if [ ! -f "$script" ]; then
        echo -e "${RED}$(t error): $(t script_not_found) $script${NC}"
        exit 1
    fi
}

# Function to check database availability / Функция проверки доступности базы данных
check_database() {
    local db="$1"
    case "$db" in
        mysql|postgresql)
            return 0
            ;;
        *)
            echo -e "${RED}$(t error): $(t unsupported_db) '$db'${NC}"
            echo -e "$(t supported_databases): ${CYAN}mysql${NC}, ${CYAN}postgresql${NC}"
            exit 1
            ;;
    esac
}

# Function to check action availability / Функция проверки доступности действия
check_action() {
    local action="$1"
    case "$action" in
        setup|backup|restore|list|verify|schedule)
            return 0
            ;;
        *)
            echo -e "${RED}$(t error): $(t unsupported_action) '$action'${NC}"
            echo -e "$(t supported_actions): ${CYAN}setup${NC}, ${CYAN}backup${NC}, ${CYAN}restore${NC}, ${CYAN}list${NC}, ${CYAN}verify${NC}, ${CYAN}schedule${NC}"
            exit 1
            ;;
    esac
}

# Main function / Основная функция
main() {
    # Check basic dependencies / Проверка базовых зависимостей
    check_dependencies "bash" "grep" "sed"
    
    # Parse arguments / Парсинг аргументов
    if [ $# -lt 2 ]; then
        show_help
        exit 1
    fi
    
    DATABASE="$1"
    ACTION="$2"
    shift 2
    
    # Checks / Проверки
    check_database "$DATABASE"
    check_action "$ACTION"
    
    # Path to action script / Путь к скрипту действия
    ACTION_SCRIPT="$SCRIPTS_DIR/$DATABASE/$ACTION.sh"
    check_script "$ACTION_SCRIPT"
    
    # Process additional options / Обработка дополнительных опций
    while [ $# -gt 0 ]; do
        case "$1" in
            --config)
                CONFIG_FILE="$2"
                if [ ! -f "$CONFIG_FILE" ]; then
                    echo -e "${RED}$(t error): $(t config_not_found) '$CONFIG_FILE'${NC}"
                    exit 1
                fi
                shift 2
                ;;
            --help)
                show_help
                exit 0
                ;;
            --version)
                echo -e "${CYAN}wall-be${NC} $(t version) ${GREEN}$VERSION${NC}"
                exit 0
                ;;
            *)
                break
                ;;
        esac
    done
    
    # If config file not specified, use template / Если файл конфигурации не указан, используем шаблон
    if [ -z "$CONFIG_FILE" ]; then
        # Check for local config / Проверяем наличие локальной конфигурации
        LOCAL_CONFIG="./config-$DATABASE.env"
        if [ -f "$LOCAL_CONFIG" ]; then
            CONFIG_FILE="$LOCAL_CONFIG"
        else
            # Copy template to current directory / Копируем шаблон в текущую директорию
            TEMPLATE="$CONFIG_DIR/$DATABASE.env.template"
            CONFIG_FILE="./config-$DATABASE.env"
            cp "$TEMPLATE" "$CONFIG_FILE"
            echo -e "${YELLOW}$(t notice): $(t config_created) '$CONFIG_FILE' $(t from_template).${NC}"
            echo -e "${YELLOW}$(t edit_config_warning)${NC}"
            exit 0
        fi
    fi
    
    # Export config path for scripts / Экспортируем путь к конфигурации для скриптов
    export WALL_BE_CONFIG_FILE="$CONFIG_FILE"
    
    # Run action script / Запуск скрипта действия
    echo -e "${GREEN}$(t executing): $DATABASE - $ACTION${NC}"
    echo -e "${BLUE}$(t using_config): $CONFIG_FILE${NC}"
    
    # Pass remaining arguments to action script / Передаем все оставшиеся аргументы в скрипт действия
    "$ACTION_SCRIPT" "$@"
}

# Добавляем новые переводы для wall-be.sh
TRANSLATIONS_EN["database_backup_tool"]="Database backup management tool using WAL-G"
TRANSLATIONS_RU["database_backup_tool"]="Инструмент для управления бэкапами баз данных через WAL-G"

TRANSLATIONS_EN["usage"]="Usage"
TRANSLATIONS_RU["usage"]="Использование"

TRANSLATIONS_EN["supported_databases"]="Supported databases"
TRANSLATIONS_RU["supported_databases"]="Поддерживаемые базы данных"

TRANSLATIONS_EN["actions"]="Actions"
TRANSLATIONS_RU["actions"]="Действия"

TRANSLATIONS_EN["action_setup"]="Set up WAL-G for database"
TRANSLATIONS_RU["action_setup"]="Настройка WAL-G для базы данных"

TRANSLATIONS_EN["action_backup"]="Create a backup"
TRANSLATIONS_RU["action_backup"]="Создание резервной копии"

TRANSLATIONS_EN["action_restore"]="Restore from backup"
TRANSLATIONS_RU["action_restore"]="Восстановление из резервной копии"

TRANSLATIONS_EN["action_list"]="List available backups"
TRANSLATIONS_RU["action_list"]="Список доступных резервных копий"

TRANSLATIONS_EN["action_verify"]="Verify backup integrity"
TRANSLATIONS_RU["action_verify"]="Проверка целостности резервной копии"

TRANSLATIONS_EN["action_schedule"]="Configure backup schedule"
TRANSLATIONS_RU["action_schedule"]="Настройка расписания резервного копирования"

TRANSLATIONS_EN["options"]="Options"
TRANSLATIONS_RU["options"]="Опции"

TRANSLATIONS_EN["option_config"]="Path to config file (if not specified, default config is used)"
TRANSLATIONS_RU["option_config"]="Путь к файлу конфигурации (если не указан, используется конфигурация по умолчанию)"

TRANSLATIONS_EN["option_help"]="Show this help"
TRANSLATIONS_RU["option_help"]="Показать эту справку"

TRANSLATIONS_EN["option_version"]="Show version"
TRANSLATIONS_RU["option_version"]="Показать версию"

TRANSLATIONS_EN["examples"]="Examples"
TRANSLATIONS_RU["examples"]="Примеры"

TRANSLATIONS_EN["script_not_found"]="Script not found"
TRANSLATIONS_RU["script_not_found"]="Скрипт не найден"

TRANSLATIONS_EN["supported_actions"]="Supported actions"
TRANSLATIONS_RU["supported_actions"]="Поддерживаемые действия"

TRANSLATIONS_EN["notice"]="Notice"
TRANSLATIONS_RU["notice"]="Внимание"

TRANSLATIONS_EN["from_template"]="from template"
TRANSLATIONS_RU["from_template"]="из шаблона"

TRANSLATIONS_EN["executing"]="Executing"
TRANSLATIONS_RU["executing"]="Выполнение"

TRANSLATIONS_EN["using_config"]="Using config"
TRANSLATIONS_RU["using_config"]="Используется конфигурация"

# Run main function / Запуск основной функции
main "$@" 