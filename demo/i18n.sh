#!/usr/bin/env bash

# i18n.sh - Файл с переводами для демонстрационных скриптов wall-be

# Определение языка системы
detect_language() {
    local lang="${LANG:-${LC_ALL:-${LC_MESSAGES:-en_US}}}"
    lang="${lang%%.*}"  # Убираем кодировку
    lang="${lang%%@*}"  # Убираем модификатор региона
    
    # Если язык начинается с ru, используем русский
    if [[ "$lang" == ru* ]]; then
        echo "ru"
    else
        echo "en"
    fi
}

# Переопределение языка через параметр или переменную окружения
DEMO_LANG="${DEMO_LANG:-$(detect_language)}"

# Экспорт переменной языка для всех скриптов
export DEMO_LANG

# Функция для получения перевода
translate() {
    local key="$1"
    
    # Если язык русский, вернуть русский перевод
    if [ "$DEMO_LANG" = "ru" ]; then
        echo "${TRANSLATIONS_RU[$key]}"
    else
        echo "${TRANSLATIONS_EN[$key]}"
    fi
}

# Сокращение для удобства
t() {
    translate "$1"
}

# Переводы на английском (по умолчанию)
declare -A TRANSLATIONS_EN
TRANSLATIONS_EN=(
    # Общие строки
    ["demo_title"]="WALL-BE DEMONSTRATION"
    ["demo_subtitle"]="Database Backup Tool"
    ["press_enter"]="Press Enter to continue..."
    ["return_main_menu"]="Press Enter to return to the main menu..."
    ["invalid_choice"]="Invalid choice. Please choose a number from the list."
    ["exiting"]="Exiting demonstration mode."
    ["cleanup"]="Cleaning up temporary files..."
    ["cleanup_complete"]="Cleanup complete."
    ["and"]="and"
    
    # Главное меню
    ["select_demo"]="Select a demonstration:"
    ["mysql_demo"]="MySQL/MariaDB"
    ["postgresql_demo"]="PostgreSQL"
    ["schedule_demo"]="Backup Scheduling"
    ["retention_demo"]="Retention Policies"
    ["readme_demo"]="README / Help"
    ["exit"]="Exit"
    ["enter_number"]="Enter a number [1-7]: "
    
    # run-demo.sh меню
    ["standard_demo"]="Standard demonstration (local database)"
    ["docker_demo"]="Docker demonstration"
    ["autotest_demo"]="Automated testing"
    ["help_option"]="Help"
    ["setup_dependencies"]="Install and configure dependencies"
    
    # setup_dependencies.sh
    ["setup_dependencies_title"]="WALL-BE DEPENDENCIES SETUP"
    ["root_required"]="This script must be run as root!"
    ["run_as_root"]="Please run this script as root:"
    ["installing_common_deps"]="Installing common dependencies..."
    ["installing"]="Installing"
    ["already_installed"]="Already installed:"
    ["unsupported_distro"]="Unsupported distribution. Please install dependencies manually."
    ["common_deps_installed"]="Common dependencies installed."
    ["installing_mysql"]="Installing MySQL/MariaDB..."
    ["mysql_installed"]="MySQL/MariaDB installed successfully."
    ["mysql_install_failed"]="Failed to install MySQL/MariaDB."
    ["installing_postgresql"]="Installing PostgreSQL..."
    ["postgresql_installed"]="PostgreSQL installed successfully."
    ["postgresql_install_failed"]="Failed to install PostgreSQL."
    ["installing_docker"]="Installing Docker..."
    ["docker_installed"]="Docker installed successfully."
    ["docker_install_failed"]="Failed to install Docker."
    ["docker_compose_installed"]="Docker Compose installed successfully."
    ["docker_compose_install_failed"]="Failed to install Docker Compose."
    ["installing_walg"]="Installing WAL-G..."
    ["walg_installed"]="WAL-G installed successfully."
    ["walg_install_failed"]="Failed to install WAL-G."
    ["setting_up_mysql_demo"]="Setting up MySQL for demonstration..."
    ["starting_mysql"]="Starting MySQL service..."
    ["mysql_demo_setup_complete"]="MySQL setup for demonstration completed."
    ["setting_up_postgresql_demo"]="Setting up PostgreSQL for demonstration..."
    ["starting_postgresql"]="Starting PostgreSQL service..."
    ["postgresql_demo_setup_complete"]="PostgreSQL setup for demonstration completed."
    ["setting_up_walg_demo"]="Setting up WAL-G for demonstration..."
    ["walg_demo_setup_complete"]="WAL-G setup for demonstration completed."
    ["bash_version_too_old"]="Bash version is too old. Version 4.0 or newer is required."
    ["bash_version_ok"]="Bash version is OK."
    ["detected_distro"]="Detected distribution"
    ["setup_menu"]="Setup menu"
    ["install_all_deps"]="Install all dependencies (MySQL, PostgreSQL, Docker, WAL-G)"
    ["install_mysql_only"]="Install MySQL and WAL-G only"
    ["install_postgresql_only"]="Install PostgreSQL and WAL-G only"
    ["install_docker_only"]="Install Docker only"
    ["setup_existing"]="Setup existing installations (create users, databases, etc.)"
    ["setup_complete"]="Setup complete!"
    ["run_demo"]="Now you can run the demonstration with"
    
    # MySQL демо
    ["mysql_demo_title"]="MySQL Demonstration"
    ["mysql_not_installed"]="Error: MySQL is not installed"
    ["mysql_install_required"]="MySQL/MariaDB must be installed for this demonstration"
    ["creating_test_db"]="Creating test database"
    ["viewing_data"]="Viewing data in test database"
    ["creating_backup"]="Creating MySQL backup"
    ["listing_backups"]="Listing available backups"
    ["adding_data"]="Adding new data to database"
    ["viewing_updated_data"]="Viewing updated data"
    ["restore_warning"]="This operation will delete current data in MySQL."
    ["continue_restore"]="Continue with restore? (y/n): "
    ["restoring_backup"]="Restoring from backup"
    ["viewing_restored_data"]="Viewing restored data"
    ["mysql_demo_complete"]="MySQL demonstration complete."
    
    # PostgreSQL демо
    ["postgresql_demo_title"]="PostgreSQL Demonstration"
    ["postgresql_not_installed"]="Error: PostgreSQL is not installed"
    ["postgresql_install_required"]="PostgreSQL must be installed for this demonstration"
    ["creating_test_table"]="Creating test table and data"
    ["pg_demo_complete"]="PostgreSQL demonstration complete."
    
    # Расписания
    ["schedule_demo_title"]="Backup Schedule Demonstration"
    ["cron_examples"]="Examples of cron expressions for backups:"
    ["daily_2am"]="Daily at 2:00 AM"
    ["monday_330am"]="Every Monday at 3:30 AM"
    ["every_6_hours"]="Every 6 hours"
    ["first_day_month"]="First day of each month at 4:00 AM"
    ["schedule_command"]="Command to set up schedule:"
    ["crontab_example"]="Example of generated crontab entry:"
    ["backup_mysql_daily"]="# Backup MySQL daily at 2:00 AM"
    ["shell_script_example"]="Example shell script for scheduled backups:"
    
    # Политики хранения
    ["retention_demo_title"]="Retention Policies Demonstration"
    ["available_policies"]="Available retention policies:"
    ["full_backups_policy"]="1. By number of full backups"
    ["days_policy"]="2. By days to keep backups"
    ["count_policy"]="3. By total number of backups"
    ["config_example"]="Example configuration in environment file:"
    ["retention_command"]="Command to apply retention policy:"
    ["retention_logic"]="Retention policy logic:"
    ["retention_logic_1"]="1. If multiple policies are specified, they are combined with OR:"
    ["retention_logic_1_detail"]="   - A backup is retained if it meets ANY of the policies"
    ["retention_logic_2"]="2. Backups are only deleted when retention policy is applied:"
    ["retention_logic_2_detail_1"]="   - Automatically when creating a new backup (if configured)"
    ["retention_logic_2_detail_2"]="   - Manually when running command with --apply-retention flag"
    
    # Docker демо
    ["docker_demo_title"]="Docker Demonstration"
    ["docker_not_installed"]="Error: Docker is not installed"
    ["docker_install_required"]="Docker and Docker Compose must be installed for this demonstration"
    ["docker_not_running"]="Error: Docker daemon is not running"
    ["start_docker_daemon"]="Start Docker daemon and try again"
    ["mysql_container_not_running"]="MySQL container is not running"
    ["start_containers_first"]="Start containers first using 'Start Docker containers' option"
    ["postgres_container_not_running"]="PostgreSQL container is not running"
    ["starting_containers"]="Starting Docker containers"
    ["waiting_for_services"]="Waiting for services to start..."
    ["checking_containers"]="Checking container status"
    ["containers_started"]="Docker containers started."
    ["stopping_containers"]="Stopping Docker containers"
    ["containers_stopped"]="All containers stopped"
    ["stopping_failed"]="Failed to stop all containers"
    ["cleanup_docker"]="Cleaning up Docker resources"
    ["cleanup_warning"]="This operation will delete all containers, images, and volumes created during demonstration."
    ["continue_cleanup"]="Continue with cleanup? (y/n): "
    ["cleanup_cancelled"]="Cleanup cancelled"
    ["docker_cleanup_complete"]="Docker resources cleanup complete"
    
    # Автотесты
    ["autotest_title"]="WALL-BE AUTOMATED TESTING"
    ["running_autotest"]="Running automated tests for wall-be"
    ["log_file"]="Log file"
    ["testing_mysql"]="Testing MySQL"
    ["testing_postgresql"]="Testing PostgreSQL"
    ["finishing_tests"]="Finishing tests"
    ["tests_complete"]="Testing complete!"
    ["detailed_log"]="Detailed test log saved to file"
    ["test_passed"]="Passed"
    ["test_failed"]="Failed"
    ["tests_all_passed"]="All tests passed successfully!"
    ["tests_some_failed"]="Some tests failed! Check the log for details."
    ["test_creating_database"]="Creating test database"
    ["test_adding_data"]="Adding test data"
    ["test_creating_backup"]="Creating backup"
    ["test_listing_backups"]="Listing backups"
    ["test_modifying_data"]="Modifying data"
    ["test_restoring_backup"]="Restoring from backup"
    ["test_verifying_data"]="Verifying restored data"
    ["test_cleanup"]="Cleaning up after tests"
    ["test_create_database"]="Create database"
    ["test_insert_data"]="Insert data"
    ["test_backup"]="Create backup"
    ["test_list_backups"]="List backups"
    ["test_modify_data"]="Modify data"
    ["test_restore"]="Restore backup"
    ["test_verify_data"]="Verify data"
    ["mysql_connection_failed"]="Failed to connect to MySQL"
    ["postgresql_connection_failed"]="Failed to connect to PostgreSQL"
    
    # README
    ["readme_title"]="WALL-BE DEMO DOCUMENTATION"
    ["readme_intro"]="This directory contains scripts for demonstrating wall-be capabilities - a database backup tool based on WAL-G."
    ["running_demo"]="Running the demonstration"
    ["requirements"]="Requirements"
    ["available_demos"]="Available demonstrations"
    ["notes"]="Notes"
    ["troubleshooting"]="Troubleshooting"
    
    # Добавляем новые переводы для WAL-G в демо-режиме
    ["creating_demo_placeholders"]="Creating WAL-G placeholder scripts for demonstration..."
    ["wal_g_setup_complete"]="WAL-G setup for demonstration completed."
)

