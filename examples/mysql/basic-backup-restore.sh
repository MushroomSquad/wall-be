#!/bin/bash

# Basic MySQL Backup and Restore Example / Пример базового резервного копирования и восстановления MySQL
# This script demonstrates the basic workflow for MySQL backup and restore using wall-be
# Этот скрипт демонстрирует базовый рабочий процесс для резервного копирования и восстановления MySQL с использованием wall-be

# Change to the wall-be directory / Перейти в директорию wall-be
cd "$(dirname "$0")/../.."

# Step 1: Setup WAL-G for MySQL / Шаг 1: Настройка WAL-G для MySQL
echo "Setting up WAL-G for MySQL... / Настройка WAL-G для MySQL..."
./wall-be.sh mysql setup

# Step 2: Configure the backup settings / Шаг 2: Настройка параметров резервного копирования
echo "Configuring backup settings... / Настройка параметров резервного копирования..."
cat > config-mysql.env << EOF
# MySQL connection settings / Настройки подключения к MySQL
WALG_MYSQL_HOST=localhost
WALG_MYSQL_USER=root
WALG_MYSQL_PASSWORD=password
WALG_MYSQL_PORT=3306

# Local file storage / Локальное файловое хранилище
WALG_FILE_PREFIX=/tmp/mysql-backups

# Backup settings / Настройки резервного копирования
WALG_COMPRESSION_METHOD=lz4
WALG_RETENTION_FULL_BACKUPS=3
EOF

# Step 3: Create a MySQL backup / Шаг 3: Создание резервной копии MySQL
echo "Creating MySQL backup... / Создание резервной копии MySQL..."
./wall-be.sh mysql backup

# Step 4: List available backups / Шаг 4: Просмотр доступных резервных копий
echo "Listing available backups... / Просмотр доступных резервных копий..."
./wall-be.sh mysql list

# Step 5: Verify the backup / Шаг 5: Проверка резервной копии
echo "Verifying backup... / Проверка резервной копии..."
./wall-be.sh mysql verify --name LATEST

# Step 6: Restore from backup / Шаг 6: Восстановление из резервной копии
echo "Restoring from backup... / Восстановление из резервной копии..."
./wall-be.sh mysql restore --name LATEST

echo "Example completed successfully! / Пример успешно завершен!" 