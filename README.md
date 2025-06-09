# wall-be

<p align="center">
  <img src="logo.svg" alt="WALL-BE Logo" width="200">
</p>

*Read this in other languages: [English](README.md), [Русский](README.ru.md)*

wall-be is a unified tool for database backup management using [WAL-G](https://github.com/wal-g/wal-g).

![GitHub](https://img.shields.io/github/license/MushroomSquad/wall-be)
![GitHub tag (latest by date)](https://img.shields.io/github/v/tag/MushroomSquad/wall-be)

**Language / Язык**: [English](README.md) | [Русский](README.ru.md)

## Features

- Support for multiple databases (MySQL, PostgreSQL)
- Simple command-line interface
- Configurable backup storage (S3, GCS, Azure, Local)
- Scheduling via cron
- Retention policy management
- Docker integration
- Interactive demonstration mode

## Supported Databases

- [MySQL/MariaDB](docs/databases/en/mysql.md)
- [PostgreSQL](docs/databases/en/postgresql.md)

## Installation

To install wall-be, run:

```bash
git clone https://github.com/MushroomSquad/wall-be.git
cd wall-be
chmod +x wall-be.sh
```

## Quick Start

### Setting Up WAL-G for MySQL

```bash
./wall-be.sh mysql setup
```

This will:
1. Download and install WAL-G
2. Create a default configuration file
3. Configure MySQL for WAL-G integration

### Creating a MySQL Backup

```bash
./wall-be.sh mysql backup
```

### Listing Available Backups

```bash
./wall-be.sh mysql list
```

### Restoring from a Backup

```bash
./wall-be.sh mysql restore --name LATEST
```

## Demonstration Mode

wall-be includes an interactive demonstration mode to showcase its capabilities without affecting your production environment:

```bash
# Run the demonstration
./demo/run-demo.sh

# Run with specific language (en - English, ru - Russian)
DEMO_LANG=en ./demo/run-demo.sh
```

The demonstration mode includes:
- MySQL/MariaDB backup and restore workflow
- PostgreSQL backup and restore workflow
- Backup scheduling examples
- Retention policy configuration
- Docker integration examples
- Automated testing suite

For Docker-based demonstration that doesn't require locally installed databases:
```bash
./demo/docker-demo.sh
```

## Contributing

Contributions are welcome! Please read our [contributing guidelines](CONTRIBUTING.md).

## License

This project is licensed under the MIT License.

## Acknowledgments

- [WAL-G](https://github.com/wal-g/wal-g) - The core backup tool
- [MySQL](https://www.mysql.com/) - Database documentation and community
- [PostgreSQL](https://www.postgresql.org/) - Database documentation and community

## Configuration

Configuration files are located in the `config` directory. There is a template configuration for each database.

### Main Configuration Parameters

- **Database connection** - database connection parameters
- **Storage** - type and settings of the backup storage
- **Compression** - backup compression method
- **Retention** - backup retention policy
- **Notifications** - backup status notification settings

## Examples

In the `examples` directory, there are examples of using **wall-be** for various scenarios.

### MySQL

- Basic backup and restore: `examples/mysql/basic-backup-restore.sh`

### PostgreSQL

- Basic backup and restore: `examples/postgresql/basic-backup-restore.sh`

## Documentation

- [Getting Started](docs/en/getting-started.md)
- [Configuration](docs/en/configuration.md)
- [Backup Management](docs/en/backup.md)
- [Restore](docs/en/restore.md)
- [Scheduling Backups](docs/en/cron.md)
- [Docker Integration](docs/en/docker.md)
- [Troubleshooting](docs/en/troubleshooting.md)

## License

The project is distributed under the MIT license.

## Contributing

We welcome contributions to the project! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for information on how to contribute.

## Dependency Installation

To install dependencies, you can use the automatic script from the demo directory:

```bash
# Install all dependencies
sudo ./demo/setup_dependencies.sh

# Or run the demonstration mode and select the "Dependency Installation" option
./demo/run-demo.sh
```

Alternatively, you can install manually:

1. Install WAL-G for your database, following the [official documentation](https://github.com/wal-g/wal-g#installation)
2. Clone this repository or download the archive
3. Create a configuration file (see examples in the `config` directory)
4. Run scripts from the `scripts` directory

## Internationalization

WALL-BE supports multilingual interfaces:

- The default language is automatically detected from your system settings
- You can override the language using the environment variable:

```bash
# Force English language
WALL_BE_LANG=en ./wall-be.sh mysql backup

# Force Russian language
WALL_BE_LANG=ru ./wall-be.sh mysql backup
```

Currently supported languages:
- English (en)
- Russian (ru)