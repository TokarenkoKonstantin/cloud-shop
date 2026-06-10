# ecommerce — Helm chart

Деплоит платформу целиком: frontend (nginx), три микросервиса (product / order / user) и PostgreSQL.

## Установка

```bash
helm install shop . \
  --namespace ecommerce --create-namespace \
  --set postgres.auth.password=<пароль>
```

Пароль **не хранится в чарте** — передаётся при установке или берётся из существующего Secret:

```bash
helm install shop . -n ecommerce --create-namespace \
  --set postgres.auth.existingSecret=my-db-secret
```

(Secret должен содержать ключи `postgres-password`, `database-url-orders`, `database-url-users`.)

## Ключевые values

| Параметр | По умолчанию | Описание |
|---|---|---|
| `global.imagePullPolicy` | `IfNotPresent` | `Never` — для локальных образов без registry |
| `postgres.auth.password` | — (обязателен) | пароль БД, задаётся через `--set` |
| `postgres.auth.existingSecret` | `""` | использовать существующий Secret вместо создаваемого чартом |
| `postgres.storage` | `1Gi` | размер PVC |
| `<service>.replicas` | `1` | количество реплик сервиса |
| `<service>.resources` | см. values | requests/limits (cpu-limits намеренно нет — троттлинг вреднее) |
| `ingress.enabled` | `true` | создавать ли Ingress |
| `ingress.host` | `""` | хост (пусто = любой) |

## Решения и ограничения

- **Probes**: readiness/liveness на `/health` каждого сервиса; у PostgreSQL — `pg_isready`
- **PostgreSQL здесь — одна реплика** (`strategy: Recreate`, один RWO-PVC). Это осознанное упрощение для данной фазы; production-вариант с HA (primary + 2 реплики, автофейловер, бэкапы в S3) в этом проекте реализован оператором [CloudNativePG — phase-08](../../phase-08-databases)
- **Labels** — по конвенции `app.kubernetes.io/*` через `_helpers.tpl`; селекторы оставлены простыми (`app: <name>`), т.к. селектор Deployment неизменяем

## Проверка

```bash
helm lint .
helm template shop . --set postgres.auth.password=test | kubectl apply --dry-run=server -f -
```
