#!/usr/bin/env bash

# Загрузка файла с переводами
source "$(dirname "$0")/i18n.sh"

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

# Функция для запуска Docker-контейнеров
start_containers() {
    clear
    echo -e "\e[1m$(t docker_demo_title)\e[0m"
    echo "========================================"
    echo ""
    
    # Проверка на наличие Docker и Docker Compose
    if ! command -v docker &> /dev/null; then
        echo "$(t docker_not_installed)"
        echo "$(t docker_install_required)"
        read -p "$(t press_enter)" _
        return 1
    fi

    # Проверка на наличие пользователя в группе docker
    if ! check_docker_group; then
        return 1
    fi

    # Проверка на запущенный Docker демон
    if ! docker info &> /dev/null; then
        echo "$(t docker_not_running)"
        echo "$(t start_docker_daemon)"
        read -p "$(t press_enter)" _
        return 1
    fi

    echo "$(t starting_containers)"
    
    # Определяем команду docker-compose (может быть как отдельная команда, так и подкоманда docker)
    COMPOSE_CMD=""
    if command -v docker-compose &> /dev/null; then
        COMPOSE_CMD="docker-compose"
    elif docker compose version &> /dev/null; then
        COMPOSE_CMD="docker compose"
    else
        echo "$(t docker_compose_not_found)"
        read -p "$(t press_enter)" _
        return 1
    fi
    
    # Запуск контейнеров с помощью docker-compose
    $COMPOSE_CMD -f "$(dirname "$0")/docker/docker-compose.yml" up -d
    
    # Проверка успешности запуска
    if [ $? -ne 0 ]; then
        echo "$(t container_start_failed)"
        read -p "$(t press_enter)" _
        return 1
    fi
    
    echo "$(t waiting_for_services)"
    # Даем время на запуск сервисов
    sleep 5
    
    echo "$(t checking_containers)"
    # Проверка статуса контейнеров
    $COMPOSE_CMD -f "$(dirname "$0")/docker/docker-compose.yml" ps
    
    echo "$(t containers_started)"
    read -p "$(t press_enter)" _
    return 0
}

# Функция для остановки Docker-контейнеров
stop_containers() {
    clear
    echo -e "\e[1m$(t docker_demo_title)\e[0m"
    echo "========================================"
    echo ""
    
    echo "$(t stopping_containers)"
    
    # Определяем команду docker-compose
    COMPOSE_CMD=""
    if command -v docker-compose &> /dev/null; then
        COMPOSE_CMD="docker-compose"
    elif docker compose version &> /dev/null; then
        COMPOSE_CMD="docker compose"
    else
        echo "$(t docker_compose_not_found)"
        read -p "$(t press_enter)" _
        return 1
    fi
    
    # Остановка контейнеров
    $COMPOSE_CMD -f "$(dirname "$0")/docker/docker-compose.yml" down
    
    # Проверка успешности остановки
    if [ $? -ne 0 ]; then
        echo "$(t stopping_failed)"
        read -p "$(t press_enter)" _
        return 1
    fi
    
    # Проверяем, что все контейнеры остановлены
    if docker ps | grep -q "wall-be"; then
        echo "$(t stopping_failed)"
        read -p "$(t press_enter)" _
        return 1
    else
        echo "$(t containers_stopped)"
        read -p "$(t press_enter)" _
        return 0
    fi
}

# Функция для очистки Docker-ресурсов
cleanup_docker() {
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
        return 1
    fi
    
    # Определяем команду docker-compose
    COMPOSE_CMD=""
    if command -v docker-compose &> /dev/null; then
        COMPOSE_CMD="docker-compose"
    elif docker compose version &> /dev/null; then
        COMPOSE_CMD="docker compose"
    else
        echo "$(t docker_compose_not_found)"
        read -p "$(t press_enter)" _
        return 1
    fi
    
    # Остановка и удаление контейнеров
    $COMPOSE_CMD -f "$(dirname "$0")/docker/docker-compose.yml" down -v
    
    # Удаление образов
    docker rmi $(docker images --filter "reference=wall-be-*" -q) 2>/dev/null || true
    
    # Удаление неиспользуемых томов
    docker volume prune -f
    
    echo "$(t docker_cleanup_complete)"
    read -p "$(t press_enter)" _
    return 0
}

