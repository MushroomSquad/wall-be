#!/usr/bin/env bash

# Загрузка файла с переводами
source "$(dirname "$0")/i18n.sh"

# Установка цветов для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RESET='\033[0m'

# Переменные для тестирования
DEMO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$DEMO_DIR/.." && pwd)"
LOG_FILE="$DEMO_DIR/autotest.log"

# Очистка лог-файла перед запуском
> "$LOG_FILE"

# Функция логирования
log() {
    local message="$1"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] $message" | tee -a "$LOG_FILE"
}

# Функция для проверки успешности выполнения команды
check_status() {
    local status=$?
    local test_name="$1"
    
    if [ $status -eq 0 ]; then
        echo -e "${GREEN}✓ $test_name: $(t test_passed)${RESET}" | tee -a "$LOG_FILE"
        return 0
    else
        echo -e "${RED}✗ $test_name: $(t test_failed)${RESET}" | tee -a "$LOG_FILE"
        return 1
    fi
}

# Функция для запуска тестов MySQL
test_mysql() {
    log "$(t testing_mysql)"
    
    # Проверка наличия MySQL
    if ! command -v mysql &> /dev/null; then
        log "$(t mysql_not_installed)"
        return 1
    fi
    
    # Проверка подключения к MySQL
    if ! mysql -u root -proot -e "SELECT 1" &>/dev/null; then
        log "$(t mysql_connection_failed)"
        return 1
    fi
    
    # Тест: Создание тестовой базы данных
    log "$(t test_creating_database)"
    mysql -u root -proot -e "DROP DATABASE IF EXISTS wallbe_test; CREATE DATABASE wallbe_test; USE wallbe_test; CREATE TABLE test_data (id INT AUTO_INCREMENT PRIMARY KEY, data VARCHAR(255));" >> "$LOG_FILE" 2>&1
    check_status "$(t test_create_database)"
    
    # Тест: Добавление данных
    log "$(t test_adding_data)"
    mysql -u root -proot -e "USE wallbe_test; INSERT INTO test_data (data) VALUES ('Test data 1'), ('Test data 2');" >> "$LOG_FILE" 2>&1
    check_status "$(t test_insert_data)"
    
    # Тест: Создание резервной копии
    log "$(t test_creating_backup)"
    
    # Создание временного конфиг-файла для тестов
    cat > "$DEMO_DIR/test-mysql.env" << EOF
WALG_MYSQL_HOST=localhost
WALG_MYSQL_USER=root
WALG_MYSQL_PASSWORD=root
WALG_MYSQL_PORT=3306
WALG_FILE_PREFIX=file://$DEMO_DIR/backups/mysql-test
WALG_COMPRESSION_METHOD=lz4
WALG_RETENTION_FULL_BACKUPS=3
EOF
    
    "$PROJECT_DIR/wall-be.sh" mysql backup --config "$DEMO_DIR/test-mysql.env" >> "$LOG_FILE" 2>&1
    check_status "$(t test_backup)"
    
    # Тест: Просмотр резервных копий
    log "$(t test_listing_backups)"
    "$PROJECT_DIR/wall-be.sh" mysql list --config "$DEMO_DIR/test-mysql.env" >> "$LOG_FILE" 2>&1
    check_status "$(t test_list_backups)"
    
    # Тест: Изменение данных для последующего восстановления
    log "$(t test_modifying_data)"
    mysql -u root -proot -e "USE wallbe_test; TRUNCATE TABLE test_data; INSERT INTO test_data (data) VALUES ('Modified data');" >> "$LOG_FILE" 2>&1
    check_status "$(t test_modify_data)"
    
    # Тест: Восстановление из резервной копии
    log "$(t test_restoring_backup)"
    "$PROJECT_DIR/wall-be.sh" mysql restore --name LATEST --config "$DEMO_DIR/test-mysql.env" >> "$LOG_FILE" 2>&1
    check_status "$(t test_restore)"
    
    # Тест: Проверка восстановленных данных
    log "$(t test_verifying_data)"
    mysql -u root -proot -e "USE wallbe_test; SELECT COUNT(*) FROM test_data WHERE data IN ('Test data 1', 'Test data 2');" | grep -q "2" >> "$LOG_FILE" 2>&1
    check_status "$(t test_verify_data)"
    
    # Очистка после тестов
    log "$(t test_cleanup)"
    mysql -u root -proot -e "DROP DATABASE IF EXISTS wallbe_test;" >> "$LOG_FILE" 2>&1
    rm -f "$DEMO_DIR/test-mysql.env" >> "$LOG_FILE" 2>&1
    
    return 0
}

