#!/usr/bin/env bash
PIPE="/tmp/qs_temp_wait_$$.fifo"
mkfifo "$PIPE" 2>/dev/null
trap 'rm -f "$PIPE"; kill $(jobs -p) 2>/dev/null; exit 0' EXIT INT TERM

# Failsafe: Force a refresh every 30 seconds
(sleep 30 && echo "timeout" > "$PIPE") &

read -r _ < "$PIPE"
sleep 0.05