# Переводы на русском
declare -A TRANSLATIONS_RU
TRANSLATIONS_RU=(
    # Общие строки
    ["demo_title"]="WALL-BE ДЕМОНСТРАЦИЯ"
    ["demo_subtitle"]="Инструмент резервного копирования БД"
    ["press_enter"]="Нажмите Enter для продолжения..."
    ["return_main_menu"]="Нажмите Enter для возврата в главное меню..."
    ["invalid_choice"]="Неверный выбор. Пожалуйста, выберите номер из списка."
    ["exiting"]="Выход из демонстрационного режима."
    ["cleanup"]="Очистка временных файлов..."
    ["cleanup_complete"]="Очистка завершена."
    ["and"]="и"
    
    # Главное меню
    ["select_demo"]="Выберите демонстрацию:"
    ["mysql_demo"]="MySQL/MariaDB"
    ["postgresql_demo"]="PostgreSQL"
    ["schedule_demo"]="Расписания резервного копирования"
    ["retention_demo"]="Политики хранения"
    ["readme_demo"]="СПРАВКА / Помощь"
    ["exit"]="Выход"
    ["enter_number"]="Введите номер [1-7]: "
    
    # run-demo.sh меню
    ["standard_demo"]="Стандартная демонстрация (локальная база данных)"
    ["docker_demo"]="Демонстрация с использованием Docker"
    ["autotest_demo"]="Автоматическое тестирование"
    ["help_option"]="Справка"
    ["setup_dependencies"]="Установка и настройка зависимостей"
    
    # setup_dependencies.sh
    ["setup_dependencies_title"]="УСТАНОВКА ЗАВИСИМОСТЕЙ WALL-BE"
    ["root_required"]="Этот скрипт должен быть запущен с правами root!"
    ["run_as_root"]="Пожалуйста, запустите этот скрипт с правами root:"
    ["installing_common_deps"]="Установка общих зависимостей..."
    ["installing"]="Установка"
    ["already_installed"]="Уже установлено:"
    ["unsupported_distro"]="Неподдерживаемый дистрибутив. Пожалуйста, установите зависимости вручную."
    ["common_deps_installed"]="Общие зависимости установлены."
    ["installing_mysql"]="Установка MySQL/MariaDB..."
    ["mysql_installed"]="MySQL/MariaDB успешно установлен."
    ["mysql_install_failed"]="Не удалось установить MySQL/MariaDB."
    ["installing_postgresql"]="Установка PostgreSQL..."
    ["postgresql_installed"]="PostgreSQL успешно установлен."
    ["postgresql_install_failed"]="Не удалось установить PostgreSQL."
    ["installing_docker"]="Установка Docker..."
    ["docker_installed"]="Docker успешно установлен."
    ["docker_install_failed"]="Не удалось установить Docker."
    ["docker_compose_installed"]="Docker Compose успешно установлен."
    ["docker_compose_install_failed"]="Не удалось установить Docker Compose."
    ["installing_walg"]="Установка WAL-G..."
    ["walg_installed"]="WAL-G успешно установлен."
    ["walg_install_failed"]="Не удалось установить WAL-G."
    ["setting_up_mysql_demo"]="Настройка MySQL для демонстрации..."
    ["starting_mysql"]="Запуск сервиса MySQL..."
    ["mysql_demo_setup_complete"]="Настройка MySQL для демонстрации завершена."
    ["setting_up_postgresql_demo"]="Настройка PostgreSQL для демонстрации..."
    ["starting_postgresql"]="Запуск сервиса PostgreSQL..."
    ["postgresql_demo_setup_complete"]="Настройка PostgreSQL для демонстрации завершена."
    ["setting_up_walg_demo"]="Настройка WAL-G для демонстрации..."
    ["walg_demo_setup_complete"]="Настройка WAL-G для демонстрации завершена."
    ["bash_version_too_old"]="Версия Bash слишком старая. Требуется версия 4.0 или новее."
    ["bash_version_ok"]="Версия Bash подходит."
    ["detected_distro"]="Определен дистрибутив"
    ["setup_menu"]="Меню установки"
    ["install_all_deps"]="Установить все зависимости (MySQL, PostgreSQL, Docker, WAL-G)"
    ["install_mysql_only"]="Установить только MySQL и WAL-G"
    ["install_postgresql_only"]="Установить только PostgreSQL и WAL-G"
    ["install_docker_only"]="Установить только Docker"
    ["setup_existing"]="Настроить существующие установки (создать пользователей, базы данных и т.д.)"
    ["setup_complete"]="Установка завершена!"
    ["run_demo"]="Теперь вы можете запустить демонстрацию с помощью"
    
    # MySQL демо
    ["mysql_demo_title"]="Демонстрация MySQL"
    ["mysql_not_installed"]="Ошибка: MySQL не установлен"
    ["mysql_install_required"]="Для демонстрации MySQL необходимо установить MySQL/MariaDB"
    ["creating_test_db"]="Создание тестовой базы данных"
    ["viewing_data"]="Просмотр данных в тестовой базе данных"
    ["creating_backup"]="Создание резервной копии MySQL"
    ["listing_backups"]="Просмотр списка резервных копий"
    ["adding_data"]="Добавление новых данных в базу"
    ["viewing_updated_data"]="Просмотр обновленных данных"
    ["restore_warning"]="Эта операция удалит текущие данные в MySQL."
    ["continue_restore"]="Продолжить восстановление? (y/n): "
    ["restoring_backup"]="Восстановление из резервной копии"
    ["viewing_restored_data"]="Просмотр восстановленных данных"
    ["mysql_demo_complete"]="Демонстрация MySQL завершена."
    
    # PostgreSQL демо
    ["postgresql_demo_title"]="Демонстрация PostgreSQL"
    ["postgresql_not_installed"]="Ошибка: PostgreSQL не установлен"
    ["postgresql_install_required"]="Для демонстрации PostgreSQL необходимо установить PostgreSQL"
    ["creating_test_table"]="Создание тестовой таблицы и данных"
    ["pg_demo_complete"]="Демонстрация PostgreSQL завершена."
    
    # Расписания
    ["schedule_demo_title"]="Демонстрация настройки расписаний"
    ["cron_examples"]="Примеры cron-выражений для резервного копирования:"
    ["daily_2am"]="Ежедневно в 2:00"
    ["monday_330am"]="Каждый понедельник в 3:30"
    ["every_6_hours"]="Каждые 6 часов"
    ["first_day_month"]="Каждое первое число месяца в 4:00"
    ["schedule_command"]="Команда для настройки расписания:"
    ["crontab_example"]="Пример сгенерированной записи crontab:"
    ["backup_mysql_daily"]="# Резервное копирование MySQL каждый день в 2:00"
    ["shell_script_example"]="Пример shell-скрипта для запуска по расписанию:"
    
    # Политики хранения
    ["retention_demo_title"]="Демонстрация политик хранения"
    ["available_policies"]="Доступные политики хранения:"
    ["full_backups_policy"]="1. По количеству полных резервных копий"
    ["days_policy"]="2. По времени хранения"
    ["count_policy"]="3. По общему количеству резервных копий"
    ["config_example"]="Пример конфигурации в файле окружения:"
    ["retention_command"]="Команда для применения политики хранения:"
    ["retention_logic"]="Логика работы политик хранения:"
    ["retention_logic_1"]="1. Если указано несколько политик, они объединяются через логическое ИЛИ:"
    ["retention_logic_1_detail"]="   - Резервная копия сохраняется, если она соответствует хотя бы одной политике"
    ["retention_logic_2"]="2. Удаление резервных копий происходит только при применении политики хранения:"
    ["retention_logic_2_detail_1"]="   - Автоматически при создании новой резервной копии (если настроено)"
    ["retention_logic_2_detail_2"]="   - Вручную при запуске команды с флагом --apply-retention"
    
    # Docker демо
    ["docker_demo_title"]="Демонстрация Docker"
    ["docker_not_installed"]="Ошибка: Docker не установлен"
    ["docker_install_required"]="Для демонстрации Docker необходимо установить Docker и Docker Compose"
    ["docker_not_running"]="Ошибка: Docker демон не запущен"
    ["start_docker_daemon"]="Запустите Docker демон и попробуйте снова"
    ["mysql_container_not_running"]="Контейнер MySQL не запущен"
    ["start_containers_first"]="Запустите контейнеры с помощью опции 'Запустить Docker контейнеры'"
    ["postgres_container_not_running"]="Контейнер PostgreSQL не запущен"
    ["starting_containers"]="Запуск Docker контейнеров"
    ["waiting_for_services"]="Ожидание запуска сервисов..."
    ["checking_containers"]="Проверка состояния контейнеров"
    ["containers_started"]="Docker контейнеры запущены."
    ["stopping_containers"]="Остановка Docker контейнеров"
    ["containers_stopped"]="Все контейнеры остановлены"
    ["stopping_failed"]="Не удалось остановить все контейнеры"
    ["cleanup_docker"]="Очистка ресурсов Docker"
    ["cleanup_warning"]="Эта операция удалит все контейнеры, образы и тома, созданные в процессе демонстрации."
    ["continue_cleanup"]="Продолжить очистку? (y/n): "
    ["cleanup_cancelled"]="Очистка отменена"
    ["docker_cleanup_complete"]="Очистка ресурсов Docker завершена"
    
    # Автотесты
    ["autotest_title"]="WALL-BE АВТОМАТИЧЕСКОЕ ТЕСТИРОВАНИЕ"
    ["running_autotest"]="Запуск автоматического тестирования wall-be"
    ["log_file"]="Лог файл"
    ["testing_mysql"]="Тестирование MySQL"
    ["testing_postgresql"]="Тестирование PostgreSQL"
    ["finishing_tests"]="Завершение тестирования"
    ["tests_complete"]="Тестирование завершено!"
    ["detailed_log"]="Подробный лог тестирования сохранен в файле"
    ["test_passed"]="Успешно"
    ["test_failed"]="Не пройден"
    ["tests_all_passed"]="Все тесты успешно пройдены!"
    ["tests_some_failed"]="Некоторые тесты не пройдены! Проверьте лог для подробностей."
    ["test_creating_database"]="Создание тестовой базы данных"
    ["test_adding_data"]="Добавление тестовых данных"
    ["test_creating_backup"]="Создание резервной копии"
    ["test_listing_backups"]="Получение списка резервных копий"
    ["test_modifying_data"]="Изменение данных"
    ["test_restoring_backup"]="Восстановление из резервной копии"
    ["test_verifying_data"]="Проверка восстановленных данных"
    ["test_cleanup"]="Очистка после тестов"
    ["test_create_database"]="Создание базы данных"
    ["test_insert_data"]="Вставка данных"
    ["test_backup"]="Создание резервной копии"
    ["test_list_backups"]="Список резервных копий"
    ["test_modify_data"]="Изменение данных"
    ["test_restore"]="Восстановление резервной копии"
    ["test_verify_data"]="Проверка данных"
    ["mysql_connection_failed"]="Не удалось подключиться к MySQL"
    ["postgresql_connection_failed"]="Не удалось подключиться к PostgreSQL"
    
    # README
    ["readme_title"]="ДОКУМЕНТАЦИЯ ПО ДЕМОНСТРАЦИИ WALL-BE"
    ["readme_intro"]="Этот каталог содержит скрипты для демонстрации возможностей wall-be — инструмента для резервного копирования баз данных на основе WAL-G."
    ["running_demo"]="Запуск демонстрации"
    ["requirements"]="Требования"
    ["available_demos"]="Доступные демонстрации"
    ["notes"]="Примечания"
    ["troubleshooting"]="Устранение неполадок"
    
    # Добавляем новые переводы для WAL-G в демо-режиме
    ["creating_demo_placeholders"]="Создание заглушек WAL-G для демонстрации..."
    ["wal_g_setup_complete"]="Настройка WAL-G для демонстрации завершена."
)

