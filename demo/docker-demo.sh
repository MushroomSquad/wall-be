#!/usr/bin/env bash

# docker-demo.sh - Скрипт для демонстрации wall-be в Docker-контейнерах

# Определение пути к директории скрипта
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

# Загрузка переводов
source "$SCRIPT_DIR/i18n.sh"

# Установка обработчика сигнала для корректного завершения
trap cleanup EXIT

# Функция очистки при выходе
cleanup() {
    echo "$(t cleanup)"
    # Дополнительные действия по очистке, если нужны
    echo "$(t cleanup_complete)"
    exit 0
}

# Функция для проверки наличия пользователя в группе docker
check_docker_group() {
    if ! groups | grep -q "\bdocker\b"; then
        echo "$(t docker_permission_denied)"
        echo "$(t docker_group_instructions)"
        echo "sudo usermod -aG docker $USER"
        echo ""
        read -p "$(t apply_docker_group_now) (y/n)? " choice
        if [[ "$choice" == [yY] ]]; then
            echo "$(t executing_newgrp)"
            exec newgrp docker
        else
            read -p "$(t press_enter)" _
            return 1
        fi
    fi
    return 0
}

# Функция для запуска контейнеров Docker
start_containers() {
    echo "$(t starting_containers)"
    
    # Проверка наличия docker-compose
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        echo "$(t docker_compose_not_found)"
        read -p "$(t press_enter)" _
        return 1
    fi
    
    # Остановим контейнеры, если они уже запущены
    stop_containers > /dev/null 2>&1
    
    # Запускаем контейнеры с учетом выбранного профиля
    local compose_cmd
    if command -v docker-compose &> /dev/null; then
        compose_cmd="docker-compose"
    else
        compose_cmd="docker compose"
    fi
    
    cd "$SCRIPT_DIR/docker"
    
    if [ "$1" == "mysql" ]; then
        # Запускаем только MySQL контейнеры
        $compose_cmd --profile mysql up -d
    elif [ "$1" == "postgresql" ]; then
        # Запускаем только PostgreSQL контейнеры
        $compose_cmd --profile postgresql up -d
    else
        # Запускаем все контейнеры
        $compose_cmd --profile all up -d
    fi
    
    if [ $? -ne 0 ]; then
        echo "$(t container_start_failed)"
        cd - > /dev/null
        return 1
    fi
    
    echo "$(t waiting_for_services)"
    sleep 5
    
    echo "$(t checking_containers)"
    
    # Проверяем наличие необходимых контейнеров в зависимости от выбранного профиля
    if [ "$1" == "mysql" ]; then
        if ! docker ps | grep -q wall-be-mysql; then
            echo "$(t mysql_container_failed)"
            cd - > /dev/null
            return 1
        fi
        if ! docker ps | grep -q wall-be; then
            echo "$(t wallbe_container_failed)"
            cd - > /dev/null
            return 1
        fi
    elif [ "$1" == "postgresql" ]; then
        if ! docker ps | grep -q wall-be-postgres; then
            echo "$(t postgres_container_failed)"
            cd - > /dev/null
            return 1
        fi
        if ! docker ps | grep -q wall-be; then
            echo "$(t wallbe_container_failed)"
            cd - > /dev/null
            return 1
        fi
    else
        # Проверяем все контейнеры
        if ! docker ps | grep -q wall-be-mysql; then
            echo "$(t mysql_container_failed)"
            cd - > /dev/null
            return 1
        fi
        if ! docker ps | grep -q wall-be-postgres; then
            echo "$(t postgres_container_failed)"
            cd - > /dev/null
            return 1
        fi
        if ! docker ps | grep -q wall-be; then
            echo "$(t wallbe_container_failed)"
            cd - > /dev/null
            return 1
        fi
    fi
    
    echo "$(t containers_started)"
    cd - > /dev/null
    return 0
}

