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

# Функция настройки WAL-G для демонстрации
setup_walg_demo() {
    echo "$(t setting_up_walg_demo)"
    
    # Проверяем, установлены ли WAL-G бинарники
    if [ ! -f "/usr/local/bin/wal-g-mysql" ] || [ ! -f "/usr/local/bin/wal-g-pg" ]; then
        echo "$(t creating_demo_placeholders)"
        
        # Создаем директорию для бинарников, если её нет
        sudo mkdir -p /usr/local/bin
        
        # Создаем заглушки для MySQL и PostgreSQL WAL-G
        if [ ! -f "/usr/local/bin/wal-g-mysql" ]; then
            echo '#!/bin/bash
echo "This is a WAL-G MySQL placeholder for demonstration purposes."
echo "In a real environment, this would be the actual WAL-G binary."
exit 0' | sudo tee /usr/local/bin/wal-g-mysql > /dev/null
            sudo chmod +x /usr/local/bin/wal-g-mysql
        fi
        
        if [ ! -f "/usr/local/bin/wal-g-pg" ]; then
            echo '#!/bin/bash
echo "This is a WAL-G PostgreSQL placeholder for demonstration purposes."
echo "In a real environment, this would be the actual WAL-G binary."
exit 0' | sudo tee /usr/local/bin/wal-g-pg > /dev/null
            sudo chmod +x /usr/local/bin/wal-g-pg
        fi
        
        # Создаем символическую ссылку на общую команду wal-g
        sudo ln -sf /usr/local/bin/wal-g-pg /usr/local/bin/wal-g
    fi
    
    echo "$(t wal_g_setup_complete)"
}

