#!/bin/sh

PID_FILE="/tmp/wlsunset.pid"

if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if kill -0 "$PID" 2>/dev/null; then
        echo " 🌙"
        exit 0
    else
        rm -f "$PID_FILE"
    fi
fi

echo " ☀️"
