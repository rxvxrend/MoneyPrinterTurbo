# Используем официальный Python runtime как базовый образ
FROM python:3.11-slim-bullseye

# Задаем рабочий каталог в контейнере
WORKDIR /MoneyPrinterTurbo

# Выставляем права 777 для каталога /MoneyPrinterTurbo
RUN chmod 777 /MoneyPrinterTurbo

ENV PYTHONPATH="/MoneyPrinterTurbo"

# Устанавливаем системные зависимости: сначала пробуем локальные зеркала для стабильности
RUN echo "deb http://mirrors.aliyun.com/debian bullseye main" > /etc/apt/sources.list && \
    echo "deb http://mirrors.aliyun.com/debian-security bullseye-security main" >> /etc/apt/sources.list && \
    ( \
        for i in 1 2 3; do \
            echo "Attempt $i: Using Aliyun mirror"; \
            apt-get update && apt-get install -y --no-install-recommends \
                git \
                imagemagick \
                ffmpeg && break || \
            echo "Attempt $i failed, retrying..."; \
            if [ $i -eq 3 ]; then \
                echo "Aliyun mirror failed, switching to Tsinghua mirror"; \
                sed -i 's/mirrors.aliyun.com/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list && \
                sed -i 's/mirrors.aliyun.com\/debian-security/mirrors.tuna.tsinghua.edu.cn\/debian-security/g' /etc/apt/sources.list && \
                ( \
                    apt-get update && apt-get install -y --no-install-recommends \
                        git \
                        imagemagick \
                        ffmpeg || \
                    ( \
                        echo "Tsinghua mirror failed, switching to default Debian mirror"; \
                        sed -i 's/mirrors.tuna.tsinghua.edu.cn/deb.debian.org/g' /etc/apt/sources.list && \
                        sed -i 's/mirrors.tuna.tsinghua.edu.cn\/debian-security/security.debian.org/g' /etc/apt/sources.list; \
                        apt-get update && apt-get install -y --no-install-recommends \
                            git \
                            imagemagick \
                            ffmpeg; \
                    ); \
                ); \
            fi; \
            sleep 5; \
        done \
    ) && rm -rf /var/lib/apt/lists/*

# Исправляем политику безопасности ImageMagick
RUN sed -i '/<policy domain="path" rights="none" pattern="@\*"/d' /etc/ImageMagick-6/policy.xml

# Сначала копируем только requirements.txt, чтобы использовать Docker cache
COPY requirements.txt ./

# Устанавливаем Python-зависимости: сначала локальные зеркала и retry-логика
RUN pip install --no-cache-dir -i https://mirrors.aliyun.com/pypi/simple/ --trusted-host mirrors.aliyun.com --retries 3 --timeout 60 -r requirements.txt || \
    pip install --no-cache-dir -i https://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple/ --trusted-host mirrors.tuna.tsinghua.edu.cn --retries 3 --timeout 60 -r requirements.txt || \
    pip install --no-cache-dir --retries 3 --timeout 60 -r requirements.txt

# Затем копируем остальной код в образ
COPY . .

# Открываем порт, на котором работает приложение
EXPOSE 8501

# Команда запуска приложения
CMD ["streamlit", "run", "./webui/Main.py","--browser.serverAddress=127.0.0.1","--server.enableCORS=True","--browser.gatherUsageStats=False"]

# 1. Соберите Docker-образ следующей командой
# docker build -t moneyprinterturbo .

# 2. Запустите Docker-контейнер следующей командой
## Для Linux или macOS:
# docker run -v $(pwd)/config.toml:/MoneyPrinterTurbo/config.toml -v $(pwd)/storage:/MoneyPrinterTurbo/storage -p 127.0.0.1:8501:8501 moneyprinterturbo
## Для Windows:
# docker run -v ${PWD}/config.toml:/MoneyPrinterTurbo/config.toml -v ${PWD}/storage:/MoneyPrinterTurbo/storage -p 127.0.0.1:8501:8501 moneyprinterturbo
