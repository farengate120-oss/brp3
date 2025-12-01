#!/bin/bash

# BenjForum Health Check and Auto-Recovery Script
# Скрипт мониторинга и автоматического восстановления форума BenjForum

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/health_check.log"
MAX_RESTART_ATTEMPTS=3

# Функция логирования
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Функция проверки контейнера
check_container() {
    local container_name="$1"
    local expected_status="Up"
    
    if docker ps --format '{{.Names}}\t{{.Status}}' | grep -q "${container_name}.*${expected_status}"; then
        log_message "✅ Контейнер $container_name работает нормально"
        return 0
    else
        log_message "❌ Контейнер $container_name не отвечает или остановлен"
        return 1
    fi
}

# Функция проверки HTTP/HTTPS
check_web_access() {
    local url="$1"
    local expected_status="$2"
    local response
    
    response=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 10 --max-time 30 "$url" 2>/dev/null)
    
    if [ "$response" = "$expected_status" ]; then
        log_message "✅ Веб-доступ к $url работает (код: $response)"
        return 0
    else
        log_message "❌ Веб-доступ к $url не работает (код: $response)"
        return 1
    fi
}

# Функция перезапуска контейнера
restart_container() {
    local container_name="$1"
    local attempt="$2"
    
    log_message "🔄 Попытка $attempt перезапуска контейнера $container_name..."
    
    if docker restart "$container_name" >/dev/null 2>&1; then
        sleep 10
        if check_container "$container_name"; then
            log_message "✅ Контейнер $container_name успешно перезапущен"
            return 0
        fi
    fi
    
    log_message "❌ Не удалось перезапустить контейнер $container_name"
    return 1
}

# Основная функция проверки
main() {
    log_message "=== Начало проверки здоровья системы BenjForum ==="
    
    # Список критических контейнеров
    CRITICAL_CONTAINERS=("benjforum_postgres" "benjforum_redis" "benjforum_web" "benjforum_nginx")
    
    # Проверка контейнеров
    containers_ok=true
    for container in "${CRITICAL_CONTAINERS[@]}"; do
        if ! check_container "$container"; then
            containers_ok=false
            
            # Попытки перезапуска
            for attempt in $(seq 1 $MAX_RESTART_ATTEMPTS); do
                if restart_container "$container" "$attempt"; then
                    containers_ok=true
                    break
                fi
                sleep 5
            done
            
            if [ "$containers_ok" = false ]; then
                log_message "🚨 КРИТИЧЕСКАЯ ОШИБКА: Не удалось восстановить контейнер $container"
                exit 1
            fi
        fi
    done
    
    # Проверка веб-доступа
    if [ "$containers_ok" = true ]; then
        log_message "🌐 Проверка веб-доступа..."
        
        # Проверка HTTP
        if ! check_web_access "http://localhost" "200"; then
            log_message "⚠️ HTTP недоступен, проверяем HTTPS..."
            check_web_access "https://localhost" "200" || check_web_access "https://localhost" "301"
        fi
        
        # Проверка HTTPS
        check_web_access "https://localhost" "200" || check_web_access "https://localhost" "301"
        
        # Проверка внешнего IP
        check_web_access "http://84.21.189.163" "200"
        check_web_access "https://84.21.189.163" "200" || check_web_access "https://84.21.189.163" "301"
    fi
    
    # Статистика системы
    log_message "📊 Статистика системы:"
    log_message "   Контейнеры: $(docker ps --format '{{.Names}}' | wc -l) активных"
    log_message "   Использование диска: $(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')%"
    log_message "   Использование памяти: $(free | awk 'NR==2{printf "%.1f%%", $3/$2 * 100.0}')"
    
    log_message "=== Проверка здоровья системы завершена успешно ==="
}

# Проверка количества аргументов
if [ "$#" -eq 1 ] && [ "$1" = "--once" ]; then
    main
else
    # Запуск в бесконечном цикле с интервалом в 5 минут
    log_message "🚀 Запуск мониторинга BenjForum (интервал: 5 минут)"
    while true; do
        main
        sleep 300  # 5 минут
    done
fi