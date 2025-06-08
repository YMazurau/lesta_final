#!/bin/sh

set -e  # Останавливать скрипт при ошибке

echo "📌 Запускаем entrypoint..."

# Показываем текущую директорию и содержимое
echo "📁 Текущая директория: $(pwd)"
echo "📄 Содержимое директории:"
ls -la

# Устанавливаем переменные окружения для Flask
export FLASK_APP=run.py
export FLASK_ENV=production

# Инициализация миграций (если каталог отсутствует)
if [ ! -d "./migrations" ]; then
  echo "🔧 migrations не найдены, создаём..."
  flask db init
  flask db migrate -m "Initial migration"
fi

# Применяем миграции
echo "🔁 Применяем миграции..."
flask db upgrade

# Запускаем Gunicorn
echo "🚀 Запускаем Gunicorn..."
exec gunicorn --bind 0.0.0.0:5000 "app:create_app()"
