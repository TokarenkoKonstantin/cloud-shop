# Phase 9 — Production Deploy на VMware Workstation

Развернул полноценный Kubernetes кластер из 5 виртуальных машин на VMware Workstation.
Это финальная проверка всей инфраструктуры в условиях, максимально приближенных к реальному продакшну.

## Инфраструктура

| Нода | IP | Роль | CPU | RAM | Диск |
|------|----|------|-----|-----|------|
| k8s-master | 192.168.11.101 | Control Plane | 2 | 4GB | 20GB |
| k8s-worker-1 | 192.168.11.102 | Worker | 2 | 4GB | 20GB |
| k8s-worker-2 | 192.168.11.103 | Worker | 2 | 4GB | 20GB |
| k8s-worker-3 | 192.168.11.104 | Worker | 2 | 4GB | 20GB |
| k8s-worker-4 | 192.168.11.105 | Worker | 2 | 4GB | 20GB |

- **OS:** Ubuntu 22.04 LTS
- **Kubernetes:** kubeadm v1.29
- **Статические IP** назначены через Netplan

## Что задеплоено

- Все 4 микросервиса cloud-shop (Running)
- PostgreSQL HA через CloudNativePG (1 primary + 2 replica)
- MinIO — S3-совместимое хранилище для бэкапов БД
- Ingress-NGINX + MetalLB (External IP: 192.168.11.200)
- Prometheus + Grafana мониторинг
- ArgoCD — GitOps синхронизация
- HPA + PDB — высокая доступность

## Проверка работоспособности

```bash
# Статус нод
kubectl get nodes -o wide

# Все поды запущены
kubectl get pods -A

# Приложение доступно
curl http://192.168.11.200
```

## Результат

```
NAME            STATUS   ROLES           AGE
k8s-master      Ready    control-plane   -
k8s-worker-1    Ready    <none>          -
k8s-worker-2    Ready    <none>          -
k8s-worker-3    Ready    <none>          -
k8s-worker-4    Ready    <none>          -
```

`curl http://192.168.11.200` → HTTP 200 ✅

