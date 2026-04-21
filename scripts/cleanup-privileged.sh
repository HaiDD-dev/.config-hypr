#!/bin/bash
# Runs as root via sudo NOPASSWD

# RAM cache
sync
echo 3 > /proc/sys/vm/drop_caches

# Pacman package cache (full clear)
pacman -Scc --noconfirm 2>/dev/null
pkg_size=$(du -sh /var/cache/pacman/pkg 2>/dev/null | cut -f1)
echo "PKG_CACHE:${pkg_size}"

# Orphan packages
orphans=$(pacman -Qtdq 2>/dev/null)
if [ -n "$orphans" ]; then
    orphan_count=$(echo "$orphans" | wc -l)
    pacman -Rns $orphans --noconfirm 2>/dev/null
    echo "ORPHANS:${orphan_count}"
else
    echo "ORPHANS:0"
fi

# Journal logs (keep last 7 days)
journalctl --vacuum-time=7d 2>/dev/null
journal_size=$(journalctl --disk-usage 2>/dev/null | grep -oP '[\d.]+[KMG]' | tail -1)
echo "JOURNAL:${journal_size:-?}"

# Coredumps
coredump_count=$(ls /var/lib/systemd/coredump/ 2>/dev/null | wc -l)
rm -rf /var/lib/systemd/coredump/* 2>/dev/null
echo "COREDUMPS:${coredump_count}"
