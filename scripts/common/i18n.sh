#!/usr/bin/env bash

# i18n.sh - Файл с переводами для скриптов wall-be

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
WALL_BE_LANG="${WALL_BE_LANG:-$(detect_language)}"

# Экспорт переменной языка для всех скриптов
export WALL_BE_LANG

# Функция для получения перевода
translate() {
    local key="$1"
    
    # Если язык русский, вернуть русский перевод
    if [ "$WALL_BE_LANG" = "ru" ]; then
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
    ["error"]="Error"
    ["success"]="Success"
    ["warning"]="Warning"
    ["info"]="Information"
    ["yes"]="Yes"
    ["no"]="No"
    ["continue"]="Continue"
    ["cancel"]="Cancel"
    ["exit"]="Exit"
    ["back"]="Back"
    ["help"]="Help"
    ["version"]="Version"
    ["and"]="and"
    ["loading"]="Loading..."
    ["processing"]="Processing..."
    ["completed"]="Completed"
    ["failed"]="Failed"
    ["not_found"]="not found"
    
    # Сообщения об ошибках
    ["missing_deps"]="Missing required dependencies"
    ["file_not_exists"]="File does not exist"
    ["dir_not_exists"]="Directory does not exist"
    ["config_not_found"]="Config file not found"
    ["config_not_specified"]="Config file not specified"
    ["root_required"]="This script must be run as root or with sudo"
    ["command_failed"]="Command failed"
    ["invalid_option"]="Invalid option"
    ["invalid_argument"]="Invalid argument"
    ["no_backups_found"]="No backups found"
    ["unsupported_db"]="Unsupported database"
    ["unsupported_action"]="Unsupported action"
    ["connection_failed"]="Database connection failed"
    
    # Действия с бэкапами
    ["creating_backup"]="Creating backup"
    ["backup_created"]="Backup created successfully"
    ["backup_failed"]="Backup creation failed"
    ["restore_warning"]="This operation will replace the current database content"
    ["restoring_backup"]="Restoring backup"
    ["backup_restored"]="Backup restored successfully"
    ["restore_failed"]="Backup restoration failed"
    ["listing_backups"]="Listing available backups"
    ["verifying_backup"]="Verifying backup integrity"
    ["backup_verified"]="Backup integrity verified"
    ["verify_failed"]="Backup verification failed"
    
    # Настройка и расписание
    ["setup_title"]="WAL-G Setup"
    ["setup_complete"]="Setup completed successfully"
    ["setup_failed"]="Setup failed"
    ["scheduling_backup"]="Scheduling backup task"
    ["schedule_created"]="Backup schedule created successfully"
    ["schedule_failed"]="Failed to create backup schedule"
    ["retention_policy"]="Retention policy"
    ["applying_retention"]="Applying retention policy"
    ["retention_applied"]="Retention policy applied successfully"
    
    # Статистика и отчеты
    ["backup_size"]="Backup size"
    ["backup_time"]="Backup time"
    ["backup_type"]="Backup type"
    ["backup_date"]="Backup date"
    ["total_backups"]="Total backups"
    ["available_space"]="Available space"
    ["sending_report"]="Sending report"
    ["report_sent"]="Report sent successfully"
    
    # Интерфейс и взаимодействие
    ["confirm_action"]="Are you sure you want to perform this action?"
    ["enter_backup_name"]="Enter backup name"
    ["select_backup"]="Select backup to restore"
    ["operation_cancelled"]="Operation cancelled by user"
    ["press_enter"]="Press Enter to continue"
    
    # Конфигурация
    ["config_loaded"]="Configuration loaded from"
    ["config_created"]="Configuration file created"
    ["edit_config_warning"]="Edit it before using!"
    
    # Логирование
    ["log_started"]="Started"
    ["log_completed"]="Completed"
    ["log_backup_started"]="Backup started"
    ["log_backup_completed"]="Backup completed"
    ["log_restore_started"]="Restore started"
    ["log_restore_completed"]="Restore completed"
    ["log_error"]="Error occurred"
    
    # MySQL/MariaDB
    ["mysql_connecting"]="Connecting to MySQL server"
    ["mysql_connected"]="Connected to MySQL server"
    ["mysql_backing_up"]="Backing up MySQL database"
    ["mysql_restoring"]="Restoring MySQL database"
    ["mysql_backup_complete"]="MySQL backup completed"
    ["mysql_restore_complete"]="MySQL restore completed"
    
    # PostgreSQL
    ["pg_connecting"]="Connecting to PostgreSQL server"
    ["pg_connected"]="Connected to PostgreSQL server"
    ["pg_backing_up"]="Backing up PostgreSQL database"
    ["pg_restoring"]="Restoring PostgreSQL database"
    ["pg_backup_complete"]="PostgreSQL backup completed"
    ["pg_restore_complete"]="PostgreSQL restore completed"
)

