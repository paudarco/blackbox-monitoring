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
git clone https://github.com/your-org/external-monitoring /opt/external-monitoring
cd /opt/external-monitoring
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

## Настройка Nginx как reverse proxy (рекомендуется)

```bash
apt install nginx -y
```

Создать `/etc/nginx/sites-available/monitoring`:

```nginx
server {
    listen 80;
    server_name monitoring.yourdomain.com;

    # Redirect to HTTPS
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name monitoring.yourdomain.com;

    ssl_certificate /etc/letsencrypt/live/monitoring.yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/monitoring.yourdomain.com/privkey.pem;

    # Grafana
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    # Prometheus (restrict access)
    location /prometheus/ {
        auth_basic "Monitoring";
        auth_basic_user_file /etc/nginx/.htpasswd;
        proxy_pass http://127.0.0.1:9090/;
    }
}
```

```bash
ln -s /etc/nginx/sites-available/monitoring /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx
```

## Обновление

```bash
cd /opt/external-monitoring
docker compose pull
docker compose up -d
docker compose ps
```

## Автозапуск после перезагрузки

Docker с restart policy `unless-stopped` автоматически перезапускает контейнеры. Убедитесь, что Docker запускается при старте системы:

```bash
sudo systemctl enable docker
```
