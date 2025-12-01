#!/bin/bash

# Скрипт очистки сессий для устранения ошибок CSRF
# Автор: MiniMax Agent
# Дата: 2025-12-01

echo "=== Очистка сессий BenjForum ==="
echo "Время: $(date)"
echo

# Проверка статуса контейнеров
echo "📊 Проверка статуса контейнеров:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep benjforum
echo

# Очистка устаревших сессий из PostgreSQL
echo "🗄️  Очистка устаревших сессий из PostgreSQL:"
docker exec benjforum_postgres psql -U benjforum_user -d benjforum_db -c "DELETE FROM django_session WHERE expire_date < NOW();" 2>/dev/null
if [ $? -eq 0 ]; then
    echo "✅ Сессии PostgreSQL очищены"
else
    echo "❌ Ошибка очистки PostgreSQL"
fi
echo

# Очистка сессий через Django
echo "🐍 Очистка сессий через Django:"
docker exec benjforum_web python manage.py clearsessions 2>/dev/null
if [ $? -eq 0 ]; then
    echo "✅ Django сессии очищены"
else
    echo "❌ Ошибка очистки Django сессий"
fi
echo

# Очистка Redis кэша
echo "🔴 Очистка Redis кэша:"
docker exec benjforum_redis redis-cli -a B3njF0rum_R3dis_2024 FLUSHDB 2>/dev/null
if [ $? -eq 0 ]; then
    echo "✅ Redis кэш очищен"
else
    echo "❌ Ошибка очистки Redis"
fi
echo

# Перезапуск веб-контейнера
echo "🔄 Перезапуск веб-контейнера:"
docker restart benjforum_web
sleep 5
echo "✅ Веб-контейнер перезапущен"
echo

# Проверка HTTPS статуса
echo "🌐 Проверка HTTPS статуса:"
HTTPS_STATUS=$(curl -I -s -o /dev/null -w "%{http_code}" https://benj.run.place/ --max-time 10)
if [ "$HTTPS_STATUS" = "200" ]; then
    echo "✅ HTTPS работает (HTTP $HTTPS_STATUS)"
else
    echo "❌ HTTPS проблемы (HTTP $HTTPS_STATUS)"
fi
echo

# Проверка логов веб-контейнера
echo "📋 Последние логи веб-контейнера:"
docker logs benjforum_web --tail 5
echo

echo "=== Очистка завершена ==="
echo "Теперь очистите cookies браузера для benj.run.place и попробуйте войти"
echo "URL: https://benj.run.place/login/"
echo "Логин: admin | Пароль: misago2025"
echo

# Проверка финального статуса
echo "📊 Финальный статус контейнеров:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep benjforum