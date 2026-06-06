# Руководство по Docker-развертыванию с GPU

Документ описывает, как использовать GPU для ускорения генерации субтитров через `faster-whisper` и заметно повысить скорость обработки.

## Зачем нужно GPU-ускорение

Единственный этап глубокого обучения в MoneyPrinterTurbo — **распознавание речи faster-whisper**: преобразование аудио в субтитры с временными метками.

- **CPU-режим** (по умолчанию): модель `large-v3` генерирует субтитры сравнительно медленно.
- **GPU-режим**: использует NVIDIA GPU + CUDA и обычно ускоряет обработку в **5–10 раз**.

> Примечание: остальные этапы проекта — генерация сценария, синтез аудио и монтаж видео — не используют глубокое обучение. GPU ускоряет только генерацию субтитров.

## Способы развертывания

Проект поддерживает два варианта Docker-развертывания; **развертывание CPU по умолчанию не меняется**.

### CPU-развертывание (по умолчанию, без изменений)

```bash
docker compose up -d
```

Используется прежний `Dockerfile` (`python:3.11-slim-bullseye`), GPU не требуется.

### GPU-развертывание (для пользователей с NVIDIA GPU)

```bash
docker compose -f docker-compose.yml -f docker-compose.gpu.yml up -d
```

Используется `Dockerfile.gpu` (`nvidia/cuda:12.1.1-cudnn8-runtime-ubuntu22.04`), а GPU подключается к сервису api.

## Предварительные условия для GPU-развертывания

### 1. Требования к оборудованию

- NVIDIA GPU (рекомендуется 6 GB VRAM и больше)
- Модель `large-v3` на GPU с точностью `float16` занимает примерно 1.5 GB VRAM

### 2. Требования к ПО

- **Драйвер NVIDIA**: подойдет актуальная версия; проверьте командой `nvidia-smi`
- **Docker Desktop**
- **NVIDIA Container Toolkit**: выполните `docker info` и убедитесь, что в списке Runtimes есть `nvidia`

### 3. Проверка окружения

```bash
# Проверить, что драйвер NVIDIA работает
nvidia-smi

# Проверить, что Docker поддерживает GPU (в Runtimes должен быть nvidia)
docker info | findstr nvidia
```

Если runtime `nvidia` отсутствует, сначала установите [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html).

## Настройка Whisper для GPU

В `config.toml` задайте:

```toml
subtitle_provider = "whisper"

[whisper]
model_size = "large-v3"
device = "cuda"           # использовать GPU (для CPU задайте "cpu")
compute_type = "float16"  # для GPU рекомендуется float16 (для CPU задайте "int8")
```

## Описание файлов

| Файл | Назначение |
|---|---|
| `Dockerfile` | CPU-образ по умолчанию (прежний, без изменений) |
| `Dockerfile.gpu` | GPU-образ (новый, основан на NVIDIA CUDA) |
| `docker-compose.yml` | Конфигурация CPU-развертывания по умолчанию (прежняя, без изменений) |
| `docker-compose.gpu.yml` | Конфигурация-переопределение для GPU-развертывания (новая) |

## Шаги GPU-развертывания

### Шаг 1: загрузите базовый CUDA-образ

```bash
docker pull nvidia/cuda:12.1.1-cudnn8-runtime-ubuntu22.04
```

> Если используются зеркала-ускорители вроде Aliyun, для `nvidia/cuda` может вернуться 403. Убедитесь, что образ можно скачать напрямую из Docker Hub.

### Шаг 2: измените config.toml

Как описано выше, задайте `subtitle_provider = "whisper"` и `device = "cuda"`.

### Шаг 3: соберите и запустите

```bash
docker compose -f docker-compose.yml -f docker-compose.gpu.yml up -d --build
```

### Шаг 4: проверьте, что GPU подключен

```bash
docker exec -it moneyprinterturbo-api nvidia-smi
```

Если отображается информация о GPU, значит подключение GPU прошло успешно.

## Рекомендации по VRAM и параллельности

| VRAM GPU | Рекомендуемый максимум параллельных задач |
|---|---|
| 4GB | 1–2 |
| 6GB | 2–3 |
| 8GB | 3–4 |
| 12GB+ | 5 |

Параллельность регулируется параметром `max_concurrent_tasks` в `config.toml`.

## Диагностика проблем

### Проблема 1: не удалось скачать образ (403 Forbidden)

Зеркало Aliyun может возвращать 403 для `nvidia/cuda`. Решения:

- настройте другое доступное зеркало;
- или выполните напрямую `docker pull nvidia/cuda:12.1.1-cudnn8-runtime-ubuntu22.04`.

### Проблема 2: при установке pip появляется `Cannot uninstall blinker`

В Ubuntu 22.04 системный `blinker` установлен через `distutils`, поэтому pip не может удалить его. В `Dockerfile.gpu` это уже обработано командой `apt-get remove -y python3-blinker`.

### Проблема 3: `nvidia-smi` внутри контейнера не видит GPU

- Убедитесь, что на хосте установлен NVIDIA Container Toolkit.
- Убедитесь, что в `docker info` среди Runtimes есть `nvidia`.
- Убедитесь, что использована команда GPU-развертывания: `docker compose -f docker-compose.yml -f docker-compose.gpu.yml up -d`.

### Проблема 4: Whisper сообщает об ошибке CUDA

- Убедитесь, что в `config.toml` задано `device = "cuda"` (регистр важен; это не `"CPU"`).
- Убедитесь, что задано `compute_type = "float16"`.
- Убедитесь, что задано `subtitle_provider = "whisper"`.
