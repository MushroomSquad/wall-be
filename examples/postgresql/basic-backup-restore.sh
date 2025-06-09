#!/bin/bash

# Basic PostgreSQL Backup and Restore Example / Пример базового резервного копирования и восстановления PostgreSQL
# This script demonstrates the basic workflow for PostgreSQL backup and restore using wall-be
# Этот скрипт демонстрирует базовый рабочий процесс для резервного копирования и восстановления PostgreSQL с использованием wall-be

# Change to the wall-be directory / Перейти в директорию wall-be
cd "$(dirname "$0")/../.."

# Step 1: Setup WAL-G for PostgreSQL / Шаг 1: Настройка WAL-G для PostgreSQL
echo "Setting up WAL-G for PostgreSQL... / Настройка WAL-G для PostgreSQL..."
./wall-be.sh postgresql setup

# Step 2: Configure the backup settings / Шаг 2: Настройка параметров резервного копирования
echo "Configuring backup settings... / Настройка параметров резервного копирования..."
cat > config-postgresql.env << EOF
# PostgreSQL connection settings / Настройки подключения к PostgreSQL
PGHOST=localhost
PGUSER=postgres
PGPASSWORD=postgres
PGPORT=5432
PGDATABASE=postgres
PGDATA=/var/lib/postgresql/data

# Local file storage / Локальное файловое хранилище
WALG_FILE_PREFIX=/tmp/postgresql-backups

# Backup settings / Настройки резервного копирования
WALG_COMPRESSION_METHOD=lz4
WALG_RETENTION_FULL_BACKUPS=3
EOF

# Step 3: Create a PostgreSQL backup / Шаг 3: Создание резервной копии PostgreSQL
echo "Creating PostgreSQL backup... / Создание резервной копии PostgreSQL..."
./wall-be.sh postgresql backup

# Step 4: List available backups / Шаг 4: Просмотр доступных резервных копий
echo "Listing available backups... / Просмотр доступных резервных копий..."
./wall-be.sh postgresql list

# Step 5: Verify the backup / Шаг 5: Проверка резервной копии
echo "Verifying backup... / Проверка резервной копии..."
./wall-be.sh postgresql verify --name LATEST

# Step 6: Restore from backup / Шаг 6: Восстановление из резервной копии
echo "Restoring from backup... / Восстановление из резервной копии..."
./wall-be.sh postgresql restore --name LATEST

# Step 7: Point-in-time recovery (if WAL archiving is enabled) / Шаг 7: Восстановление на определенный момент времени (если архивирование WAL включено)
echo "Demonstrating point-in-time recovery... / Демонстрация восстановления на определенный момент времени..."
echo "To perform PITR, use: / Для выполнения PITR используйте:"
echo "./wall-be.sh postgresql restore --time \"2023-01-01 12:00:00\""

echo "Example completed successfully! / Пример успешно завершен!" 