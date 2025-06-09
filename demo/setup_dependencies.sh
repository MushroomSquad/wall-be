#!/usr/bin/env bash

# Загрузка файла с переводами
source "$(dirname "$0")/i18n.sh"

# Переменные для цветного вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RESET='\033[0m'

# Определение дистрибутива Linux
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
    elif [ -f /etc/debian_version ]; then
        DISTRO="debian"
    elif [ -f /etc/redhat-release ]; then
        DISTRO="rhel"
    else
        DISTRO="unknown"
    fi
    echo $DISTRO
}

# Проверка, запущен ли скрипт с правами root
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo -e "${RED}$(t root_required)${RESET}"
        return 1
    fi
    return 0
}

# Установка общих зависимостей для всех дистрибутивов
install_common_deps() {
    echo -e "${YELLOW}$(t installing_common_deps)${RESET}"
    
    # Проверка и установка curl
    if ! command -v curl &> /dev/null; then
        echo "$(t installing) curl..."
        if [[ "$DISTRO" == "debian" || "$DISTRO" == "ubuntu" ]]; then
            apt-get update && apt-get install -y curl
        elif [[ "$DISTRO" == "fedora" || "$DISTRO" == "rhel" || "$DISTRO" == "centos" ]]; then
            dnf install -y curl || yum install -y curl
        elif [[ "$DISTRO" == "arch" || "$DISTRO" == "manjaro" ]]; then
            pacman -Sy --noconfirm curl
        else
            echo -e "${RED}$(t unsupported_distro)${RESET}"
            return 1
        fi
    else
        echo "$(t already_installed) curl"
    fi
    
    # Проверка и установка wget
    if ! command -v wget &> /dev/null; then
        echo "$(t installing) wget..."
        if [[ "$DISTRO" == "debian" || "$DISTRO" == "ubuntu" ]]; then
            apt-get update && apt-get install -y wget
        elif [[ "$DISTRO" == "fedora" || "$DISTRO" == "rhel" || "$DISTRO" == "centos" ]]; then
            dnf install -y wget || yum install -y wget
        elif [[ "$DISTRO" == "arch" || "$DISTRO" == "manjaro" ]]; then
            pacman -Sy --noconfirm wget
        else
            echo -e "${RED}$(t unsupported_distro)${RESET}"
            return 1
        fi
    else
        echo "$(t already_installed) wget"
    fi
    
    # Проверка и установка tar
    if ! command -v tar &> /dev/null; then
        echo "$(t installing) tar..."
        if [[ "$DISTRO" == "debian" || "$DISTRO" == "ubuntu" ]]; then
            apt-get update && apt-get install -y tar
        elif [[ "$DISTRO" == "fedora" || "$DISTRO" == "rhel" || "$DISTRO" == "centos" ]]; then
            dnf install -y tar || yum install -y tar
        elif [[ "$DISTRO" == "arch" || "$DISTRO" == "manjaro" ]]; then
            pacman -Sy --noconfirm tar
        else
            echo -e "${RED}$(t unsupported_distro)${RESET}"
            return 1
        fi
    else
        echo "$(t already_installed) tar"
    fi
    
    # Проверка и установка git
    if ! command -v git &> /dev/null; then
        echo "$(t installing) git..."
        if [[ "$DISTRO" == "debian" || "$DISTRO" == "ubuntu" ]]; then
            apt-get update && apt-get install -y git
        elif [[ "$DISTRO" == "fedora" || "$DISTRO" == "rhel" || "$DISTRO" == "centos" ]]; then
            dnf install -y git || yum install -y git
        elif [[ "$DISTRO" == "arch" || "$DISTRO" == "manjaro" ]]; then
            pacman -Sy --noconfirm git
        else
            echo -e "${RED}$(t unsupported_distro)${RESET}"
            return 1
        fi
    else
        echo "$(t already_installed) git"
    fi
    
    echo -e "${GREEN}$(t common_deps_installed)${RESET}"
    return 0
}