# Проверка наличия строк и добавление недостающих
if [ -z "${TRANSLATIONS_EN["setting_up_walg_demo"]}" ]; then
    TRANSLATIONS_EN["setting_up_walg_demo"]="Setting up WAL-G for demonstration..."
fi

if [ -z "${TRANSLATIONS_EN["setting_up_mysql_demo"]}" ]; then
    TRANSLATIONS_EN["setting_up_mysql_demo"]="Setting up MySQL for demonstration..."
fi

if [ -z "${TRANSLATIONS_EN["setting_up_postgresql_demo"]}" ]; then
    TRANSLATIONS_EN["setting_up_postgresql_demo"]="Setting up PostgreSQL for demonstration..."
fi

if [ -z "${TRANSLATIONS_RU["setting_up_walg_demo"]}" ]; then
    TRANSLATIONS_RU["setting_up_walg_demo"]="Настройка WAL-G для демонстрации..."
fi

if [ -z "${TRANSLATIONS_RU["setting_up_mysql_demo"]}" ]; then
    TRANSLATIONS_RU["setting_up_mysql_demo"]="Настройка MySQL для демонстрации..."
fi

if [ -z "${TRANSLATIONS_RU["setting_up_postgresql_demo"]}" ]; then
    TRANSLATIONS_RU["setting_up_postgresql_demo"]="Настройка PostgreSQL для демонстрации..."
fi 