# Функция для остановки контейнеров Docker
stop_containers() {
    echo "$(t stopping_containers)"
    
    # Проверка наличия docker-compose
    local compose_cmd
    if command -v docker-compose &> /dev/null; then
        compose_cmd="docker-compose"
    elif docker compose version &> /dev/null; then
        compose_cmd="docker compose"
    else
        echo "$(t docker_compose_not_found)"
        return 1
    fi
    
    cd "$SCRIPT_DIR/docker"
    
    # Остановка контейнеров
    $compose_cmd down
    
    if [ $? -ne 0 ]; then
        echo "$(t stopping_failed)"
        cd - > /dev/null
        return 1
    fi
    
    echo "$(t containers_stopped)"
    cd - > /dev/null
    return 0
}

# Функция для очистки Docker-ресурсов
docker_cleanup() {
    clear
    echo -e "\e[1m$(t docker_demo_title)\e[0m"
    echo "========================================"
    echo ""
    
    echo "$(t cleanup_docker)"
    echo "$(t cleanup_warning)"
    read -p "$(t continue_cleanup) " confirm
    
    if [[ $confirm != [yY] ]]; then
        echo "$(t cleanup_cancelled)"
        read -p "$(t press_enter)" _
        return 0
    fi
    
    # Останавливаем все контейнеры
    stop_containers > /dev/null 2>&1
    
    echo "$(t cleanup_docker)"
    
    # Проверка наличия docker-compose
    local compose_cmd
    if command -v docker-compose &> /dev/null; then
        compose_cmd="docker-compose"
    elif docker compose version &> /dev/null; then
        compose_cmd="docker compose"
    else
        echo "$(t docker_compose_not_found)"
        read -p "$(t press_enter)" _
        return 1
    fi
    
    cd "$SCRIPT_DIR/docker"
    
    # Удаляем все контейнеры, образы и тома
    $compose_cmd down -v --rmi all --remove-orphans
    
    # Удаляем все образы связанные с wall-be
    docker images | grep wall-be | awk '{print $3}' | xargs -r docker rmi -f
    
    # Удаляем все Docker-ресурсы, связанные с демонстрацией
    docker volume prune -f
    
    echo "$(t docker_cleanup_complete)"
    read -p "$(t press_enter)" _
    cd - > /dev/null
    return 0
}

# Определим функцию для запуска команд Docker без интерактивного режима
docker_exec() {
    docker exec "$@"
}

# Функция для проверки наличия контейнеров MySQL
check_mysql_containers() {
    if ! docker ps | grep -q wall-be-mysql; then
        return 1
    fi
    
    if ! docker ps | grep -q wall-be; then
        return 1
    fi
    
    return 0
}

# Функция для проверки наличия контейнеров PostgreSQL
check_postgresql_containers() {
    if ! docker ps | grep -q wall-be-postgres; then
        return 1
    fi
    
    if ! docker ps | grep -q wall-be; then
        return 1
    fi
    
    return 0
}

