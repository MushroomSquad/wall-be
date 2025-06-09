FROM mysql:8.0

# Установка необходимых зависимостей
RUN apt-get update && apt-get install -y \
    wget curl gnupg2 lsb-release ca-certificates apt-transport-https \
    python3 python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Установка AWS CLI для поддержки S3
RUN pip3 install --no-cache-dir awscli

# Установка WAL-G
RUN set -ex; \
    apt-get update; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        wget \
        ca-certificates; \
    wget -q -O /tmp/wal-g.tar.gz https://github.com/wal-g/wal-g/releases/download/v2.0.1/wal-g-mysql-ubuntu-20.04-amd64.tar.gz; \
    tar -xzf /tmp/wal-g.tar.gz -C /usr/local/bin wal-g; \
    chmod +x /usr/local/bin/wal-g; \
    rm /tmp/wal-g.tar.gz; \
    apt-get purge -y --auto-remove wget; \
    rm -rf /var/lib/apt/lists/*

# Копирование скриптов
COPY scripts/ /usr/local/bin/
RUN chmod +x /usr/local/bin/*.sh

# Копирование файла конфигурации MySQL
COPY my.cnf /etc/mysql/conf.d/my.cnf

# Копирование entrypoint скрипта
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["mysqld"] 