# Развёртывание на VPS

## Требования

- Ubuntu 22.04+ / Debian 12+ (или любой Linux с Docker)
- Docker Engine 24+
- Docker Compose v2 (плагин, не standalone)
- 1 vCPU, 1 GB RAM минимум (рекомендуется 2 GB)
- 10 GB свободного места на диске

## Шаг 1 — Установить Docker

```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
newgrp docker
docker --version        # Docker version 24+
docker compose version  # Docker Compose version v2+
```

## Шаг 2 — Клонировать репозиторий

```bash
git clone https://github.com/paudarco/blackbox-monitoring /opt/blackbox-monitoring
cd /opt/blackbox-monitoring
```

## Шаг 3 — Настроить переменные окружения

```bash
cp .env.example .env
nano .env
```

Минимальная конфигурация:

```env
TELEGRAM_BOT_TOKEN=1234567890:ABCdefGHIjklMNOpqrSTUvwxYZ
TELEGRAM_CHAT_ID=-1001234567890
GF_ADMIN_PASSWORD=your_strong_password_here
```

## Шаг 4 — Запустить

```bash
make up 
```
> Для make-команд требуется утилита Makefile. Установка - `sudo apt install build-essential`

или

```bash
docker compose up -d
docker compose ps
```

Ожидаемый вывод:

```
NAME            STATUS          PORTS
blackbox        healthy         0.0.0.0:9115->9115/tcp
prometheus      healthy         0.0.0.0:9090->9090/tcp
alertmanager    healthy         0.0.0.0:9093->9093/tcp
grafana         healthy         0.0.0.0:3000->3000/tcp
```

## Шаг 5 — Проверить работу

```bash
# Проверить все проверки в Prometheus
curl -s http://localhost:9090/api/v1/targets | python3 -m json.tool | grep -E '"health"|"instance"'

# Прямо проверить один URL через Blackbox
curl -s "http://localhost:9115/probe?target=https://www.google.com&module=http_2xx" | grep probe_success
```

Также дашборды доступны на :3000 порту по ip-адресу выбранного сервера, например: `185.218.137.1:3000`

## Автозапуск после перезагрузки

Docker с restart policy `unless-stopped` автоматически перезапускает контейнеры. Убедитесь, что Docker запускается при старте системы:

```bash
sudo systemctl enable --now docker
sudo systemctl enable containerd

# Проверка, что сервис включен в автозапуск
systemctl is-enabled docker

# Проверка, что контейнеры получили restart policy
docker inspect blackbox --format '{{ .HostConfig.RestartPolicy.Name }}'
docker inspect prometheus --format '{{ .HostConfig.RestartPolicy.Name }}'
docker inspect alertmanager --format '{{ .HostConfig.RestartPolicy.Name }}'
docker inspect grafana --format '{{ .HostConfig.RestartPolicy.Name }}'
```

Если вывод `systemctl is-enabled docker` = `enabled`, а для контейнеров выводится `unless-stopped`, автозапуск настроен корректно.
