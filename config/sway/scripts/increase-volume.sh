#!/bin/sh

CURRENT=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '\d+(?=%)' | head -1)
STEP=5

case "$1" in
    up)
        if [ $CURRENT -lt 100 ]; then
            NEW_VOL=$((CURRENT + STEP))
            if [ $NEW_VOL -gt 100 ]; then
                pactl set-sink-volume @DEFAULT_SINK@ 100%
            else
                pactl set-sink-volume @DEFAULT_SINK@ +${STEP}%
            fi
        fi
        ;;
    down)
        pactl set-sink-volume @DEFAULT_SINK@ -${STEP}%
        ;;
    *)
        echo "Usage: $0 {up|down}"
        exit 1
        ;;
esac
