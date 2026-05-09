# Настройка Telegram-алертов

## Шаг 1 — Создать Telegram-бота

1. Напишите [@BotFather](https://t.me/BotFather) в Telegram
2. Отправьте команду `/newbot`
3. Придумайте имя и username бота
4. Сохраните полученный **Bot Token** — он выглядит так: `1234567890:ABCdefGHIjklMNOpqrSTUvwxYZ`

## Шаг 2 — Получить Chat ID

**Для личных сообщений:**
1. Напишите вашему боту любое сообщение
2. Откройте в браузере: `https://api.telegram.org/bot<YOUR_TOKEN>/getUpdates`
3. Найдите в ответе поле `"chat": {"id": 123456789}` — это и есть ваш Chat ID

**Для группы:**
1. Добавьте бота в группу и сделайте администратором
2. Отправьте любое сообщение в группу
3. Откройте `https://api.telegram.org/bot<YOUR_TOKEN>/getUpdates`
4. Chat ID группы начинается с `-` (например, `-1001234567890`)

**Быстрый способ:** напишите [@userinfobot](https://t.me/userinfobot) — он покажет ваш ID.

## Шаг 3 — Настроить .env

```bash
nano .env
```

```env
TELEGRAM_BOT_TOKEN=1234567890:ABCdefGHIjklMNOpqrSTUvwxYZ
TELEGRAM_CHAT_ID=-1001234567890
```

## Шаг 4 — Перезапустить Alertmanager

```bash
docker compose restart alertmanager
docker compose logs alertmanager --tail=20
```

Убедитесь, что нет ошибок вида `failed to send telegram message`.

## Шаг 5 — Тест алерта

Намеренно сломанная проверка уже настроена в `prometheus.yml`. Она срабатывает примерно через 1–2 минуты после запуска и отправляет алерт `DemoAlertBrokenCheck` в Telegram.

Дополнительно можно отправить тестовый алерт вручную:

```bash
curl -X POST http://localhost:9093/api/v2/alerts \
  -H "Content-Type: application/json" \
  -d '[{
    "labels": {
      "alertname": "TestAlert",
      "severity": "warning",
      "instance": "test.example.com"
    },
    "annotations": {
      "summary": "Тестовый алерт — работает!",
      "description": "Это ручной тест Telegram-нотификаций."
    }
  }]'
```

## Что придёт в Telegram

При срабатывании алерта:

```
🔴 ALERT FIRING

Service https://example.com is DOWN

Probe for https://example.com has been failing for more than 2 minutes.
Job: blackbox_http_websites

Instance: https://example.com
Severity: critical
Started: 2024-01-15 14:30:00 UTC
```

При восстановлении:

```
✅ RESOLVED

Service https://example.com has RECOVERED

Instance: https://example.com
Severity: critical
Started: 2024-01-15 14:30:00 UTC
Resolved: 2024-01-15 14:35:22 UTC
```

## Когда отправляется алерт

По умолчанию алерт **не отправляется сразу** при первой неудаче:

| Правило          | for: | Объяснение                               |
|------------------|------|------------------------------------------|
| ServiceDown      | 2m   | Должен падать непрерывно 2 минуты        |
| ServiceHighLatency | 3m | Высокая latency 3 минуты подряд          |
| SSLCertExpiring  | 1h   | Предупреждение держится час              |
| DemoBrokenCheck  | 1m   | Быстро для тестирования                  |

Это предотвращает ложные срабатывания при единичных сбоях сети.

## Изменить задержку алертов

В `config/prometheus/rules.yml` найдите нужный alert и измените `for:`:

```yaml
- alert: ServiceDown
  expr: probe_success == 0
  for: 5m   # ← изменить здесь (было 2m)
```

После изменения:

```bash
curl -X POST http://localhost:9090/-/reload
```
