FROM python:3.9-slim

# Устанавливаем зависимости для сборки
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    python3-dev \
 && rm -rf /var/lib/apt/lists/*

# Указываем рабочую директорию
WORKDIR /app

# Копируем только requirements.txt для кеширования зависимостей
COPY app/requirements.txt .

# Устанавливаем зависимости в режиме "no cache" для меньшего размера образа
RUN pip install --no-cache-dir -r requirements.txt

# Копируем приложение
COPY app .

# Открываем порт
EXPOSE 8080

# Запускаем приложение
CMD ["python", "app.py"]