# Функция для запуска MySQL-демо в Docker
mysql_docker_demo() {
    clear
    echo -e "\e[1m$(t mysql_demo_title)\e[0m"
    echo "========================================"
    echo ""
    
    # Проверка и запуск контейнеров, если они не запущены
    if ! check_mysql_containers; then
        echo "$(t mysql_container_not_running)"
        echo "$(t starting_containers_automatically)"
        
        # Запускаем только MySQL контейнеры
        if ! start_containers "mysql"; then
            echo "$(t container_start_failed)"
            read -p "$(t press_enter)" _
            return 1
        fi
        
        # Даем дополнительное время для инициализации MySQL
        echo "$(t waiting_for_mysql_init)"
        sleep 10
    fi
    
    # Проверка готовности MySQL к работе - используем контейнер wall-be для проверки
    echo "$(t checking_mysql_connection)"
    if ! docker exec wall-be mysql -h wall-be-mysql -u root -proot -e "SELECT 1" &>/dev/null; then
        echo "$(t mysql_connection_failed)"
        read -p "$(t press_enter)" _
        return 1
    fi
    
    # Создание тестовой базы и данных
    echo "$(t creating_test_db)"
    docker exec wall-be mysql -h wall-be-mysql -u root -proot -e "CREATE DATABASE IF NOT EXISTS wallbe_demo; USE wallbe_demo; CREATE TABLE IF NOT EXISTS demo_data (id INT AUTO_INCREMENT PRIMARY KEY, data VARCHAR(255), created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP); INSERT INTO demo_data (data) VALUES ('Demo data 1'), ('Demo data 2');"
    
    if [ $? -ne 0 ]; then
        echo "$(t demo_data_creation_failed)"
        read -p "$(t press_enter)" _
        return 1
    fi
    
    echo "$(t viewing_data)"
    docker exec wall-be mysql -h wall-be-mysql -u root -proot -e "SELECT * FROM wallbe_demo.demo_data;"
    
    # Создание фактического бэкапа с использованием wall-be
    echo "$(t creating_backup)"
    docker exec wall-be /opt/wall-be/wall-be.sh mysql backup --config /etc/wall-be/mysql.env
    
    if [ $? -ne 0 ]; then
        echo "$(t backup_creation_failed)"
        read -p "$(t press_enter)" _
        return 1
    fi
    
    echo "$(t listing_backups)"
    docker exec wall-be /opt/wall-be/wall-be.sh mysql list --config /etc/wall-be/mysql.env
    
    echo "$(t adding_data)"
    docker exec wall-be mysql -h wall-be-mysql -u root -proot -e "USE wallbe_demo; INSERT INTO demo_data (data) VALUES ('New data after backup');"
    
    echo "$(t viewing_updated_data)"
    docker exec wall-be mysql -h wall-be-mysql -u root -proot -e "SELECT * FROM wallbe_demo.demo_data;"
    
    echo "$(t restore_warning)"
    read -p "$(t continue_restore) " confirm
    if [[ $confirm == [yY] ]]; then
        echo "$(t restoring_backup)"
        docker exec wall-be /opt/wall-be/wall-be.sh mysql restore --config /etc/wall-be/mysql.env
        
        if [ $? -ne 0 ]; then
            echo "$(t restore_failed)"
            read -p "$(t press_enter)" _
            return 1
        fi
        
        echo "$(t viewing_restored_data)"
        docker exec wall-be mysql -h wall-be-mysql -u root -proot -e "SELECT * FROM wallbe_demo.demo_data;"
    fi
    
    echo "$(t mysql_demo_complete)"
    read -p "$(t return_main_menu)" _
    return 0
}

