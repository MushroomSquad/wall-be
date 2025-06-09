#!/usr/bin/env bash

# Загружаем переводы, если они еще не загружены
if [ -z "$DEMO_LANG" ]; then
  source "$(dirname "$0")/i18n.sh"
fi

# Функция для отображения README в зависимости от языка
show_readme() {
  clear
  echo "$(t readme_title)"
  echo "========================================"
  echo ""
  echo "$(t readme_intro)"
  echo ""
  
  echo "## $(t running_demo)"
  echo ""
  if [ "$DEMO_LANG" = "ru" ]; then
    echo "1. Запустите скрипт demo.sh из директории demo:"
    echo "   ./demo.sh"
    echo ""
    echo "2. Или с указанием языка (en - английский, ru - русский):"
    echo "   DEMO_LANG=ru ./demo.sh"
    echo ""
    echo "3. Для запуска демонстрации с Docker:"
    echo "   ./docker-demo.sh"
    echo ""
  else
    echo "1. Run the demo.sh script from the demo directory:"
    echo "   ./demo.sh"
    echo ""
    echo "2. Or specify language (en - English, ru - Russian):"
    echo "   DEMO_LANG=en ./demo.sh"
    echo ""
    echo "3. To run the demonstration with Docker:"
    echo "   ./docker-demo.sh"
    echo ""
  fi
  
  echo "## $(t requirements)"
  echo ""
  if [ "$DEMO_LANG" = "ru" ]; then
    echo "* Для локальной демонстрации: MySQL/MariaDB или PostgreSQL"
    echo "* Для Docker-демонстрации: Docker и Docker Compose"
    echo "* bash 4.0+ (для ассоциативных массивов)"
    echo ""
  else
    echo "* For local demonstration: MySQL/MariaDB or PostgreSQL"
    echo "* For Docker demonstration: Docker and Docker Compose"
    echo "* bash 4.0+ (for associative arrays)"
    echo ""
  fi
  
  echo "## $(t available_demos)"
  echo ""
  if [ "$DEMO_LANG" = "ru" ]; then
    echo "1. **MySQL/MariaDB** - демонстрирует создание и восстановление резервных копий для MySQL/MariaDB"
    echo "2. **PostgreSQL** - демонстрирует работу с PostgreSQL (если установлен)"
    echo "3. **Расписания резервного копирования** - примеры настройки расписаний"
    echo "4. **Политики хранения** - показывает настройку политик хранения резервных копий"
    echo "5. **Docker** - запуск демонстрации в контейнерах Docker"
    echo "6. **Автотесты** - запуск автоматических тестов"
    echo ""
  else
    echo "1. **MySQL/MariaDB** - demonstrates creating and restoring backups for MySQL/MariaDB"
    echo "2. **PostgreSQL** - demonstrates working with PostgreSQL (if installed)"
    echo "3. **Backup Scheduling** - examples of setting up backup schedules"
    echo "4. **Retention Policies** - shows how to configure backup retention policies"
    echo "5. **Docker** - run the demonstration in Docker containers"
    echo "6. **Automated Tests** - run automated tests"
    echo ""
  fi
  
  echo "## $(t notes)"
  echo ""
  if [ "$DEMO_LANG" = "ru" ]; then
    echo "* Демо-скрипты создают временные базы данных, не затрагивая существующие"
    echo "* Docker-демонстрация не требует локально установленных баз данных"
    echo "* Для выхода из демонстрации в любой момент нажмите Ctrl+C"
    echo ""
  else
    echo "* Demo scripts create temporary databases and don't affect existing ones"
    echo "* Docker demonstration doesn't require locally installed databases"
    echo "* To exit the demonstration at any time, press Ctrl+C"
    echo ""
  fi
  
  echo "## $(t troubleshooting)"
  echo ""
  if [ "$DEMO_LANG" = "ru" ]; then
    echo "* Если у вас возникли проблемы с правами доступа при запуске скриптов:"
    echo "  chmod +x *.sh"
    echo ""
    echo "* Для проблем с Docker убедитесь, что сервис Docker запущен и у вас"
    echo "  есть права на управление контейнерами"
    echo ""
    echo "* При проблемах с демонстрацией MySQL/PostgreSQL проверьте, что"
    echo "  соответствующая база данных установлена и запущена"
  else
    echo "* If you have permission issues when running scripts:"
    echo "  chmod +x *.sh"
    echo ""
    echo "* For Docker issues, make sure the Docker service is running and you have"
    echo "  permissions to manage containers"
    echo ""
    echo "* If you have issues with MySQL/PostgreSQL demonstrations, check that"
    echo "  the corresponding database is installed and running"
  fi
  
  echo ""
  echo "========================================"
  read -p "$(t return_main_menu)" _
}

# Если скрипт запущен напрямую, показать README
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  show_readme
fi 