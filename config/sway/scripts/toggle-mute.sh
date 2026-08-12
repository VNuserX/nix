#!/bin/sh

# Toggle mute
pactl set-sink-mute @DEFAULT_SINK@ toggle

# Check status and notify
if pactl get-sink-mute @DEFAULT_SINK@ | grep -q "Mute: yes"; then
    notify-send -u low -t 1000 "🔇 Muted"
else
    notify-send -u low -t 1000 "🔊 Unmuted"
fi
