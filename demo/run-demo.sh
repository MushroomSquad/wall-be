#!/usr/bin/env bash

# Загрузка файла с переводами
source "$(dirname "$0")/i18n.sh"

# run-demo.sh - Скрипт-обертка для запуска всех демонстраций wall-be

# Настройка терминала
set -e
TERM=xterm-256color

# Цвета и стили
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
RESET='\033[0m'

# Переменные конфигурации
DEMO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Функция для отображения заголовка
show_header() {
    clear
    echo -e "\e[1m$(t demo_title)\e[0m"
    echo -e "\e[3m$(t demo_subtitle)\e[0m"
    echo "========================================"
    echo ""
}

# Функция ожидания нажатия Enter для продолжения
press_enter() {
    local message="${1:-Нажмите Enter для продолжения...}"
    echo -e "${YELLOW}$message${RESET}"
    read -r
}

# Функция отображения справки
show_help() {
    show_header
    
    if [ "$DEMO_LANG" = "ru" ]; then
        echo -e "\e[1mИспользование:\e[0m $0 [опция]"
        echo ""
        echo -e "\e[1mДоступные опции:\e[0m"
        echo "  --help         Показать эту справку"
        echo "  --standard     Запустить стандартную демонстрацию (локальная база данных)"
        echo "  --docker       Запустить демонстрацию с использованием Docker"
        echo "  --autotest     Запустить автоматическое тестирование всех функций"
        echo "  --setup        Установить и настроить зависимости"
        echo ""
        echo "Если опция не указана, будет показано меню выбора."
    else
        echo -e "\e[1mUsage:\e[0m $0 [option]"
        echo ""
        echo -e "\e[1mAvailable options:\e[0m"
        echo "  --help         Show this help"
        echo "  --standard     Run standard demonstration (local database)"
        echo "  --docker       Run demonstration using Docker"
        echo "  --autotest     Run automated testing of all functions"
        echo "  --setup        Install and configure dependencies"
        echo ""
        echo "If no option is specified, a selection menu will be shown."
    fi
    
    echo ""
    read -p "$(t press_enter)" _
    exit 0
}

# Функция для вывода меню выбора демонстрации
show_menu() {
    show_header
    
    if [ "$DEMO_LANG" = "ru" ]; then
        echo -e "\e[1mВыберите тип демонстрации:\e[0m"
    else
        echo -e "\e[1mSelect demonstration type:\e[0m"
    fi
    
    echo ""
    echo "1) $(t standard_demo)"
    echo "2) $(t docker_demo)"
    echo "3) $(t autotest_demo)"
    echo "4) $(t setup_dependencies)"
    echo "5) $(t help_option)"
    echo "6) $(t exit)"
    echo ""
    
    read -p "$(t enter_number) " choice
    
    case $choice in
        1)
            "$DEMO_DIR/demo.sh"
            ;;
        2)
            "$DEMO_DIR/docker-demo.sh"
            ;;
        3)
            "$DEMO_DIR/autotest.sh"
            read -p "$(t return_main_menu)" _
            show_menu
            ;;
        4)
            # Запуск скрипта установки зависимостей
            sudo "$DEMO_DIR/setup_dependencies.sh"
            read -p "$(t return_main_menu)" _
            show_menu
            ;;
        5)
            show_help
            ;;
        6)
            echo "$(t exiting)"
            exit 0
            ;;
        *)
            echo "$(t invalid_choice)"
            read -p "$(t press_enter)" _
            show_menu
            ;;
    esac
}

# Проверка аргументов командной строки
if [ "$#" -gt 0 ]; then
    case "$1" in
        --help)
            show_help
            ;;
        --standard)
            "$DEMO_DIR/demo.sh"
            ;;
        --docker)
            "$DEMO_DIR/docker-demo.sh"
            ;;
        --autotest)
            "$DEMO_DIR/autotest.sh"
            ;;
        --setup)
            sudo "$DEMO_DIR/setup_dependencies.sh"
            ;;
        *)
            if [ "$DEMO_LANG" = "ru" ]; then
                echo -e "\e[31mНеизвестная опция: $1\e[0m"
            else
                echo -e "\e[31mUnknown option: $1\e[0m"
            fi
            show_help
            ;;
    esac
else
    # Если аргументы не указаны, показываем меню
    show_menu
fi 