# Функция демонстрации MySQL
mysql_demo() {
    clear
    echo -e "\e[1m$(t mysql_demo_title)\e[0m"
    echo "========================================"
    echo ""
    
    # Проверка наличия WAL-G
    setup_walg_demo
    
    echo -e "\e[33m$(t setting_up_mysql_demo)\e[0m"
    # Создаем тестовую базу данных для демонстрации
    echo -e "\e[36m> $(t creating_test_db)\e[0m"
    echo -e "  $(t demo_creating_db_tables)"
    echo "  CREATE DATABASE wallbe_demo;"
    echo "  USE wallbe_demo;"
    echo "  CREATE TABLE test_table (id INT AUTO_INCREMENT PRIMARY KEY, data VARCHAR(255));"
    echo "  INSERT INTO test_table (data) VALUES ('Test data 1'), ('Test data 2');"
    echo ""
    sleep 1
    
    echo -e "\e[36m> $(t viewing_initial_data)\e[0m"
    echo "  SELECT * FROM test_table;"
    echo "  +----+-------------+"
    echo "  | id | data        |"
    echo "  +----+-------------+"
    echo "  | 1  | Test data 1 |"
    echo "  | 2  | Test data 2 |"
    echo "  +----+-------------+"
    echo "  2 rows in set (0.00 sec)"
    echo ""
    sleep 1
    
    # Имитируем создание резервной копии
    echo -e "\e[33m$(t creating_mysql_backup)\e[0m"
    echo -e "  $(t demo_executing_command) \e[32mwal-g-mysql backup-push\e[0m"
    echo ""
    echo "  $(t demo_backup_process_started)"
    echo "  $(t demo_backup_compressing_data)"
    echo "  $(t demo_backup_uploading_to_storage)"
    echo "  $(t demo_backup_completed)"
    echo ""
    sleep 1
    
    echo -e "\e[36m> $(t listing_backups)\e[0m"
    echo "  $(t demo_executing_command) \e[32mwal-g-mysql backup-list\e[0m"
    echo ""
    echo "  name                          last_modified             wal_segment_backup_start         size       storage_size"
    echo "  ------------------------------------------------------------------------------------------------------"
    echo "  mysql_base_$(date +%Y%m%d)_1  $(date "+%Y-%m-%d %H:%M:%S").000000+00  permanent  16.2 MiB  16.2 MiB"
    echo "  mysql_base_$(date +%Y%m%d)_2  $(date -d '1 hour ago' "+%Y-%m-%d %H:%M:%S").000000+00  permanent  16.4 MiB  16.4 MiB"
    echo ""
    sleep 1
    
    # Имитируем добавление данных
    echo -e "\e[36m> $(t adding_data)\e[0m"
    echo "  INSERT INTO test_table (data) VALUES ('New data after backup');"
    echo "  Query OK, 1 row affected (0.00 sec)"
    echo ""
    echo "  SELECT * FROM test_table;"
    echo "  +----+----------------------+"
    echo "  | id | data                 |"
    echo "  +----+----------------------+"
    echo "  | 1  | Test data 1          |"
    echo "  | 2  | Test data 2          |"
    echo "  | 3  | New data after backup|"
    echo "  +----+----------------------+"
    echo "  3 rows in set (0.00 sec)"
    echo ""
    sleep 1
    
    # Имитируем восстановление резервной копии
    echo -e "\e[33m$(t restore_warning)\e[0m"
    read -p "$(t continue_mysql_restore) " confirm
    if [[ $confirm == [yY] ]]; then
        echo -e "\e[33m$(t restoring_mysql_backup)\e[0m"
        echo -e "  $(t demo_executing_command) \e[32mwal-g-mysql backup-fetch LATEST\e[0m"
        echo ""
        echo "  $(t demo_restore_process_started)"
        echo "  $(t demo_restore_downloading_backup)"
        echo "  $(t demo_restore_extracting_data)"
        echo "  $(t demo_restore_applying_to_mysql)"
        echo "  $(t demo_restore_completed)"
        echo ""
        sleep 1
        
        echo -e "\e[36m> $(t viewing_restored_data)\e[0m"
        echo "  SELECT * FROM test_table;"
        echo "  +----+-------------+"
        echo "  | id | data        |"
        echo "  +----+-------------+"
        echo "  | 1  | Test data 1 |"
        echo "  | 2  | Test data 2 |"
        echo "  +----+-------------+"
        echo "  2 rows in set (0.00 sec)"
        echo ""
        sleep 1
        
        echo -e "  $(t demo_restore_note)"
        echo ""
    fi
    
    echo -e "\e[32m$(t mysql_demo_complete)\e[0m"
    read -p "$(t return_main_menu)" _
}

