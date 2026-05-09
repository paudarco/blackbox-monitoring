# Мониторинг из нескольких географических точек

## Проблема

Один экземпляр мониторинга проверяет доступность только из одной локации. Если ваш сайт недоступен из Европы, но доступен из США — единый инстанс не покажет реальную картину.

## Схема: два VPS в разных регионах

```
┌──────────────────────────┐     ┌──────────────────────────┐
│  VPS Frankfurt (EU)       │     │  VPS Singapore (APAC)     │
│  monitoring-eu.example.com│     │  monitoring-sg.example.com│
│                           │     │                           │
│  ┌─────────────────────┐  │     │  ┌─────────────────────┐  │
│  │  Blackbox Exporter  │  │     │  │  Blackbox Exporter  │  │
│  │  Prometheus         │  │     │  │  Prometheus         │  │
│  │  Alertmanager       │  │     │  │  (no Alertmanager)  │  │
│  └─────────────────────┘  │     │  └─────────────────────┘  │
└──────────────────────────┘     └──────────────────────────┘
         │                                    │
         │ remote_write                       │ remote_write
         ▼                                    ▼
┌──────────────────────────────────────────────────────────────┐
│  Central Prometheus / VictoriaMetrics                         │
│  Grafana (единый дашборд с метками region=eu/apac)           │
└──────────────────────────────────────────────────────────────┘
```

## Шаг 1: Метки региона в prometheus.yml

На каждом региональном инстансе добавьте метку в `external_labels`:

```yaml
# prometheus.yml на Frankfurt VPS
global:
  external_labels:
    monitor: "external-monitoring"
    region: "eu-west"
    location: "frankfurt"
```

```yaml
# prometheus.yml на Singapore VPS
global:
  external_labels:
    monitor: "external-monitoring"
    region: "apac"
    location: "singapore"
```

## Шаг 2: remote_write в центральный Prometheus

```yaml
# На каждом региональном инстансе
remote_write:
  - url: "https://central-prometheus.example.com/api/v1/write"
    basic_auth:
      username: "remote_write_user"
      password: "${REMOTE_WRITE_PASSWORD}"
    write_relabel_configs:
      - source_labels: [__name__]
        regex: "probe_.*"
        action: keep  # Отправлять только probe_* метрики
```

## Шаг 3: PromQL с учётом регионов

```promql
# Сервис недоступен ТОЛЬКО из одного региона
probe_success == 0 and on(instance) sum by(instance) (probe_success) > 0

# Сервис недоступен из ВСЕХ регионов — реальный сбой
(count by(instance) (probe_success == 0))
  == (count by(instance) (probe_success))

# Latency по регионам
probe_duration_seconds{instance="https://example.com"}
```

## Шаг 4: Дашборд Grafana

Добавьте переменную `region` в дашборд и используйте её в queries:

```promql
probe_success{instance=~"$target", region=~"$region"}
```

## Минимальный вариант без центрального Prometheus

Запустить полный стек (с Grafana) только на одном регионе. На втором — только Blackbox + Prometheus, который federate-ится с первым:

```yaml
# На основном инстансе в prometheus.yml
scrape_configs:
  - job_name: "federate_apac"
    honor_labels: true
    metrics_path: /federate
    params:
      match[]:
        - '{job=~"blackbox_.*"}'
    static_configs:
      - targets:
          - monitoring-sg.example.com:9090
        labels:
          federated_from: "apac"
```
