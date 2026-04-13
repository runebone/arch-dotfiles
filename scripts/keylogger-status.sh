#!/bin/bash
PID_FILE="/tmp/keylogger.pid"
if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    echo '{"text": " ", "class": "active", "tooltip": ""}'
else
    echo '{"text": " ", "class": "inactive", "tooltip": ""}'
fi