# Установка MySQL/MariaDB
install_mysql() {
    if command -v mysql &> /dev/null; then
        echo "$(t already_installed) MySQL/MariaDB"
        return 0
    fi
    
    echo -e "${YELLOW}$(t installing_mysql)${RESET}"
    
    if [[ "$DISTRO" == "debian" || "$DISTRO" == "ubuntu" ]]; then
        apt-get update
        apt-get install -y mariadb-server mariadb-client
        systemctl enable mariadb
        systemctl start mariadb
        mysql_secure_installation
    elif [[ "$DISTRO" == "fedora" || "$DISTRO" == "rhel" || "$DISTRO" == "centos" ]]; then
        dnf install -y mariadb-server mariadb || yum install -y mariadb-server mariadb
        systemctl enable mariadb
        systemctl start mariadb
        mysql_secure_installation
    elif [[ "$DISTRO" == "arch" || "$DISTRO" == "manjaro" ]]; then
        pacman -Sy --noconfirm mariadb
        mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
        systemctl enable mariadb
        systemctl start mariadb
        mysql_secure_installation
    else
        echo -e "${RED}$(t unsupported_distro)${RESET}"
        return 1
    fi
    
    # Проверяем успешность установки
    if command -v mysql &> /dev/null; then
        echo -e "${GREEN}$(t mysql_installed)${RESET}"
        return 0
    else
        echo -e "${RED}$(t mysql_install_failed)${RESET}"
        return 1
    fi
}

# Установка PostgreSQL
install_postgresql() {
    if command -v psql &> /dev/null; then
        echo "$(t already_installed) PostgreSQL"
        return 0
    fi
    
    echo -e "${YELLOW}$(t installing_postgresql)${RESET}"
    
    if [[ "$DISTRO" == "debian" || "$DISTRO" == "ubuntu" ]]; then
        apt-get update
        apt-get install -y postgresql postgresql-contrib
        systemctl enable postgresql
        systemctl start postgresql
    elif [[ "$DISTRO" == "fedora" || "$DISTRO" == "rhel" || "$DISTRO" == "centos" ]]; then
        dnf install -y postgresql-server postgresql-contrib || yum install -y postgresql-server postgresql-contrib
        postgresql-setup --initdb
        systemctl enable postgresql
        systemctl start postgresql
    elif [[ "$DISTRO" == "arch" || "$DISTRO" == "manjaro" ]]; then
        pacman -Sy --noconfirm postgresql
        su - postgres -c "initdb -D /var/lib/postgres/data"
        systemctl enable postgresql
        systemctl start postgresql
    else
        echo -e "${RED}$(t unsupported_distro)${RESET}"
        return 1
    fi
    
    # Проверяем успешность установки
    if command -v psql &> /dev/null; then
        echo -e "${GREEN}$(t postgresql_installed)${RESET}"
        return 0
    else
        echo -e "${RED}$(t postgresql_install_failed)${RESET}"
        return 1
    fi
}

# Установка Docker и Docker Compose
install_docker() {
    if command -v docker &> /dev/null && command -v docker-compose &> /dev/null; then
        echo "$(t already_installed) Docker $(t and) Docker Compose"
        return 0
    fi
    
    echo -e "${YELLOW}$(t installing_docker)${RESET}"
    
    if [[ "$DISTRO" == "debian" || "$DISTRO" == "ubuntu" ]]; then
        apt-get update
        apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
        curl -fsSL https://download.docker.com/linux/$DISTRO/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/$DISTRO $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
        apt-get update
        apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
        usermod -aG docker $SUDO_USER
    elif [[ "$DISTRO" == "fedora" ]]; then
        dnf -y install dnf-plugins-core
        dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
        dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
        systemctl enable docker
        systemctl start docker
        usermod -aG docker $SUDO_USER
    elif [[ "$DISTRO" == "rhel" || "$DISTRO" == "centos" ]]; then
        yum install -y yum-utils
        yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
        systemctl enable docker
        systemctl start docker
        usermod -aG docker $SUDO_USER
    elif [[ "$DISTRO" == "arch" || "$DISTRO" == "manjaro" ]]; then
        pacman -Sy --noconfirm docker docker-compose
        systemctl enable docker
        systemctl start docker
        usermod -aG docker $SUDO_USER
    else
        echo -e "${RED}$(t unsupported_distro)${RESET}"
        return 1
    fi
    
    # Проверяем успешность установки
    if command -v docker &> /dev/null; then
        echo -e "${GREEN}$(t docker_installed)${RESET}"
        
        # Устанавливаем Docker Compose, если он не был установлен
        if ! command -v docker-compose &> /dev/null && ! command -v docker compose &> /dev/null; then
            echo "$(t installing) Docker Compose..."
            curl -L "https://github.com/docker/compose/releases/download/v2.16.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
            chmod +x /usr/local/bin/docker-compose
            
            if command -v docker-compose &> /dev/null || command -v docker compose &> /dev/null; then
                echo -e "${GREEN}$(t docker_compose_installed)${RESET}"
            else
                echo -e "${RED}$(t docker_compose_install_failed)${RESET}"
                return 1
            fi
        else
            echo "$(t already_installed) Docker Compose"
        fi
        
        return 0
    else
        echo -e "${RED}$(t docker_install_failed)${RESET}"
        return 1
    fi
}

