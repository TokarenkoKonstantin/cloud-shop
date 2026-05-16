# Phase 11 — GitLab CI/CD

Self-hosted GitLab CE с GitLab Runner на Proxmox VE.
Полный CI/CD pipeline: lint → test → build → push в GitLab Container Registry.

## Инфраструктура

| Компонент | Расположение | IP |
|-----------|-------------|-----|
| GitLab CE | VMware VM (Ubuntu 24.04) | 192.168.0.8 |
| GitLab Runner | Proxmox VE VM (Ubuntu 22.04) | 192.168.11.110 |

## Pipeline

```
┌─────────┐    ┌─────────┐    ┌──────────────────────┐
│  lint   │───▶│  test   │───▶│  build & push        │
│ flake8  │    │ pytest  │    │  Docker → Registry   │
│         │    │coverage │    │  (только main ветка) │
└─────────┘    └─────────┘    └──────────────────────┘
```

### Стадии

| Стадия | Инструмент | Описание |
|--------|-----------|----------|
| lint | flake8 | Проверка стиля кода (PEP 8) |
| test | pytest + pytest-cov | Юнит-тесты + покрытие кода |
| build | docker build/push | Сборка образа и пуш в Registry |

## Настройка GitLab

```bash
# 1. Установка GitLab CE через Ansible
ansible-playbook ansible/install-gitlab.yml -i ansible/inventory.ini

# 2. Конфигурация external_url в /etc/gitlab/gitlab.rb
external_url "http://192.168.0.8"
registry_external_url "http://192.168.0.8:5050"

# 3. Применить конфигурацию
gitlab-ctl reconfigure
```

## Настройка Runner

```bash
# Установить Docker на Runner VM
sudo apt install docker.io -y
sudo usermod -aG docker gitlab-runner

# Зарегистрировать Runner
gitlab-runner register \
  --url http://192.168.0.8 \
  --token <registration-token> \
  --executor shell \
  --description "proxmox-shell-runner"
```

## Результат

Pipeline #5 — **passed** ✅

```
lint   ✅  flake8 — no issues
test   ✅  2 passed in 0.02s, coverage 100%
build  ✅  Image pushed to GitLab Registry
```

