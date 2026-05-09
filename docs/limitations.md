# Ограничения решения

## Почему выбран Blackbox Exporter + Prometheus

### Рассмотренные альтернативы

| Инструмент        | Плюсы                                   | Минусы                                    |
|-------------------|-----------------------------------------|-------------------------------------------|
| **Blackbox Exporter** | CNCF, зрелый, config-as-code, богатые метрики | Нет UI для настройки, нужен Prometheus    |
| **Uptime Kuma**   | Красивый UI, прост в настройке          | Конфиг через UI (не код), ограниченные метрики |
| **Gatus**         | Config-as-code, встроенный UI           | Меньше метрик, слабее экосистема          |
| **Checkly**       | Полноценный SaaS, браузерные тесты      | Не self-hosted, платный                   |
| **Freshping**     | Прост, бесплатный tier                  | SaaS, нет config-as-code                  |

**Выбор Blackbox Exporter обоснован:**
- Это промышленный стандарт в Kubernetes/cloud-native стеке
- Богатые метрики (DNS timing, TLS expiry, phase breakdown)
- Полная интеграция с Prometheus/Grafana/Alertmanager
- Конфигурация как код, GitOps-совместимость
- Активная поддержка CNCF Prometheus community

## Технические ограничения

### 1. Одна точка проверки

Все проверки выполняются с одного сервера. Это означает:

- Нет проверки из разных географических зон
- Проблема с DNS на этом сервере = ложная тревога
- Нет "triangulation" при диагностике инцидента

**Решение для мульти-локации:** запустить несколько инстансов стека на разных VPS в разных регионах, федерировать Prometheus или использовать remote_write в центральный Prometheus.

### 2. Нет browser/screenshot проверок

Blackbox Exporter проверяет HTTP-ответ, но не рендерит страницу. Это не покрывает:

- JavaScript-ошибки на клиентской стороне
- Визуальную деградацию UI
- SPA с client-side routing

**Следующий этап:** Playwright/Puppeteer + screenshot comparison (Grafana k6 Browser или checkly).

### 3. Body matching — только regex

Проверка содержимого ответа через regexp — не полноценный JSON Schema validation. Для сложных API это недостаточно.

**Альтернатива:** k6, или custom exporter на Python/Go.

### 4. Нет проверки authenticated endpoints

Blackbox Exporter поддерживает базовый HTTP auth и Bearer token, но не OAuth2 flows, CSRF, session cookies.

Добавить auth headers для конкретного endpoint:

```yaml
modules:
  http_authenticated:
    prober: http
    http:
      headers:
        Authorization: "Bearer your_static_token"
```

### 5. Нет исторических SLA-отчётов из коробки

Prometheus хранит сырые метрики. SLA-отчёт (например, "uptime 99.9% за месяц") можно посчитать через PromQL, но нет встроенного SLA-репортинга.

```promql
# Uptime за последние 30 дней
avg_over_time(probe_success{instance="https://example.com"}[30d]) * 100
```

### 6. Хранение метрик

По умолчанию: 30 дней / 5 GB. Для долгосрочного хранения нужен VictoriaMetrics, Thanos или Cortex.

### 7. Отсутствие RBAC/multi-tenancy

Grafana с одним admin-пользователем — не подходит для команд с разными уровнями доступа без дополнительной настройки организаций/ролей.

## Что делать дальше

| Потребность                        | Инструмент                              |
|------------------------------------|-----------------------------------------|
| Мульти-регион проверки             | Несколько инстансов + Prometheus federation |
| Браузерные/screenshot тесты        | k6 Browser, Playwright + custom exporter |
| Долгосрочное хранение              | VictoriaMetrics, Thanos                 |
| Complex API validation             | k6, custom Go/Python exporter           |
| SLA-отчёты                         | Grafana + PromQL recording rules        |
| RBAC                               | Grafana Organizations + LDAP/OAuth      |
| Scheduled maintenance windows      | Alertmanager time intervals             |