# Установка WAL-G
install_walg() {
    local walg_dir="/usr/local/bin"
    
    if [ -f "$walg_dir/wal-g" ]; then
        echo "$(t already_installed) WAL-G"
        return 0
    fi
    
    echo -e "${YELLOW}$(t installing_walg)${RESET}"
    
    # Установка зависимостей для WAL-G
    if [[ "$DISTRO" == "debian" || "$DISTRO" == "ubuntu" ]]; then
        apt-get update
        apt-get install -y libpq-dev liblzo2-dev
    elif [[ "$DISTRO" == "fedora" || "$DISTRO" == "rhel" || "$DISTRO" == "centos" ]]; then
        dnf install -y postgresql-devel lzo-devel || yum install -y postgresql-devel lzo-devel
    elif [[ "$DISTRO" == "arch" || "$DISTRO" == "manjaro" ]]; then
        pacman -Sy --noconfirm postgresql-libs lzo
    else
        echo -e "${RED}$(t unsupported_distro)${RESET}"
        return 1
    fi
    
    # Скачиваем и устанавливаем WAL-G
    local temp_dir=$(mktemp -d)
    cd $temp_dir
    
    # Определяем архитектуру
    local arch=$(uname -m)
    if [[ "$arch" == "x86_64" ]]; then
        arch="amd64"
    elif [[ "$arch" == "aarch64" ]]; then
        arch="arm64"
    fi
    
    # Скачиваем последнюю версию WAL-G для MySQL
    echo "$(t downloading) WAL-G for MySQL..."
    curl -L "https://github.com/wal-g/wal-g/releases/latest/download/wal-g-mysql-ubuntu-$arch.tar.gz" -o wal-g-mysql.tar.gz
    
    # Скачиваем последнюю версию WAL-G для PostgreSQL
    echo "$(t downloading) WAL-G for PostgreSQL..."
    curl -L "https://github.com/wal-g/wal-g/releases/latest/download/wal-g-pg-ubuntu-$arch.tar.gz" -o wal-g-pg.tar.gz
    
    # Распаковываем и устанавливаем WAL-G для MySQL
    echo "$(t extracting) WAL-G for MySQL..."
    tar -xzf wal-g-mysql.tar.gz
    cp wal-g-mysql /usr/local/bin/wal-g-mysql
    chmod +x /usr/local/bin/wal-g-mysql
    
    # Распаковываем и устанавливаем WAL-G для PostgreSQL
    echo "$(t extracting) WAL-G for PostgreSQL..."
    tar -xzf wal-g-pg.tar.gz
    cp wal-g-pg /usr/local/bin/wal-g-pg
    chmod +x /usr/local/bin/wal-g-pg
    
    # Создаем символические ссылки для общей команды
    ln -sf /usr/local/bin/wal-g-pg /usr/local/bin/wal-g
    
    # Проверяем успешность установки
    if [ -f "/usr/local/bin/wal-g-mysql" ] && [ -f "/usr/local/bin/wal-g-pg" ]; then
        echo -e "${GREEN}$(t walg_installed)${RESET}"
        rm -rf $temp_dir
        return 0
    else
        echo -e "${RED}$(t walg_install_failed)${RESET}"
        rm -rf $temp_dir
        return 1
    fi
}

# Настройка пользователя и базы данных MySQL для демонстрации
setup_mysql_demo() {
    echo -e "${YELLOW}$(t setting_up_mysql_demo)${RESET}"
    
    # Проверяем, запущен ли MySQL
    if ! systemctl is-active --quiet mariadb && ! systemctl is-active --quiet mysql; then
        echo "$(t starting_mysql)"
        systemctl start mariadb || systemctl start mysql
    fi
    
    # Создаем демо-пользователя и базу данных
    mysql -u root -e "CREATE USER IF NOT EXISTS 'wall_be'@'localhost' IDENTIFIED BY 'wall_be_pass';"
    mysql -u root -e "CREATE DATABASE IF NOT EXISTS wall_be_demo;"
    mysql -u root -e "GRANT ALL PRIVILEGES ON wall_be_demo.* TO 'wall_be'@'localhost';"
    mysql -u root -e "FLUSH PRIVILEGES;"
    
    echo -e "${GREEN}$(t mysql_demo_setup_complete)${RESET}"
    return 0
}

