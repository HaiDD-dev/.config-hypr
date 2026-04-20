#!/usr/bin/env bash

SELECTED=$(cliphist list | wofi --dmenu \
    -p "Clipboard" \
    -config ~/.config/rofi/config.rasi \
    -theme-str 'listview { columns: 1; spacing: 10px; }' \
    -theme-str 'element { orientation: vertical; children: [ element-icon, element-text ]; padding: 15px; }' \
    -theme-str 'element-icon { size: 48px; }' \
    -theme-str 'element-text { enabled: true; vertical-align: 0.5; horizontal-align: 0.0; margin: 0; text-color: inherit; }' \
)

[ -z "$SELECTED" ] && exit 0

MIME=$(echo "$SELECTED" | cliphist decode --print0 | xargs -0 wl-paste -l | head -1)

if echo "$MIME" | grep -q "image"; then
    TMPDIR=$(mktemp -d)
    IMAGE_FILE="$TMPDIR/clipboard_image.png"
    echo "$SELECTED" | cliphist decode > "$IMAGE_FILE"

    if command -v imv &>/dev/null; then
        imv "$IMAGE_FILE"
    elif command -v swayimg &>/dev/null; then
        swayimg "$IMAGE_FILE"
    elif command -v feh &>/dev/null; then
        feh "$IMAGE_FILE"
    elif command -v NSxiv &>/dev/null; then
        NSxiv "$IMAGE_FILE"
    elif command -v sxiv &>/dev/null; then
        sxiv "$IMAGE_FILE"
    else
        python3 -c "
import tkinter as tk
from tkinter import Label, Canvas
from PIL import Image, ImageTk
import sys

root = tk.Tk()
root.title('Clipboard Image')

try:
    img = Image.open('$IMAGE_FILE')
    photo = ImageTk.PhotoImage(img)

    canvas = Canvas(root, width=photo.width(), height=photo.height(), bg='white')
    canvas.create_image(0, 0, anchor='nw', image=photo')
    canvas.pack()

    root.mainloop()
except Exception as e:
    print(f'Error: {e}', file=sys.stderr)
    root.destroy()
"
    fi

    rm -rf "$TMPDIR"
else
    echo "$SELECTED" | cliphist decode | wl-copy
    notify-send "Copied to clipboard" "$SELECTED"
fi