# Функция демонстрации PostgreSQL
postgresql_demo() {
    clear
    echo -e "\e[1m$(t postgresql_demo_title)\e[0m"
    echo "========================================"
    echo ""
    
    # Проверка наличия WAL-G
    setup_walg_demo
    
    echo -e "\e[33m$(t setting_up_postgresql_demo)\e[0m"
    # Создаем тестовую базу данных для демонстрации
    echo -e "\e[36m> $(t creating_test_table)\e[0m"
    echo -e "  $(t demo_creating_pg_db_tables)"
    echo "  CREATE DATABASE wallbe_demo;"
    echo "  \\c wallbe_demo"
    echo "  CREATE TABLE demo_data (id SERIAL PRIMARY KEY, data VARCHAR(255), created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);"
    echo "  INSERT INTO demo_data (data) VALUES ('PG Demo data 1'), ('PG Demo data 2');"
    echo ""
    sleep 1
    
    echo -e "\e[36m> $(t viewing_initial_data)\e[0m"
    echo "  SELECT * FROM demo_data;"
    echo "   id |     data      |         created_at         "
    echo "  ----+---------------+---------------------------"
    echo "    1 | PG Demo data 1 | $(date -d '1 hour ago' "+%Y-%m-%d %H:%M:%S")"
    echo "    2 | PG Demo data 2 | $(date -d '59 min ago' "+%Y-%m-%d %H:%M:%S")"
    echo "  (2 rows)"
    echo ""
    sleep 1
    
    # Имитируем создание резервной копии
    echo -e "\e[33m$(t creating_pg_backup)\e[0m"
    echo -e "  $(t demo_executing_command) \e[32mwal-g-pg backup-push\e[0m"
    echo ""
    echo "  $(t demo_pg_backup_process_started)"
    echo "  $(t demo_pg_backup_starting_backup_mode)"
    echo "  $(t demo_pg_backup_creating_snapshot)"
    echo "  $(t demo_pg_backup_compressing_data)"
    echo "  $(t demo_pg_backup_uploading_to_storage)"
    echo "  $(t demo_pg_backup_completed)"
    echo ""
    sleep 1
    
    echo -e "\e[36m> $(t listing_backups)\e[0m"
    echo -e "  $(t demo_executing_command) \e[32mwal-g-pg backup-list\e[0m"
    echo ""
    echo "  name                          last_modified             wal_segment_backup_start         size       storage_size"
    echo "  ------------------------------------------------------------------------------------------------------"
    echo "  base_$(date +%Y%m%d)_1  $(date "+%Y-%m-%d %H:%M:%S").000000+00  permanent  20.5 MiB  20.5 MiB"
    echo "  base_$(date +%Y%m%d)_2  $(date -d '1 hour ago' "+%Y-%m-%d %H:%M:%S").000000+00  permanent  21.2 MiB  21.2 MiB"
    echo ""
    sleep 1
    
    # Имитируем добавление данных
    echo -e "\e[36m> $(t adding_data)\e[0m"
    echo "  INSERT INTO demo_data (data) VALUES ('New PG data after backup');"
    echo "  INSERT 0 1"
    echo ""
    echo "  SELECT * FROM demo_data;"
    echo "   id |          data          |         created_at         "
    echo "  ----+------------------------+---------------------------"
    echo "    1 | PG Demo data 1         | $(date -d '1 hour ago' "+%Y-%m-%d %H:%M:%S")"
    echo "    2 | PG Demo data 2         | $(date -d '59 min ago' "+%Y-%m-%d %H:%M:%S")"
    echo "    3 | New PG data after backup | $(date "+%Y-%m-%d %H:%M:%S")"
    echo "  (3 rows)"
    echo ""
    sleep 1
    
    # Имитируем восстановление резервной копии
    echo -e "\e[33m$(t restore_warning)\e[0m"
    read -p "$(t continue_pg_restore) " confirm
    if [[ $confirm == [yY] ]]; then
        echo -e "\e[33m$(t restoring_pg_backup)\e[0m"
        echo -e "  $(t demo_executing_command) \e[32mwal-g-pg backup-fetch LATEST\e[0m"
        echo ""
        echo "  $(t demo_pg_restore_process_started)"
        echo "  $(t demo_pg_restore_stopping_postgres)"
        echo "  $(t demo_pg_restore_downloading_backup)"
        echo "  $(t demo_pg_restore_extracting_data)"
        echo "  $(t demo_pg_restore_starting_postgres)"
        echo "  $(t demo_pg_restore_completed)"
        echo ""
        sleep 1
        
        echo -e "\e[36m> $(t viewing_restored_data)\e[0m"
        echo "  SELECT * FROM demo_data;"
        echo "   id |     data      |         created_at         "
        echo "  ----+---------------+---------------------------"
        echo "    1 | PG Demo data 1 | $(date -d '1 hour ago' "+%Y-%m-%d %H:%M:%S")"
        echo "    2 | PG Demo data 2 | $(date -d '59 min ago' "+%Y-%m-%d %H:%M:%S")"
        echo "  (2 rows)"
        echo ""
        sleep 1
        
        echo -e "  $(t demo_pg_restore_note)"
        echo ""
    fi
    
    echo -e "\e[32m$(t pg_demo_complete)\e[0m"
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