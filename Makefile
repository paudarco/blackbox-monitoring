# =============================================================================
# External Monitoring — Makefile
# Convenience commands for managing the monitoring stack
# =============================================================================

.PHONY: help up down restart status logs validate reload test-alert targets probe

help:
	@echo "External Monitoring Stack"
	@echo ""
	@echo "Usage:"
	@echo "  make up          — Start all services"
	@echo "  make down        — Stop all services"
	@echo "  make restart     — Restart all services"
	@echo "  make status      — Show container status"
	@echo "  make logs        — Follow logs from all services"
	@echo "  make validate    — Validate Prometheus config"
	@echo "  make reload      — Hot-reload Prometheus config"
	@echo "  make targets     — Show all Prometheus scrape targets"
	@echo "  make test-alert  — Send a test alert to Alertmanager"
	@echo "  make probe URL=https://example.com — Manually run a probe"

up:
	@if [ ! -f .env ]; then \
		cp .env.example .env; \
		echo ""; \
		echo "⚠️  Создан файл .env из .env.example."; \
		echo "   Перед запуском ОБЯЗАТЕЛЬНО заполните:"; \
		echo "     TELEGRAM_BOT_TOKEN=  (для Telegram-алертов)"; \
		echo "     GF_ADMIN_PASSWORD=   (пароль Grafana)"; \
		echo ""; \
		echo "   Отредактируйте: nano .env"; \
		echo "   Затем повторите: make up"; \
		echo ""; \
		exit 1; \
	fi
	docker compose up -d
	@echo ""
	@echo "Grafana:       http://localhost:3000"
	@echo "Prometheus:    http://localhost:9090"
	@echo "Alertmanager:  http://localhost:9093"
	@echo "Blackbox:      http://localhost:9115"

down:
	docker compose down

restart:
	docker compose restart

status:
	docker compose ps

logs:
	docker compose logs -f --tail=50

validate:
	docker compose exec prometheus promtool check config /etc/prometheus/prometheus.yml
	docker compose exec prometheus promtool check rules /etc/prometheus/rules.yml

reload:
	curl -s -X POST http://localhost:9090/-/reload && echo "Prometheus reloaded"
	docker compose restart blackbox && echo "Blackbox restarted"

targets:
	@curl -s http://localhost:9090/api/v1/targets | python3 -c \
	"import json,sys; data=json.load(sys.stdin)['data']['activeTargets']; \
	[print(f\"{t['labels'].get('job','?'):40s} {t['labels'].get('instance','?'):60s} {t['health']}\") for t in data]"

test-alert:
	curl -s -X POST http://localhost:9093/api/v2/alerts \
	  -H "Content-Type: application/json" \
	  -d '[{"labels":{"alertname":"TestAlert","severity":"warning","instance":"test.example.com"},"annotations":{"summary":"Test alert from Makefile","description":"This is a manual test alert."}}]'
	@echo ""
	@echo "Алерт отправлен. Проверьте Telegram и логи Alertmanager:"
	@echo "  docker compose logs alertmanager --tail=20"

probe:
	@if [ -z "$(URL)" ]; then echo "Usage: make probe URL=https://example.com"; exit 1; fi
	curl -s "http://localhost:9115/probe?target=$(URL)&module=http_2xx" | grep "^probe_"
