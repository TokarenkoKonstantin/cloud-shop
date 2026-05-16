# Phase 10 — CNI Migration: Flannel → Calico

Миграция сетевого плагина кластера с Flannel на Calico v3.29.3 без даунтайма приложения.
Calico даёт возможность использовать Network Policy — файрвол между подами на уровне кластера.

## Зачем менять Flannel на Calico?

| Функция | Flannel | Calico |
|---------|---------|--------|
| Network Policy | ❌ | ✅ |
| Производительность | Средняя | Высокая |
| BGP routing | ❌ | ✅ |
| Observability | Минимальная | Расширенная |

## Конфигурация

- **Версия:** Calico v3.29.3
- **Режим:** IPIP (IP-in-IP encapsulation)
- **Pod CIDR:** 10.244.0.0/16
- **Установка:** Tigera Operator

## Проблемы и решения

**Проблема:** Ubuntu 22.04 имеет `rp_filter=2` по умолчанию, что блокирует IPIP трафик Calico.

**Решение:** DaemonSet `calico-rp-fix`, который устанавливает `rp_filter=1` на всех нодах при старте.

```yaml
# calico-rp-fix.yaml — решает проблему rp_filter на Ubuntu
```

## Порядок миграции

```bash
# 1. Удалить Flannel
kubectl delete -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml

# 2. Очистить сетевые интерфейсы на всех нодах (Ansible)
ansible k8s_nodes -m shell -a "ip link delete flannel.1; ip link delete cni0" --become

# 3. Установить Tigera Operator
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.29.3/manifests/tigera-operator.yaml

# 4. Применить конфигурацию
kubectl apply -f calico-custom-resources.yaml

# 5. Применить фикс rp_filter
kubectl apply -f calico-rp-fix.yaml

# 6. Проверить статус
kubectl get pods -n calico-system
```

## Проверка

```bash
# Все Calico поды Running
kubectl get pods -n calico-system

# Сеть между нодами работает
kubectl run test --image=busybox --restart=Never -- ping -c 3 10.244.0.1

# Приложение доступно
curl http://192.168.11.200
```

