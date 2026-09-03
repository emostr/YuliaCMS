---
title: Обновление и резервные копии
description: Как обновить Yulia одной кнопкой и что сохранять, чтобы ничего не потерять.
permalink: /ru/updating/
---

## Обновление

Подключитесь к серверу и запустите тот же скрипт, что и при установке:

```bash
sudo ruby InstallYulia.rb
```

Он увидит, что Yulia уже стоит, и покажет меню с пунктом **Обновить**. Дальше он сам скачает новую версию, пересоберёт и перезапустит. Изменения в базе применяются на запуске.

Сайты недоступны на минуту-две, пока идёт перезапуск. Содержимое, файлы и настройки не трогаются.

Если что-то не заладилось, скрипт скажет, на каком шаге остановился, и **не тронет данные**. Повторный запуск безопасен.

## Что нужно сохранять

Три вещи, и все три — на сервере.

### 1. Файл `.env`

```
/opt/yulia/.env
```

В нём пароль базы и `SECRET_KEY_BASE`. Потеряете `SECRET_KEY_BASE` — сессии оборвутся, а секреты второго фактора расшифровать будет нечем: всем придётся заново привязывать аутентификатор.

Скопируйте файл к себе один раз и положите в менеджер паролей.

### 2. База данных

Там страницы, настройки и заявки:

```bash
cd /opt/yulia
docker compose exec -T postgres pg_dump -U yulia yulia_production | gzip > ~/yulia-$(date +%F).sql.gz
```

### 3. Загруженные файлы

Картинки и собранные острова:

```bash
docker run --rm \
  -v project-yulia_storage:/data:ro \
  -v ~:/backup \
  alpine tar czf /backup/yulia-files-$(date +%F).tar.gz -C /data .
```

Скачать копии на свой компьютер:

```bash
scp root@203.0.113.10:~/yulia-*.gz .
```

## Автоматическая копия раз в сутки

Создайте `/etc/cron.daily/yulia-backup`:

```bash
#!/bin/sh
# Ежедневная копия Yulia. Хранится две недели.
set -e

DEST=/var/backups/yulia
mkdir -p "$DEST"

cd /opt/yulia
docker compose exec -T postgres pg_dump -U yulia yulia_production \
  | gzip > "$DEST/db-$(date +%F).sql.gz"

cp /opt/yulia/.env "$DEST/env-$(date +%F)"

# Копии старше двух недель только занимают место.
find "$DEST" -type f -mtime +14 -delete
```

Сделайте его исполняемым:

```bash
chmod +x /etc/cron.daily/yulia-backup
```

> Копия на том же сервере спасает от ошибки, но не от потери сервера. Хотя бы раз в месяц забирайте её на свой компьютер или в облако.

## Восстановление

Из копии базы:

```bash
cd /opt/yulia
gunzip -c ~/yulia-2026-09-03.sql.gz | \
  docker compose exec -T postgres psql -U yulia -d yulia_production
docker compose restart app
```

Восстанавливайте **на ту же версию Yulia**, с которой снималась копия, иначе схема базы может не совпасть.

## Остановить и запустить

Через меню установщика, пункты **Остановить** и **Обновить**. Или руками:

```bash
cd /opt/yulia
docker compose down     # остановить: сайты уйдут в офлайн
docker compose up -d     # запустить обратно
```

## Посмотреть, что происходит

```bash
cd /opt/yulia
docker compose ps                  # что запущено
docker compose logs -f app         # журнал приложения
docker compose logs --tail 50 caddy  # журнал веб-сервера
```

То же самое короче — в меню установщика: **Состояние** и **Журнал**.
