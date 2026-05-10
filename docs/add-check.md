# Добавление новой проверки

Все проверки — в одном файле: `config/prometheus/prometheus.yml`.

## Быстрый пример: добавить проверку сайта

Откройте `config/prometheus/prometheus.yml` и добавьте URL в секцию `blackbox_http_websites`:

```yaml
- job_name: "blackbox_http_websites"
  ...
  static_configs:
    - targets:
        - https://www.google.com
        - https://www.github.com
        - https://your-new-site.com   # ← добавить сюда
```

Применить без перезапуска:

```bash
curl -X POST http://localhost:9090/-/reload
```

## Типы проверок

### 1. Проверка доступности (HTTP 2xx)

```yaml
- job_name: "blackbox_http_websites"
  metrics_path: /probe
  params:
    module: [http_2xx]
  static_configs:
    - targets:
        - https://example.com
      labels:
        check_type: "website"
  relabel_configs:
    - source_labels: [__address__]
      target_label: __param_target
    - source_labels: [__param_target]
      target_label: instance
    - target_label: __address__
      replacement: blackbox:9115
```

### 2. Проверка JSON API

```yaml
- job_name: "blackbox_my_api"
  metrics_path: /probe
  params:
    module: [http_json_api]
  static_configs:
    - targets:
        - https://api.example.com/health
      labels:
        check_type: "api"
  relabel_configs:
    - source_labels: [__address__]
      target_label: __param_target
    - source_labels: [__param_target]
      target_label: instance
    - target_label: __address__
      replacement: blackbox:9115
```

### 3. Проверка содержимого body

Добавьте новый модуль в `config/blackbox/blackbox.yml`:

```yaml
modules:
  http_check_my_site:
    prober: http
    timeout: 15s
    http:
      valid_status_codes: [200]
      method: GET
      fail_if_body_not_matches_regexp:
        - "Welcome to MyApp"     # текст, который должен быть в ответе
      fail_if_matches_regexp:
        - "Error|Exception|500"  # текст, которого не должно быть
```

Затем в `prometheus.yml`:

```yaml
- job_name: "blackbox_my_site_body"
  metrics_path: /probe
  params:
    module: [http_check_my_site]
  static_configs:
    - targets:
        - https://myapp.example.com
  relabel_configs:
    - source_labels: [__address__]
      target_label: __param_target
    - source_labels: [__param_target]
      target_label: instance
    - target_label: __address__
      replacement: blackbox:9115
```

### 4. Проверка с нестандартным таймаутом

```yaml
- job_name: "blackbox_slow_api"
  scrape_interval: 60s
  scrape_timeout: 25s       # должен быть < scrape_interval
  metrics_path: /probe
  params:
    module: [http_2xx]
  static_configs:
    - targets:
        - https://slow-api.example.com
```

### 5. Проверка TLS-сертификата

```yaml
- job_name: "blackbox_tls_expiry"
  ...
  static_configs:
    - targets:
        - https://your-site.com   # добавить сюда
```

Алерт сработает автоматически, если сертификат истечёт через 14 дней.

## Описание условий успешной проверки

| Что проверяем              | Способ конфигурации                                 |
|----------------------------|-----------------------------------------------------|
| Статус-код = 200           | `valid_status_codes: [200]`                         |
| Статус-код = любой 2xx     | `valid_status_codes: []` (по умолчанию)             |
| Тело содержит строку       | `fail_if_body_not_matches_regexp: ["your_string"]`       |
| Тело НЕ содержит строку    | `fail_if_matches_regexp: ["error_string"]`          |
| Таймаут                    | `timeout: 10s` в модуле + порог в rules.yml         |
| TLS-сертификат не истёк    | `http_tls_expiry` модуль + правило алерта           |

## Применение изменений

```bash
# Горячая перезагрузка Prometheus (без остановки)
curl -X POST http://localhost:9090/-/reload

# Горячая перезагрузка Blackbox Exporter
docker compose restart blackbox

# Или перезапустить отдельный сервис
docker compose restart prometheus
```

## Проверка что новый таргет подхватился

```bash
# Prometheus targets API
curl -s "http://localhost:9090/api/v1/targets" | python3 -c "
import json,sys
data = json.load(sys.stdin)
for t in data['data']['activeTargets']:
    print(t['labels'].get('instance',''), '->', t['health'])
"
```
