#!/usr/bin/env bash
PIPE="/tmp/qs_bright_wait_$$.fifo"
mkfifo "$PIPE" 2>/dev/null
trap 'rm -f "$PIPE"; kill $(jobs -p) 2>/dev/null; exit 0' EXIT INT TERM
if command -v brightnessctl &> /dev/null; then
    brightnessctl --monitor 2>/dev/null > "$PIPE" &
fi
read -r _ < "$PIPE"