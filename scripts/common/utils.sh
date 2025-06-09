#!/bin/bash

# Загрузка файла с переводами
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/i18n.sh"

# Colors for output / Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color / Без цвета

# Logging function / Функция для логирования
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    
    case "$level" in
        "INFO")
            echo -e "${BLUE}[$(t info)]${NC} $timestamp - $message"
            ;;
        "SUCCESS")
            echo -e "${GREEN}[$(t success)]${NC} $timestamp - $message"
            ;;
        "WARNING")
            echo -e "${YELLOW}[$(t warning)]${NC} $timestamp - $message"
            ;;
        "ERROR")
            echo -e "${RED}[$(t error)]${NC} $timestamp - $message"
            ;;
        *)
            echo -e "$timestamp - $message"
            ;;
    esac
}

# Function to check if script is run as root / Функция для проверки, запущен ли скрипт от имени root
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        log "ERROR" "$(t root_required)"
        exit 1
    fi
}

# Function to load configuration file / Функция для загрузки конфигурационного файла
load_config() {
    local config_file="${WALL_BE_CONFIG_FILE}"
    
    if [ -z "$config_file" ]; then
        log "ERROR" "$(t config_not_specified)"
        exit 1
    fi
    
    if [ ! -f "$config_file" ]; then
        log "ERROR" "$(t config_not_found): '$config_file'"
        exit 1
    fi
    
    log "INFO" "$(t config_loaded) '$config_file'"
    source "$config_file"
}

# Function to send notifications / Функция для отправки уведомлений
send_notification() {
    local status="$1"
    local message="$2"
    local subject="$3"
    
    if [ "$BACKUP_ALERT_ON_SUCCESS" = "true" ] && [ "$status" = "SUCCESS" ]; then
        # Send email / Отправка email
        if [ -n "$BACKUP_ALERT_EMAIL" ]; then
            echo "$message" | mail -s "$subject" "$BACKUP_ALERT_EMAIL"
        fi
        
        # Send to Slack / Отправка в Slack
        if [ -n "$BACKUP_SLACK_WEBHOOK" ]; then
            curl -s -X POST -H 'Content-type: application/json' \
                --data "{\"text\":\"$subject: $message\"}" \
                "$BACKUP_SLACK_WEBHOOK"
        fi
    elif [ "$BACKUP_ALERT_ON_ERROR" = "true" ] && [ "$status" = "FAILED" ]; then
        # Send email / Отправка email
        if [ -n "$BACKUP_ALERT_EMAIL" ]; then
            echo "$message" | mail -s "$subject" "$BACKUP_ALERT_EMAIL"
        fi
        
        # Send to Slack / Отправка в Slack
        if [ -n "$BACKUP_SLACK_WEBHOOK" ]; then
            curl -s -X POST -H 'Content-type: application/json' \
                --data "{\"text\":\"$subject: $message\"}" \
                "$BACKUP_SLACK_WEBHOOK"
        fi
    fi
}

# Function to check if WAL-G is installed / Функция для проверки, установлен ли WAL-G
check_walg_installed() {
    local walg_cmd="${1:-wal-g}"
    
    if ! command -v "$walg_cmd" &> /dev/null; then
        log "ERROR" "WAL-G $(t not_found). $(t setup_failed)."
        exit 1
    fi
}

# Function to create backup name / Функция для создания имени бэкапа
create_backup_name() {
    local backup_type="$1"
    local timestamp=$(date +%Y%m%d%H%M%S)
    local hostname=$(hostname -s)
    echo "${backup_type}_${hostname}_${timestamp}"
}

# Function to format duration / Функция для форматирования времени выполнения
format_duration() {
    local seconds="$1"
    local hours=$((seconds / 3600))
    local minutes=$(( (seconds % 3600) / 60 ))
    local secs=$((seconds % 60))
    
    if [ $hours -gt 0 ]; then
        printf "%02d:%02d:%02d" $hours $minutes $secs
    else
        printf "%02d:%02d" $minutes $secs
    fi
}

# Function to check dependencies / Функция для загрузки и проверки зависимостей
check_dependencies() {
    local deps=("$@")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -ne 0 ]; then
        log "ERROR" "$(t missing_deps): ${missing[*]}"
        exit 1
    fi
}

# Function to check directory existence / Функция для проверки наличия директории
check_directory() {
    local dir="$1"
    local create="${2:-false}"
    
    if [ ! -d "$dir" ]; then
        if [ "$create" = "true" ]; then
            log "INFO" "$(t creating_directory): $dir"
            mkdir -p "$dir"
        else
            log "ERROR" "$(t dir_not_exists): '$dir'"
            exit 1
        fi
    fi
}

# Function to check file existence / Функция для проверки наличия файла
check_file() {
    local file="$1"
    
    if [ ! -f "$file" ]; then
        log "ERROR" "$(t file_not_exists): '$file'"
        exit 1
    fi
}

# Function to request user confirmation / Функция для запроса подтверждения от пользователя
confirm_action() {
    local message="$1"
    local default="${2:-n}"
    
    local prompt
    if [ "$default" = "y" ]; then
        prompt="[$(t yes)/$(t no)]"
    else
        prompt="[$(t yes)/$(t no)]"
    fi
    
    echo -e "${YELLOW}$message${NC} $prompt"
    read -r response
    
    case "$response" in
        [yY][eE][sS]|[yY])
            return 0
            ;;
        [nN][oO]|[nN])
            return 1
            ;;
        "")
            if [ "$default" = "y" ]; then
                return 0
            else
                return 1
            fi
            ;;
        *)
            return 1
            ;;
    esac
}

# Добавляем перевод для создания директории
TRANSLATIONS_EN["creating_directory"]="Creating directory"
TRANSLATIONS_RU["creating_directory"]="Создание директории"

# Export functions / Экспорт функций
export -f log
export -f check_root
export -f load_config
export -f send_notification
export -f check_walg_installed
export -f create_backup_name
export -f format_duration
export -f check_dependencies
export -f check_directory
export -f check_file
export -f confirm_action
export -f t
export -f translate 