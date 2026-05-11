# External Monitoring

> Self-hosted synthetic/blackbox monitoring — проверяет доступность сайтов и API снаружи, как это делает реальный пользователь.

## Что это

Компактный стек для **внешнего мониторинга** сервисов:

- **Blackbox Exporter** — выполняет HTTP/HTTPS/TCP проверки
- **Prometheus** — собирает метрики, хранит историю, оценивает правила алертов
- **Alertmanager** — маршрутизирует алерты в Telegram
- **Grafana** — дашборды с историей доступности и latency

Отвечает на вопрос: **доступен ли сервис пользователю прямо сейчас?**

## Быстрый старт

```bash
# 1. Клонировать репозиторий
git clone https://github.com/your-org/external-monitoring
cd external-monitoring

# 2. Создать .env из примера
cp .env.example .env

# 3. (Опционально) Добавить Telegram-бота
# Откройте .env и заполните TELEGRAM_BOT_TOKEN и TELEGRAM_CHAT_ID

# 4. Запустить стек
docker compose up -d

# 5. Проверить статус контейнеров
docker compose ps

# 6. Открыть Grafana
# http://localhost:3000  (логин/пароль из .env: GF_ADMIN_USER / GF_ADMIN_PASSWORD)
```

Через 60–90 секунд Prometheus начнёт собирать метрики.

## Компоненты и порты

| Сервис           | URL                          | Назначение                        |
|------------------|------------------------------|-----------------------------------|
| Grafana          | http://localhost:3000        | Дашборды, визуализация            |
| Prometheus       | http://localhost:9090        | Метрики, alert rules              |
| Alertmanager     | http://localhost:9093        | Маршрутизация алертов             |
| Blackbox Exporter| http://localhost:9115        | Probe engine                      |

## Что проверяется из коробки

| Проверка                    | Цель                                            |
|-----------------------------|------------------------------------------------|
| HTTP 2xx доступность        | google.com, github.com, cloudflare.com         |
| JSON API                    | api.github.com, jsonplaceholder.typicode.com   |
| TLS/SSL expiry              | Сертификаты всех HTTPS-сайтов                  |
| Body content                | example.com (содержит "Example Domain")        |
| Latency                     | google.com, httpbin.org                        |
| Намеренно сломанная         | httpbin.org с неверным ожидаемым статусом      |

## Документация

- [Развёртывание на VPS](docs/deploy.md)
- [Добавление новой проверки](docs/add-check.md)
- [Настройка Telegram-алертов](docs/alerts.md)
- [Ограничения решения](docs/limitations.md)

## Почему Blackbox Exporter + Prometheus

Blackbox Exporter — наиболее зрелый и поддерживаемый open-source инструмент для synthetic monitoring. Преимущества:

- Конфигурация как код (YAML)
- Богатые метрики: latency, DNS timing, TLS expiry, body matching
- Нативная интеграция с Prometheus и Grafana
- Активная поддержка CNCF/Prometheus community
- Работает без агентов на целевых серверах

Подробнее: [docs/limitations.md](docs/limitations.md)
