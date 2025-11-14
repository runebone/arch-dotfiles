#!/bin/bash

# Находим процесс с наибольшим потреблением памяти (исключая systemd и kernel threads)
top_process=$(ps aux --sort=-%mem | awk 'NR>1 && $11 !~ /^\[/ {print $2, $11, $4; exit}')

if [ -z "$top_process" ]; then
    echo '{"text": "N/A", "tooltip": "No processes found"}'
    exit 0
fi

pid=$(echo "$top_process" | awk '{print $1}')
name=$(echo "$top_process" | awk '{print $2}' | xargs basename)
mem=$(echo "$top_process" | awk '{print $3}')

# Получаем дополнительную информацию для tooltip
mem_mb=$(ps -p "$pid" -o rss= | awk '{printf "%.0f", $1/1024}')
cpu=$(ps -p "$pid" -o %cpu= | xargs)

# Форматируем вывод для waybar
echo "{\"text\": \"$name ${mem}%\", \"tooltip\": \"PID: $pid\nName: $name\nMEM: ${mem}% (${mem_mb}MB)\nCPU: ${cpu}%\n\nClick to kill\"}"
