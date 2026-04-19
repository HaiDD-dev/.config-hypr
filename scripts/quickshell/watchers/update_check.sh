#!/usr/bin/env bash
UPDATE_FILE="$HOME/.cache/qs_update_pending"
FORCE_FILE="$HOME/.cache/qs_update_force"

# Manual test override
if [ -f "$FORCE_FILE" ]; then
    cat "$FORCE_FILE"
    exit 0
fi

# Pacman DB locked — return cached value
if [ -f "/var/lib/pacman/db.lck" ]; then
    cat "$UPDATE_FILE" 2>/dev/null || echo "0"
    exit 0
fi

UPDATES=$(pacman -Sup 2>/dev/null | grep -v '^::' | grep -c '\.pkg\.tar\.zst$')
if [ -n "$UPDATES" ] && [ "$UPDATES" -gt 0 ]; then
    echo "$UPDATES" > "$UPDATE_FILE"
    echo "$UPDATES"
else
    rm -f "$UPDATE_FILE"
    echo "0"
fi
