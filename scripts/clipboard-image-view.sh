#!/usr/bin/env bash
TMPDIR=$(mktemp -d)
IMAGE_FILE="$TMPDIR/clipboard_image.png"

wl-paste -t image/png > "$IMAGE_FILE" 2>/dev/null

[ ! -s "$IMAGE_FILE" ] && notify-send "No image in clipboard" && rm -rf "$TMPDIR" && exit 1

if command -v imv &>/dev/null; then
    imv "$IMAGE_FILE"
elif command -v swayimg &>/dev/null; then
    swayimg "$IMAGE_FILE"
elif command -v feh &>/dev/null; then
    feh "$IMAGE_FILE"
else
    python3 -c "
import tkinter as tk
from PIL import Image, ImageTk

root = tk.Tk()
root.title('Clipboard Image')

try:
    img = Image.open('$IMAGE_FILE')
    photo = ImageTk.PhotoImage(img)
    canvas = tk.Canvas(root, width=photo.width(), height=photo.height())
    canvas.create_image(0, 0, anchor='nw', image=photo)
    canvas.pack()
    root.mainloop()
except:
    root.destroy()
"
fi

rm -rf "$TMPDIR"