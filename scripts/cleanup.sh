#!/bin/bash

# --- User-level ---

# Clipboard
cliphist wipe 2>/dev/null
wl-copy --clear 2>/dev/null

# /tmp (user-owned)
tmp_count=$(find /tmp -user "$USER" ! -path "/tmp" 2>/dev/null | wc -l)
find /tmp -user "$USER" -delete 2>/dev/null

# Thumbnails
thumb_count=$(find "$HOME/.cache/thumbnails" -type f 2>/dev/null | wc -l)
rm -rf "$HOME/.cache/thumbnails/"* 2>/dev/null

# Shader cache (Mesa / NVIDIA)
rm -rf "$HOME/.cache/mesa_shader_cache" 2>/dev/null
rm -rf "$HOME/.cache/nv/"* 2>/dev/null

# Broken symlinks in ~/.config
symlink_count=$(find "$HOME/.config" -xtype l 2>/dev/null | wc -l)
find "$HOME/.config" -xtype l -delete 2>/dev/null

# npm cache
if command -v npm &>/dev/null; then
    npm cache clean --force 2>/dev/null
    npm_cleaned="yes"
fi

# pip cache
if command -v pip &>/dev/null; then
    pip cache purge 2>/dev/null
    pip_cleaned="yes"
fi

# cargo cache
if command -v cargo &>/dev/null; then
    cargo cache --autoclean 2>/dev/null
    cargo_cleaned="yes"
fi

# AUR build cache (yay)
if [ -d "$HOME/.cache/yay" ]; then
    aur_size=$(du -sh "$HOME/.cache/yay" 2>/dev/null | cut -f1)
    rm -rf "$HOME/.cache/yay/"*/
    aur_cleaned="yes"
fi

# --- Root-level ---
free_before=$(free -h | awk '/^Mem:/{print $4}')
priv_out=$(sudo /home/haidd-dev/.config/hypr/scripts/cleanup-privileged.sh 2>/dev/null)
free_after=$(free -h | awk '/^Mem:/{print $4}')

pkg_cache=$(echo "$priv_out" | grep '^PKG_CACHE:' | cut -d: -f2)
orphans=$(echo "$priv_out" | grep '^ORPHANS:' | cut -d: -f2)
journal=$(echo "$priv_out" | grep '^JOURNAL:' | cut -d: -f2)
coredumps=$(echo "$priv_out" | grep '^COREDUMPS:' | cut -d: -f2)

# --- Build notification ---
body="Clipboard cleared"
body+="\n/tmp: ${tmp_count} items removed"
body+="\nThumbnails: ${thumb_count} files removed"
body+="\nBroken symlinks: ${symlink_count} removed"
body+="\nShader cache cleared"
[ -n "$npm_cleaned" ]   && body+="\nnpm cache cleaned"
[ -n "$pip_cleaned" ]   && body+="\npip cache cleaned"
[ -n "$cargo_cleaned" ] && body+="\ncargo cache cleaned"
[ -n "$aur_cleaned" ]   && body+="\nAUR cache cleared: ${aur_size}"
body+="\nPacman cache: ${pkg_cache} remaining"
[ "$orphans" != "0" ]   && body+="\nOrphans removed: ${orphans}" || body+="\nOrphans: none"
body+="\nJournal: ${journal} remaining"
body+="\nCoredumps: ${coredumps} removed"
body+="\nRAM: ${free_before} → ${free_after} free"

notify-send "Cleanup Done" "$body" -t 7000
echo "done"