# Функция для запуска тестов PostgreSQL
test_postgresql() {
    log "$(t testing_postgresql)"
    
    # Проверка наличия PostgreSQL
    if ! command -v psql &> /dev/null; then
        log "$(t postgresql_not_installed)"
        return 1
    fi
    
    # Проверка подключения к PostgreSQL
    if ! PGPASSWORD=postgres psql -U postgres -h localhost -c "SELECT 1" &>/dev/null; then
        log "$(t postgresql_connection_failed)"
        return 1
    fi
    
    # Тест: Создание тестовой базы данных
    log "$(t test_creating_database)"
    PGPASSWORD=postgres psql -U postgres -h localhost -c "DROP DATABASE IF EXISTS wallbe_test;" >> "$LOG_FILE" 2>&1
    PGPASSWORD=postgres psql -U postgres -h localhost -c "CREATE DATABASE wallbe_test;" >> "$LOG_FILE" 2>&1
    PGPASSWORD=postgres psql -U postgres -h localhost -d wallbe_test -c "CREATE TABLE test_data (id SERIAL PRIMARY KEY, data VARCHAR(255));" >> "$LOG_FILE" 2>&1
    check_status "$(t test_create_database)"
    
    # Тест: Добавление данных
    log "$(t test_adding_data)"
    PGPASSWORD=postgres psql -U postgres -h localhost -d wallbe_test -c "INSERT INTO test_data (data) VALUES ('PG Test data 1'), ('PG Test data 2');" >> "$LOG_FILE" 2>&1
    check_status "$(t test_insert_data)"
    
    # Тест: Создание резервной копии
    log "$(t test_creating_backup)"
    
    # Создание временного конфиг-файла для тестов
    cat > "$DEMO_DIR/test-postgres.env" << EOF
PGHOST=localhost
PGUSER=postgres
PGPASSWORD=postgres
PGPORT=5432
PGDATABASE=wallbe_test
WALG_FILE_PREFIX=file://$DEMO_DIR/backups/postgres-test
WALG_COMPRESSION_METHOD=lz4
WALG_RETENTION_FULL_BACKUPS=3
EOF
    
    "$PROJECT_DIR/wall-be.sh" postgresql backup --config "$DEMO_DIR/test-postgres.env" >> "$LOG_FILE" 2>&1
    check_status "$(t test_backup)"
    
    # Тест: Просмотр резервных копий
    log "$(t test_listing_backups)"
    "$PROJECT_DIR/wall-be.sh" postgresql list --config "$DEMO_DIR/test-postgres.env" >> "$LOG_FILE" 2>&1
    check_status "$(t test_list_backups)"
    
    # Тест: Изменение данных для последующего восстановления
    log "$(t test_modifying_data)"
    PGPASSWORD=postgres psql -U postgres -h localhost -d wallbe_test -c "TRUNCATE TABLE test_data; INSERT INTO test_data (data) VALUES ('Modified PG data');" >> "$LOG_FILE" 2>&1
    check_status "$(t test_modify_data)"
    
    # Тест: Восстановление из резервной копии
    log "$(t test_restoring_backup)"
    "$PROJECT_DIR/wall-be.sh" postgresql restore --name LATEST --config "$DEMO_DIR/test-postgres.env" >> "$LOG_FILE" 2>&1
    check_status "$(t test_restore)"
    
    # Тест: Проверка восстановленных данных
    log "$(t test_verifying_data)"
    PGPASSWORD=postgres psql -U postgres -h localhost -d wallbe_test -c "SELECT COUNT(*) FROM test_data WHERE data IN ('PG Test data 1', 'PG Test data 2');" | grep -q "2" >> "$LOG_FILE" 2>&1
    check_status "$(t test_verify_data)"
    
    # Очистка после тестов
    log "$(t test_cleanup)"
    PGPASSWORD=postgres psql -U postgres -h localhost -c "DROP DATABASE IF EXISTS wallbe_test;" >> "$LOG_FILE" 2>&1
    rm -f "$DEMO_DIR/test-postgres.env" >> "$LOG_FILE" 2>&1
    
    return 0
}

# Главная функция для запуска автотестов
run_autotests() {
    clear
    echo -e "\e[1m$(t autotest_title)\e[0m"
    echo "========================================"
    echo ""
    
    log "$(t running_autotest)"
    log "$(t log_file): $LOG_FILE"
    echo ""
    
    # Создаем директорию для бэкапов
    mkdir -p "$DEMO_DIR/backups/mysql-test" "$DEMO_DIR/backups/postgres-test"
    
    # Запуск тестов MySQL
    test_mysql
    mysql_status=$?
    
    echo ""
    
    # Запуск тестов PostgreSQL
    test_postgresql
    pg_status=$?
    
    echo ""
    log "$(t finishing_tests)"
    
    # Подведение итогов
    echo ""
    echo "========================================"
    echo "$(t tests_complete)"
    
    if [ $mysql_status -eq 0 ] && [ $pg_status -eq 0 ]; then
        echo -e "${GREEN}$(t tests_all_passed)${RESET}"
    else
        echo -e "${RED}$(t tests_some_failed)${RESET}"
    fi
    
    echo "$(t detailed_log): $LOG_FILE"
    echo ""
    
    read -p "$(t press_enter)" _
}

# Проверка, запущен ли скрипт напрямую
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_autotests
fi 