#!/bin/sh

PID_FILE="/tmp/wlsunset.pid"

# Kill all wlsunset processes first
pkill -x wlsunset

# Check if PID file exists and process was running
if [ -f "$PID_FILE" ]; then
    rm -f "$PID_FILE"
    # Reset color temperature without starting new process
    # Use a short fade to reset instantly
    wlsunset -l 56.95 -L 24.1 -d 0.1 &
    sleep 0.2
    pkill -x wlsunset
    notify-send -t 1000 "wlsunset" "Disabled ☀️"
else
    # Start wlsunset
    wlsunset -l 56.95 -L 24.1 &
    echo "$!" > "$PID_FILE"
    notify-send -t 1000 "wlsunset" "Enabled 🌙"
fi

# Refresh Waybar
pkill -SIGRTMIN+1 waybar
