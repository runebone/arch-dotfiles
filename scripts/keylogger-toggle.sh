#!/bin/bash
PID_FILE="/tmp/keylogger.pid"
SCRIPT="$HOME/.dotfiles/scripts/keylogger.py"

if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    kill "$(cat "$PID_FILE")"
    rm -f "$PID_FILE"
    notify-send -u normal "Keylogger" "Stopped" -i security-low
else
    python3 "$SCRIPT" &
    echo $! > "$PID_FILE"
    notify-send -u critical "Keylogger" "Started — logging input" -i security-high
fi
pkill -SIGRTMIN+1 waybar