# Функция для запуска PostgreSQL-демо в Docker
postgresql_docker_demo() {
    clear
    echo -e "\e[1m$(t postgresql_demo_title)\e[0m"
    echo "========================================"
    echo ""
    
    # Проверка и запуск контейнеров, если они не запущены
    if ! check_postgresql_containers; then
        echo "$(t postgres_container_not_running)"
        echo "$(t starting_containers_automatically)"
        
        # Запускаем только PostgreSQL контейнеры
        if ! start_containers "postgresql"; then
            echo "$(t container_start_failed)"
            read -p "$(t press_enter)" _
            return 1
        fi
        
        # Даем дополнительное время для инициализации PostgreSQL
        echo "$(t waiting_for_postgres_init)"
        sleep 10
    fi
    
    # Проверка готовности PostgreSQL к работе - используем контейнер wall-be для проверки
    echo "$(t checking_postgres_connection)"
    if ! docker exec wall-be bash -c "PGPASSWORD=postgres psql -h wall-be-postgres -U postgres -c 'SELECT 1'" &>/dev/null; then
        echo "$(t postgres_connection_failed)"
        read -p "$(t press_enter)" _
        return 1
    fi
    
    # Создание тестовой базы и данных
    echo "$(t creating_test_table)"
    docker exec wall-be bash -c "PGPASSWORD=postgres psql -h wall-be-postgres -U postgres -c 'CREATE DATABASE wallbe_demo;'" 2>/dev/null || true
    docker exec wall-be bash -c "PGPASSWORD=postgres psql -h wall-be-postgres -U postgres -d wallbe_demo -c 'CREATE TABLE IF NOT EXISTS demo_data (id SERIAL PRIMARY KEY, data VARCHAR(255), created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP); INSERT INTO demo_data (data) VALUES (''PG Demo data 1''), (''PG Demo data 2'');'"
    
    if [ $? -ne 0 ]; then
        echo "$(t demo_data_creation_failed)"
        read -p "$(t press_enter)" _
        return 1
    fi
    
    echo "$(t viewing_data)"
    docker exec wall-be bash -c "PGPASSWORD=postgres psql -h wall-be-postgres -U postgres -d wallbe_demo -c 'SELECT * FROM demo_data;'"
    
    # Создание фактического бэкапа с использованием wall-be
    echo "$(t creating_backup)"
    docker exec wall-be /opt/wall-be/wall-be.sh postgresql backup --config /etc/wall-be/postgres.env
    
    if [ $? -ne 0 ]; then
        echo "$(t backup_creation_failed)"
        read -p "$(t press_enter)" _
        return 1
    fi
    
    echo "$(t listing_backups)"
    docker exec wall-be /opt/wall-be/wall-be.sh postgresql list --config /etc/wall-be/postgres.env
    
    echo "$(t adding_data)"
    docker exec wall-be bash -c "PGPASSWORD=postgres psql -h wall-be-postgres -U postgres -d wallbe_demo -c 'INSERT INTO demo_data (data) VALUES (''New PG data after backup'');'"
    
    echo "$(t viewing_updated_data)"
    docker exec wall-be bash -c "PGPASSWORD=postgres psql -h wall-be-postgres -U postgres -d wallbe_demo -c 'SELECT * FROM demo_data;'"
    
    echo "$(t restore_warning)"
    read -p "$(t continue_restore) " confirm
    if [[ $confirm == [yY] ]]; then
        echo "$(t restoring_backup)"
        docker exec wall-be /opt/wall-be/wall-be.sh postgresql restore --config /etc/wall-be/postgres.env
        
        if [ $? -ne 0 ]; then
            echo "$(t restore_failed)"
            read -p "$(t press_enter)" _
            return 1
        fi
        
        echo "$(t viewing_restored_data)"
        docker exec wall-be bash -c "PGPASSWORD=postgres psql -h wall-be-postgres -U postgres -d wallbe_demo -c 'SELECT * FROM demo_data;'"
    fi
    
    echo "$(t pg_demo_complete)"
    read -p "$(t return_main_menu)" _
    return 0
}

# Функция для просмотра README
readme_demo() {
    clear
    echo -e "\e[1m$(t readme_title)\e[0m"
    echo "========================================"
    echo ""
    
    # Показываем содержимое README
    echo "$(t readme_intro)"
    echo ""
    echo "1. $(t mysql_demo) - $(t mysql_demo_desc)"
    echo "2. $(t postgresql_demo) - $(t postgresql_demo_desc)"
    echo "3. $(t schedule_demo) - $(t schedule_demo_desc)"
    echo "4. $(t retention_demo) - $(t retention_demo_desc)"
    echo ""
    echo "$(t docker_note)"
    echo ""
    
    read -p "$(t press_enter)" _
    return 0
}

# Функция для демонстрации расписаний
schedule_demo() {
    clear
    echo -e "\e[1m$(t schedule_demo_title)\e[0m"
    echo "========================================"
    echo ""
    
    echo "$(t cron_examples):"
    echo "$(t daily_2am): 0 2 * * *"
    echo "$(t monday_330am): 30 3 * * 1"
    echo "$(t every_6_hours): 0 */6 * * *"
    echo "$(t first_day_month): 0 4 1 * *"
    echo ""
    
    echo "$(t schedule_command):"
    echo "wall-be schedule --cron=\"0 2 * * *\" --config=config.env"
    echo ""
    
    echo "$(t crontab_example):"
    echo "$(t backup_mysql_daily)"
    echo "0 2 * * * /usr/local/bin/wall-be backup --config=/etc/wall-be/config.env"
    echo ""
    
    echo "$(t shell_script_example):"
    echo "#!/bin/bash"
    echo "source /etc/wall-be/config.env"
    echo "wall-be backup"
    echo ""
    
    read -p "$(t press_enter)" _
    return 0
}

