# Getting Started

**Language / Язык**: [English](getting-started.md) | [Русский](../getting-started.md)

## Introduction

wall-be is a universal tool for managing backups of various databases using WAL-G. This guide will help you get started with the basic setup and operations.

## Prerequisites

Before you begin, ensure you have the following:

- Linux system with bash shell
- Access to one of the supported databases (MySQL/MariaDB, PostgreSQL)
- Administrative privileges for database operations
- Storage account for backups (S3, GCS, Azure) or local storage space

## Installation

1. **Clone the repository**:

```bash
git clone https://github.com/MushroomSquad/wall-be.git
cd wall-be
chmod +x wall-be.sh
```

2. **Set up WAL-G for your database**:

For MySQL:
```bash
./wall-be.sh mysql setup
```

For PostgreSQL:
```bash
./wall-be.sh postgresql setup
```

This will:
- Download and install WAL-G
- Create a configuration file
- Configure your database for WAL-G integration

3. **Edit the configuration file**:

The setup script creates a configuration file in the current directory. Edit this file to specify your database connection details and storage settings:

```bash
nano config-mysql.env  # For MySQL
# or
nano config-postgresql.env  # For PostgreSQL
```

## Quick Start

### Creating a Backup

```bash
./wall-be.sh mysql backup  # For MySQL
# or
./wall-be.sh postgresql backup  # For PostgreSQL
```

### Listing Available Backups

```bash
./wall-be.sh mysql list  # For MySQL
# or
./wall-be.sh postgresql list  # For PostgreSQL
```

### Restoring from a Backup

```bash
./wall-be.sh mysql restore --name LATEST  # For MySQL, restores the latest backup
# or
./wall-be.sh postgresql restore --name LATEST  # For PostgreSQL, restores the latest backup
```

## Next Steps

Now that you have the basics set up, you may want to:

1. [Configure backup retention policies](configuration.md)
2. [Set up scheduled backups](cron.md)
3. [Learn about Docker integration](docker.md)
4. [Explore database-specific features](../databases/en/mysql.md)

## Need Help?

If you encounter any issues, please check the [Troubleshooting](troubleshooting.md) guide or open an issue on the GitHub repository. 