# Функция для запуска MySQL-демо в Docker
mysql_docker_demo() {
    clear
    echo -e "\e[1m$(t mysql_demo_title)\e[0m"
    echo "========================================"
    echo ""
    
    # Проверка и запуск контейнеров, если они не запущены
    if ! docker ps | grep -q wall-be-mysql; then
        echo "$(t mysql_container_not_running)"
        echo "$(t starting_containers_automatically)"
        
        # Запускаем контейнеры автоматически
        if ! start_containers; then
            echo "$(t container_start_failed)"
            read -p "$(t press_enter)" _
            return 1
        fi
        
        # Даем дополнительное время для инициализации MySQL
        echo "$(t waiting_for_mysql_init)"
        sleep 5
    fi
    
    # Проверка готовности MySQL к работе
    echo "$(t checking_mysql_connection)"
    if ! docker exec -it wall-be-mysql mysqladmin -u root -proot ping &>/dev/null; then
        echo "$(t mysql_connection_failed)"
        read -p "$(t press_enter)" _
        return 1
    fi
    
    # Создание тестовой базы и данных
    echo "$(t creating_test_db)"
    docker exec -it wall-be-mysql mysql -u root -proot -e "CREATE DATABASE IF NOT EXISTS wallbe_demo; USE wallbe_demo; CREATE TABLE IF NOT EXISTS demo_data (id INT AUTO_INCREMENT PRIMARY KEY, data VARCHAR(255), created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP); INSERT INTO demo_data (data) VALUES ('Demo data 1'), ('Demo data 2');"
    
    if [ $? -ne 0 ]; then
        echo "$(t demo_data_creation_failed)"
        read -p "$(t press_enter)" _
        return 1
    fi
    
    echo "$(t viewing_data)"
    docker exec -it wall-be-mysql mysql -u root -proot -e "SELECT * FROM wallbe_demo.demo_data;"
    
    # Создание фактического бэкапа с использованием wall-be
    echo "$(t creating_backup)"
    docker exec -it wall-be /opt/wall-be/wall-be.sh mysql backup --config /etc/wall-be/mysql.env
    
    if [ $? -ne 0 ]; then
        echo "$(t backup_creation_failed)"
        read -p "$(t press_enter)" _
        return 1
    fi
    
    echo "$(t listing_backups)"
    docker exec -it wall-be /opt/wall-be/wall-be.sh mysql list --config /etc/wall-be/mysql.env
    
    echo "$(t adding_data)"
    docker exec -it wall-be-mysql mysql -u root -proot -e "USE wallbe_demo; INSERT INTO demo_data (data) VALUES ('New data after backup');"
    
    echo "$(t viewing_updated_data)"
    docker exec -it wall-be-mysql mysql -u root -proot -e "SELECT * FROM wallbe_demo.demo_data;"
    
    echo "$(t restore_warning)"
    read -p "$(t continue_restore) " confirm
    if [[ $confirm == [yY] ]]; then
        echo "$(t restoring_backup)"
        docker exec -it wall-be /opt/wall-be/wall-be.sh mysql restore --config /etc/wall-be/mysql.env
        
        if [ $? -ne 0 ]; then
            echo "$(t restore_failed)"
            read -p "$(t press_enter)" _
            return 1
        fi
        
        echo "$(t viewing_restored_data)"
        docker exec -it wall-be-mysql mysql -u root -proot -e "SELECT * FROM wallbe_demo.demo_data;"
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
    if ! docker ps | grep -q wall-be-postgres; then
        echo "$(t postgres_container_not_running)"
        echo "$(t starting_containers_automatically)"
        
        # Запускаем контейнеры автоматически
        if ! start_containers; then
            echo "$(t container_start_failed)"
            read -p "$(t press_enter)" _
            return 1
        fi
        
        # Даем дополнительное время для инициализации PostgreSQL
        echo "$(t waiting_for_postgres_init)"
        sleep 5
    fi
    
    # Проверка готовности PostgreSQL к работе
    echo "$(t checking_postgres_connection)"
    if ! docker exec -it wall-be-postgres pg_isready -U postgres &>/dev/null; then
        echo "$(t postgres_connection_failed)"
        read -p "$(t press_enter)" _
        return 1
    fi
    
    # Создание тестовой базы и данных
    echo "$(t creating_test_table)"
    docker exec -it wall-be-postgres psql -U postgres -c "CREATE DATABASE wallbe_demo;" 2>/dev/null || true
    docker exec -it wall-be-postgres psql -U postgres -d wallbe_demo -c "CREATE TABLE IF NOT EXISTS demo_data (id SERIAL PRIMARY KEY, data VARCHAR(255), created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP); INSERT INTO demo_data (data) VALUES ('PG Demo data 1'), ('PG Demo data 2');"
    
    if [ $? -ne 0 ]; then
        echo "$(t demo_data_creation_failed)"
        read -p "$(t press_enter)" _
        return 1
    fi
    
    echo "$(t viewing_data)"
    docker exec -it wall-be-postgres psql -U postgres -d wallbe_demo -c "SELECT * FROM demo_data;"
    
    # Создание фактического бэкапа с использованием wall-be
    echo "$(t creating_backup)"
    docker exec -it wall-be /opt/wall-be/wall-be.sh postgresql backup --config /etc/wall-be/postgres.env
    
    if [ $? -ne 0 ]; then
        echo "$(t backup_creation_failed)"
        read -p "$(t press_enter)" _
        return 1
    fi
    
    echo "$(t listing_backups)"
    docker exec -it wall-be /opt/wall-be/wall-be.sh postgresql list --config /etc/wall-be/postgres.env
    
    echo "$(t adding_data)"
    docker exec -it wall-be-postgres psql -U postgres -d wallbe_demo -c "INSERT INTO demo_data (data) VALUES ('New PG data after backup');"
    
    echo "$(t viewing_updated_data)"
    docker exec -it wall-be-postgres psql -U postgres -d wallbe_demo -c "SELECT * FROM demo_data;"
    
    echo "$(t restore_warning)"
    read -p "$(t continue_restore) " confirm
    if [[ $confirm == [yY] ]]; then
        echo "$(t restoring_backup)"
        docker exec -it wall-be /opt/wall-be/wall-be.sh postgresql restore --config /etc/wall-be/postgres.env
        
        if [ $? -ne 0 ]; then
            echo "$(t restore_failed)"
            read -p "$(t press_enter)" _
            return 1
        fi
        
        echo "$(t viewing_restored_data)"
        docker exec -it wall-be-postgres psql -U postgres -d wallbe_demo -c "SELECT * FROM demo_data;"
    fi
    
    echo "$(t pg_demo_complete)"
    read -p "$(t return_main_menu)" _
    return 0
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
                # Вызов функции демонстрации расписаний
                source "$(dirname "$0")/demo.sh"
                schedule_demo
                ;;
            4)
                # Вызов функции демонстрации политик хранения
                source "$(dirname "$0")/demo.sh"
                retention_demo
                ;;
            5)
                # Показать README
                source "$(dirname "$0")/readme_content.sh"
                show_readme
                ;;
            6)
                # Подменю для управления Docker
                docker_menu
                ;;
            7)
                echo "$(t exiting)"
                exit 0
                ;;
            *)
                echo "$(t invalid_choice)"
                read -p "$(t press_enter)" _
                ;;
        esac
    done
}

# Функция для меню управления Docker
docker_menu() {
    while true; do
        clear
        echo -e "\e[1m$(t docker_management)\e[0m"
        echo "========================================"
        echo ""
        echo "$(t select_option)"
        echo ""
        echo "1. $(t starting_containers)"
        echo "2. $(t stopping_containers)"
        echo "3. $(t cleanup_docker)"
        echo "4. $(t return_main_menu)"
        echo ""

        read -p "$(t enter_number) " choice

        case $choice in
            1)
                start_containers
                ;;
            2)
                stop_containers
                ;;
            3)
                cleanup_docker
                ;;
            4)
                return
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