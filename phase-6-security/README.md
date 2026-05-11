# Phase 6 — Security

## Что сделано

### Trivy — сканирование образов
```bash
# сканирование Docker образа на уязвимости
trivy image nginx:latest
trivy image your-app:latest

# сканирование с фильтром по критичности
trivy image --severity HIGH,CRITICAL nginx:latest
```

### UFW — файрвол на VPS (64.188.79.192)
```bash
# закрыт порт 9100 (Prometheus node exporter — не должен быть публичным)
sudo ufw deny 9100

# статус файрвола
sudo ufw status verbose
```

### Vault — убран с VPS
HashiCorp Vault убран как лишняя зависимость для VPS.
Секреты хранятся через GitHub Secrets (CI/CD) и K8s Secrets.

## Принципы безопасности применённые в проекте
- Минимальные права для пользователей БД (appuser только для appdb)
- Закрытые порты мониторинга от внешнего доступа
- SSH ключи вместо паролей
- Fail2ban на VPS против брутфорса