# Настройка пользователя и базы данных PostgreSQL для демонстрации
setup_postgresql_demo() {
    echo -e "${YELLOW}$(t setting_up_postgresql_demo)${RESET}"
    
    # Проверяем, запущен ли PostgreSQL
    if ! systemctl is-active --quiet postgresql; then
        echo "$(t starting_postgresql)"
        systemctl start postgresql
    fi
    
    # Создаем демо-пользователя и базу данных
    su - postgres -c "psql -c \"CREATE USER wall_be WITH PASSWORD 'wall_be_pass';\""
    su - postgres -c "psql -c \"CREATE DATABASE wall_be_demo OWNER wall_be;\""
    
    echo -e "${GREEN}$(t postgresql_demo_setup_complete)${RESET}"
    return 0
}

# Настройка WAL-G для демонстрации
setup_walg_demo() {
    echo -e "${YELLOW}$(t setting_up_walg_demo)${RESET}"
    
    # Создаем директорию для конфигурации WAL-G
    mkdir -p /etc/wal-g.d
    
    # Создаем конфигурационный файл для MySQL
    cat > /etc/wal-g.d/mysql.conf << EOF
WALG_MYSQL_HOST=localhost
WALG_MYSQL_USER=wall_be
WALG_MYSQL_PASSWORD=wall_be_pass
WALG_MYSQL_DATABASE=wall_be_demo
WALG_MYSQL_BINPATH=/usr/local/bin/wal-g-mysql
WALG_FILE_PREFIX=file:///var/lib/wall-be/backups/mysql
WALG_COMPRESSION_METHOD=lz4
WALG_RETENTION_FULL_BACKUPS=5
EOF

    # Создаем конфигурационный файл для PostgreSQL
    cat > /etc/wal-g.d/postgresql.conf << EOF
PGHOST=localhost
PGUSER=wall_be
PGPASSWORD=wall_be_pass
PGDATABASE=wall_be_demo
WALG_PG_BINPATH=/usr/local/bin/wal-g-pg
WALG_FILE_PREFIX=file:///var/lib/wall-be/backups/postgresql
WALG_COMPRESSION_METHOD=lz4
WALG_RETENTION_FULL_BACKUPS=5
EOF

    # Создаем директорию для бэкапов
    mkdir -p /var/lib/wall-be/backups/mysql /var/lib/wall-be/backups/postgresql
    chmod -R 777 /var/lib/wall-be
    
    echo -e "${GREEN}$(t walg_demo_setup_complete)${RESET}"
    return 0
}

# Функция для проверки и установки Bash 4.0+
check_bash_version() {
    local version=$(bash --version | head -n 1 | sed -E 's/.*version ([0-9]+).*/\1/')
    
    if [ "$version" -lt 4 ]; then
        echo -e "${RED}$(t bash_version_too_old)${RESET}"
        return 1
    else
        echo -e "${GREEN}$(t bash_version_ok)${RESET}"
        return 0
    fi
}

# Основная функция
main() {
    clear
    echo -e "${GREEN}$(t setup_dependencies_title)${RESET}"
    echo "========================================"
    echo ""
    
    # Проверяем, запущен ли скрипт с правами root
    if ! check_root; then
        echo "$(t run_as_root)"
        echo "sudo $0"
        exit 1
    fi
    
    # Определяем дистрибутив
    DISTRO=$(detect_distro)
    echo "$(t detected_distro): $DISTRO"
    
    # Проверяем версию Bash
    if ! check_bash_version; then
        exit 1
    fi
    
    # Меню установки
    echo ""
    echo "$(t setup_menu):"
    echo "1. $(t install_all_deps)"
    echo "2. $(t install_mysql_only)"
    echo "3. $(t install_postgresql_only)"
    echo "4. $(t install_docker_only)"
    echo "5. $(t setup_existing)"
    echo "6. $(t exit)"
    echo ""
    
    read -p "$(t enter_number) " choice
    
    case $choice in
        1)
            install_common_deps
            install_mysql
            install_postgresql
            install_docker
            install_walg
            setup_mysql_demo
            setup_postgresql_demo
            setup_walg_demo
            ;;
        2)
            install_common_deps
            install_mysql
            install_walg
            setup_mysql_demo
            setup_walg_demo
            ;;
        3)
            install_common_deps
            install_postgresql
            install_walg
            setup_postgresql_demo
            setup_walg_demo
            ;;
        4)
            install_common_deps
            install_docker
            ;;
        5)
            setup_mysql_demo
            setup_postgresql_demo
            setup_walg_demo
            ;;
        6)
            echo "$(t exiting)"
            exit 0
            ;;
        *)
            echo "$(t invalid_choice)"
            exit 1
            ;;
    esac
    
    echo ""
    echo -e "${GREEN}$(t setup_complete)${RESET}"
    echo "$(t run_demo):"
    echo "./run-demo.sh"
    
    exit 0
}

# Запуск основной функции
main 