# Переводы на русском
declare -A TRANSLATIONS_RU
TRANSLATIONS_RU=(
    # Общие строки
    ["error"]="Ошибка"
    ["success"]="Успешно"
    ["warning"]="Предупреждение"
    ["info"]="Информация"
    ["yes"]="Да"
    ["no"]="Нет"
    ["continue"]="Продолжить"
    ["cancel"]="Отмена"
    ["exit"]="Выход"
    ["back"]="Назад"
    ["help"]="Справка"
    ["version"]="Версия"
    ["and"]="и"
    ["loading"]="Загрузка..."
    ["processing"]="Обработка..."
    ["completed"]="Завершено"
    ["failed"]="Ошибка"
    ["not_found"]="не найден"
    
    # Сообщения об ошибках
    ["missing_deps"]="Отсутствуют необходимые зависимости"
    ["file_not_exists"]="Файл не существует"
    ["dir_not_exists"]="Директория не существует"
    ["config_not_found"]="Файл конфигурации не найден"
    ["config_not_specified"]="Не указан файл конфигурации"
    ["root_required"]="Этот скрипт должен быть запущен с правами root или через sudo"
    ["command_failed"]="Ошибка выполнения команды"
    ["invalid_option"]="Неверная опция"
    ["invalid_argument"]="Неверный аргумент"
    ["no_backups_found"]="Резервные копии не найдены"
    ["unsupported_db"]="Неподдерживаемая база данных"
    ["unsupported_action"]="Неподдерживаемое действие"
    ["connection_failed"]="Ошибка подключения к базе данных"
    
    # Действия с бэкапами
    ["creating_backup"]="Создание резервной копии"
    ["backup_created"]="Резервная копия успешно создана"
    ["backup_failed"]="Ошибка создания резервной копии"
    ["restore_warning"]="Эта операция заменит текущее содержимое базы данных"
    ["restoring_backup"]="Восстановление из резервной копии"
    ["backup_restored"]="Восстановление из резервной копии успешно завершено"
    ["restore_failed"]="Ошибка восстановления из резервной копии"
    ["listing_backups"]="Просмотр доступных резервных копий"
    ["verifying_backup"]="Проверка целостности резервной копии"
    ["backup_verified"]="Целостность резервной копии подтверждена"
    ["verify_failed"]="Ошибка проверки резервной копии"
    
    # Настройка и расписание
    ["setup_title"]="Настройка WAL-G"
    ["setup_complete"]="Настройка успешно завершена"
    ["setup_failed"]="Ошибка настройки"
    ["scheduling_backup"]="Настройка расписания резервного копирования"
    ["schedule_created"]="Расписание резервного копирования успешно создано"
    ["schedule_failed"]="Ошибка создания расписания резервного копирования"
    ["retention_policy"]="Политика хранения"
    ["applying_retention"]="Применение политики хранения"
    ["retention_applied"]="Политика хранения успешно применена"
    
    # Статистика и отчеты
    ["backup_size"]="Размер резервной копии"
    ["backup_time"]="Время создания резервной копии"
    ["backup_type"]="Тип резервной копии"
    ["backup_date"]="Дата создания резервной копии"
    ["total_backups"]="Всего резервных копий"
    ["available_space"]="Доступное пространство"
    ["sending_report"]="Отправка отчета"
    ["report_sent"]="Отчет успешно отправлен"
    
    # Интерфейс и взаимодействие
    ["confirm_action"]="Вы уверены, что хотите выполнить это действие?"
    ["enter_backup_name"]="Введите имя резервной копии"
    ["select_backup"]="Выберите резервную копию для восстановления"
    ["operation_cancelled"]="Операция отменена пользователем"
    ["press_enter"]="Нажмите Enter для продолжения"
    
    # Конфигурация
    ["config_loaded"]="Конфигурация загружена из"
    ["config_created"]="Создан файл конфигурации"
    ["edit_config_warning"]="Отредактируйте его перед использованием!"
    
    # Логирование
    ["log_started"]="Начало"
    ["log_completed"]="Завершено"
    ["log_backup_started"]="Начато создание резервной копии"
    ["log_backup_completed"]="Создание резервной копии завершено"
    ["log_restore_started"]="Начато восстановление из резервной копии"
    ["log_restore_completed"]="Восстановление из резервной копии завершено"
    ["log_error"]="Произошла ошибка"
    
    # MySQL/MariaDB
    ["mysql_connecting"]="Подключение к серверу MySQL"
    ["mysql_connected"]="Подключено к серверу MySQL"
    ["mysql_backing_up"]="Создание резервной копии базы данных MySQL"
    ["mysql_restoring"]="Восстановление базы данных MySQL"
    ["mysql_backup_complete"]="Создание резервной копии MySQL завершено"
    ["mysql_restore_complete"]="Восстановление MySQL завершено"
    
    # PostgreSQL
    ["pg_connecting"]="Подключение к серверу PostgreSQL"
    ["pg_connected"]="Подключено к серверу PostgreSQL"
    ["pg_backing_up"]="Создание резервной копии базы данных PostgreSQL"
    ["pg_restoring"]="Восстановление базы данных PostgreSQL"
    ["pg_backup_complete"]="Создание резервной копии PostgreSQL завершено"
    ["pg_restore_complete"]="Восстановление PostgreSQL завершено"
) 