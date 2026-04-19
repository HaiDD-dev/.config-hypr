#!/usr/bin/env bash
UPDATE_FILE="$HOME/.cache/qs_update_pending"
ARCH_CACHE="/var/lib/pacman/db.lck"

if [ -f "$ARCH_CACHE" ]; then
    echo "0"
    return
fi

UPDATES=$(pacman -Sup 2>/dev/null | grep -v '^::' | grep -c '\.pkg\.tar\.zst$')
if [ -n "$UPDATES" ] && [ "$UPDATES" -gt 0 ]; then
    echo "$UPDATES" > "$UPDATE_FILE"
    echo "$UPDATES"
else
    rm -f "$UPDATE_FILE"
    echo "0"
fi