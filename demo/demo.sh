#!/usr/bin/env bash

# Загрузка файла с переводами
source "$(dirname "$0")/i18n.sh"

# Загрузка скрипта README
source "$(dirname "$0")/readme_content.sh"

# Установка обработчика сигнала для корректного завершения
trap cleanup EXIT

# Функция очистки при выходе
cleanup() {
    echo "$(t cleanup)"
    # Дополнительные действия по очистке, если нужны
    echo "$(t cleanup_complete)"
    exit 0
}

# Основная функция с меню демонстрации
main_menu() {
    while true; do
        clear
        echo -e "\e[1m$(t demo_title)\e[0m"
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
        echo "6. $(t exit)"
        echo ""

        read -p "$(t enter_number) " choice

        case $choice in
            1)
                # Проверка на наличие MySQL/MariaDB
                if command -v mysql &> /dev/null; then
                    mysql_demo
                else
                    echo "$(t mysql_not_installed)"
                    echo "$(t mysql_install_required)"
                    read -p "$(t press_enter)" _
                fi
                ;;
            2)
                # Проверка на наличие PostgreSQL
                if command -v psql &> /dev/null; then
                    postgresql_demo
                else
                    echo "$(t postgresql_not_installed)"
                    echo "$(t postgresql_install_required)"
                    read -p "$(t press_enter)" _
                fi
                ;;
            3)
                schedule_demo
                ;;
            4)
                retention_demo
                ;;
            5)
                show_readme
                ;;
            6)
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

# Функция демонстрации MySQL
mysql_demo() {
    clear
    echo -e "\e[1m$(t mysql_demo_title)\e[0m"
    echo "========================================"
    echo ""
    
    echo "$(t creating_test_db)"
    # Здесь добавляем код для создания тестовой БД MySQL
    
    echo "$(t viewing_data)"
    # Здесь добавляем код для просмотра данных
    
    echo "$(t creating_backup)"
    # Здесь добавляем код для создания резервной копии
    
    echo "$(t listing_backups)"
    # Здесь добавляем код для просмотра списка резервных копий
    
    echo "$(t adding_data)"
    # Здесь добавляем код для добавления новых данных
    
    echo "$(t viewing_updated_data)"
    # Здесь добавляем код для просмотра обновленных данных
    
    echo "$(t restore_warning)"
    read -p "$(t continue_restore) " confirm
    if [[ $confirm == [yY] ]]; then
        echo "$(t restoring_backup)"
        # Здесь добавляем код для восстановления из резервной копии
        
        echo "$(t viewing_restored_data)"
        # Здесь добавляем код для просмотра восстановленных данных
    fi
    
    echo "$(t mysql_demo_complete)"
    read -p "$(t return_main_menu)" _
}

# Функция демонстрации PostgreSQL
postgresql_demo() {
    clear
    echo -e "\e[1m$(t postgresql_demo_title)\e[0m"
    echo "========================================"
    echo ""
    
    echo "$(t creating_test_table)"
    # Здесь добавляем код для создания тестовой таблицы PostgreSQL
    
    # Остальные шаги аналогично MySQL...
    
    echo "$(t pg_demo_complete)"
    read -p "$(t return_main_menu)" _
}

# Функция демонстрации расписаний
schedule_demo() {
    clear
    echo -e "\e[1m$(t schedule_demo_title)\e[0m"
    echo "========================================"
    echo ""
    
    echo "$(t cron_examples)"
    echo ""
    echo "* $(t daily_2am): 0 2 * * *"
    echo "* $(t monday_330am): 30 3 * * 1"
    echo "* $(t every_6_hours): 0 */6 * * *"
    echo "* $(t first_day_month): 0 4 1 * *"
    echo ""
    
    echo "$(t schedule_command)"
    echo "wall-be schedule --cron=\"0 2 * * *\" --config=config.env"
    echo ""
    
    echo "$(t crontab_example)"
    echo "$(t backup_mysql_daily)"
    echo "0 2 * * * /usr/local/bin/wall-be backup --config=/etc/wall-be/config.env"
    echo ""
    
    echo "$(t shell_script_example)"
    echo "#!/bin/bash"
    echo "# backup_daily.sh"
    echo "cd /path/to/your/database"
    echo "source /etc/wall-be/config.env"
    echo "wall-be backup"
    echo ""
    
    read -p "$(t return_main_menu)" _
}

# Функция демонстрации политик хранения
retention_demo() {
    clear
    echo -e "\e[1m$(t retention_demo_title)\e[0m"
    echo "========================================"
    echo ""
    
    echo "$(t available_policies)"
    echo "$(t full_backups_policy)"
    echo "$(t days_policy)"
    echo "$(t count_policy)"
    echo ""
    
    echo "$(t config_example)"
    echo "WALG_MYSQL_FULL_BACKUPS=5      # Хранить 5 последних полных резервных копий"
    echo "WALG_MYSQL_DAYS_TO_KEEP=30     # Хранить резервные копии за 30 дней"
    echo "WALG_MYSQL_TOTAL_BACKUPS=100   # Хранить 100 последних резервных копий"
    echo ""
    
    echo "$(t retention_command)"
    echo "wall-be backup --apply-retention"
    echo ""
    
    echo "$(t retention_logic)"
    echo "$(t retention_logic_1)"
    echo "$(t retention_logic_1_detail)"
    echo ""
    echo "$(t retention_logic_2)"
    echo "$(t retention_logic_2_detail_1)"
    echo "$(t retention_logic_2_detail_2)"
    echo ""
    
    read -p "$(t return_main_menu)" _
}

# Запуск основной функции
main_menu 