#!/bin/bash

# Load utilities / Загрузка утилит
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

# Function to detect storage type based on prefix / Функция определения типа хранилища на основе префикса
detect_storage_type() {
    # Load configuration / Загрузка конфигурации
    load_config
    
    if [ -n "$WALG_S3_PREFIX" ]; then
        echo "s3"
    elif [ -n "$WALG_GS_PREFIX" ]; then
        echo "gs"
    elif [ -n "$WALG_AZ_PREFIX" ]; then
        echo "azure"
    elif [ -n "$WALG_FILE_PREFIX" ]; then
        echo "file"
    elif [ -n "$WALG_SWIFT_PREFIX" ]; then
        echo "swift"
    else
        log "ERROR" "Storage type not specified in configuration / Не указан тип хранилища в конфигурации"
        exit 1
    fi
}

# Function to check storage access / Функция проверки доступности хранилища
check_storage_access() {
    local storage_type=$(detect_storage_type)
    local success=false
    
    case "$storage_type" in
        "s3")
            if command -v aws &> /dev/null; then
                local bucket=$(echo "$WALG_S3_PREFIX" | cut -d'/' -f3)
                if aws s3 ls "s3://$bucket" &> /dev/null; then
                    success=true
                fi
            fi
            ;;
        "gs")
            if command -v gsutil &> /dev/null; then
                local bucket=$(echo "$WALG_GS_PREFIX" | cut -d'/' -f3)
                if gsutil ls "gs://$bucket" &> /dev/null; then
                    success=true
                fi
            fi
            ;;
        "azure")
            if command -v az &> /dev/null; then
                local container=$(echo "$WALG_AZ_PREFIX" | cut -d'/' -f3)
                if az storage container show --name "$container" &> /dev/null; then
                    success=true
                fi
            fi
            ;;
        "file")
            if [ -d "$WALG_FILE_PREFIX" ]; then
                success=true
            fi
            ;;
        "swift")
            if command -v swift &> /dev/null; then
                local container=$(echo "$WALG_SWIFT_PREFIX" | cut -d'/' -f3)
                if swift list "$container" &> /dev/null; then
                    success=true
                fi
            fi
            ;;
    esac
    
    if [ "$success" = "true" ]; then
        log "INFO" "Storage access confirmed / Доступ к хранилищу '$storage_type' подтвержден"
        return 0
    else
        log "ERROR" "No access to storage / Нет доступа к хранилищу '$storage_type'"
        return 1
    fi
}

# Function to create storage if it doesn't exist / Функция создания хранилища, если оно не существует
create_storage_if_not_exists() {
    local storage_type=$(detect_storage_type)
    
    case "$storage_type" in
        "s3")
            if command -v aws &> /dev/null; then
                local bucket=$(echo "$WALG_S3_PREFIX" | cut -d'/' -f3)
                if ! aws s3 ls "s3://$bucket" &> /dev/null; then
                    log "INFO" "Creating S3 bucket / Создание S3 бакета: $bucket"
                    aws s3 mb "s3://$bucket"
                fi
            fi
            ;;
        "gs")
            if command -v gsutil &> /dev/null; then
                local bucket=$(echo "$WALG_GS_PREFIX" | cut -d'/' -f3)
                if ! gsutil ls "gs://$bucket" &> /dev/null; then
                    log "INFO" "Creating GCS bucket / Создание GCS бакета: $bucket"
                    gsutil mb "gs://$bucket"
                fi
            fi
            ;;
        "azure")
            if command -v az &> /dev/null; then
                local container=$(echo "$WALG_AZ_PREFIX" | cut -d'/' -f3)
                if ! az storage container show --name "$container" &> /dev/null; then
                    log "INFO" "Creating Azure container / Создание Azure контейнера: $container"
                    az storage container create --name "$container"
                fi
            fi
            ;;
        "file")
            if [ ! -d "$WALG_FILE_PREFIX" ]; then
                log "INFO" "Creating directory / Создание директории: $WALG_FILE_PREFIX"
                mkdir -p "$WALG_FILE_PREFIX"
            fi
            ;;
        "swift")
            if command -v swift &> /dev/null; then
                local container=$(echo "$WALG_SWIFT_PREFIX" | cut -d'/' -f3)
                if ! swift list "$container" &> /dev/null; then
                    log "INFO" "Creating Swift container / Создание Swift контейнера: $container"
                    swift post "$container"
                fi
            fi
            ;;
    esac
}

# Function to calculate storage size / Функция расчета размера хранилища
calculate_storage_size() {
    local storage_type=$(detect_storage_type)
    local size=""
    
    case "$storage_type" in
        "s3")
            if command -v aws &> /dev/null; then
                local bucket=$(echo "$WALG_S3_PREFIX" | cut -d'/' -f3)
                local prefix=$(echo "$WALG_S3_PREFIX" | cut -d'/' -f4-)
                
                log "INFO" "Calculating S3 storage size / Расчет размера хранилища S3..."
                local output=$(aws s3 ls --recursive "s3://$bucket/$prefix" --summarize)
                size=$(echo "$output" | grep "Total Size" | awk '{print $3" "$4}')
            fi
            ;;
        "gs")
            if command -v gsutil &> /dev/null; then
                log "INFO" "Calculating GCS storage size / Расчет размера хранилища GCS..."
                local du_output=$(gsutil du -s "$WALG_GS_PREFIX")
                size=$(echo "$du_output" | awk '{printf "%.2f GB", $1/1024/1024/1024}')
            fi
            ;;
        "file")
            log "INFO" "Calculating local storage size / Расчет размера локального хранилища..."
            size=$(du -sh "$WALG_FILE_PREFIX" | awk '{print $1}')
            ;;
    esac
    
    if [ -n "$size" ]; then
        echo "$size"
    else
        echo "Unknown / Неизвестно"
    fi
}

# Function to get backup list from storage / Функция получения списка резервных копий из хранилища
list_backups_from_storage() {
    local storage_type=$(detect_storage_type)
    local database="$1"
    
    case "$database" in
        "mysql")
            if command -v wal-g &> /dev/null; then
                wal-g backup-list
            fi
            ;;
        "postgresql")
            if command -v wal-g-pg &> /dev/null; then
                wal-g-pg backup-list
            elif command -v wal-g &> /dev/null; then
                wal-g backup-list
            fi
            ;;
        *)
            log "ERROR" "Unsupported database type / Неподдерживаемый тип базы данных: $database"
            exit 1
            ;;
    esac
}

# Export functions / Экспорт функций
export -f detect_storage_type
export -f check_storage_access
export -f create_storage_if_not_exists
export -f calculate_storage_size
export -f list_backups_from_storage 