# Функция для демонстрации политик хранения
retention_demo() {
    clear
    echo -e "\e[1m$(t retention_demo_title)\e[0m"
    echo "========================================"
    echo ""
    
    echo "$(t available_policies):"
    echo "$(t full_backups_policy) (WALG_RETENTION_FULL_BACKUPS=5)"
    echo "$(t days_policy) (WALG_RETENTION_DAYS=7)"
    echo "$(t count_policy) (WALG_RETENTION_COUNT=10)"
    echo ""
    
    echo "$(t config_example):"
    echo "WALG_RETENTION_FULL_BACKUPS=5"
    echo "WALG_RETENTION_DAYS=7"
    echo "WALG_RETENTION_COUNT=10"
    echo ""
    
    echo "$(t retention_command):"
    echo "wall-be backup --apply-retention"
    echo ""
    
    echo "$(t retention_logic):"
    echo "$(t retention_logic_1)"
    echo "$(t retention_logic_1_detail)"
    echo "$(t retention_logic_2)"
    echo "$(t retention_logic_2_detail_1)"
    echo "$(t retention_logic_2_detail_2)"
    echo ""
    
    read -p "$(t press_enter)" _
    return 0
}

# Функция для меню управления Docker
docker_management() {
    clear
    echo -e "\e[1m$(t docker_management)\e[0m"
    echo "========================================"
    echo ""
    
    echo "$(t select_option):"
    echo "1. $(t start_mysql_containers)"
    echo "2. $(t start_postgresql_containers)" 
    echo "3. $(t start_all_containers)"
    echo "4. $(t stop_containers)"
    echo "5. $(t docker_cleanup)"
    echo "6. $(t back)"
    echo ""
    
    read -p "$(t enter_number) " choice
    
    case $choice in
        1)
            start_containers "mysql"
            read -p "$(t press_enter)" _
            ;;
        2)
            start_containers "postgresql"
            read -p "$(t press_enter)" _
            ;;
        3)
            start_containers "all"
            read -p "$(t press_enter)" _
            ;;
        4)
            stop_containers
            read -p "$(t press_enter)" _
            ;;
        5)
            docker_cleanup
            ;;
        6)
            return 0
            ;;
        *)
            echo "$(t invalid_choice)"
            read -p "$(t press_enter)" _
            ;;
    esac
    
    # Возвращаемся в это же меню
    docker_management
}

# Основная функция с меню демонстрации
main_menu() {
    while true; do
        clear
        echo -e "\e[1m$(t demo_title) - Docker\e[0m"
        echo -e "\e[3m$(t demo_subtitle)\e[0m"
        echo "========================================"
        echo ""
        echo "$(t select_demo)"
        echo ""
        echo "1. $(t mysql_demo)"
        echo "2. $(t postgresql_demo)"
        echo "3. $(t schedule_demo)"
        echo "4. $(t retention_demo)"
        echo "5. $(t readme_demo)"
        echo "6. $(t docker_management)"
        echo "7. $(t exit)"
        echo ""

        read -p "$(t enter_number) " choice

        case $choice in
            1)
                mysql_docker_demo
                ;;
            2)
                postgresql_docker_demo
                ;;
            3)
                schedule_demo
                ;;
            4)
                retention_demo
                ;;
            5)
                readme_demo
                ;;
            6)
                docker_management
                ;;
            7)
                echo "$(t exiting)"
                stop_containers > /dev/null 2>&1
                exit 0
                ;;
            *)
                echo "$(t invalid_choice)"
                read -p "$(t press_enter)" _
                ;;
        esac
    done
}

# Запуск основной функции
main_menu