#!/usr/bin/env bash
# Network speed monitoring - returns download and upload speeds

NETDEV="/tmp/qs_netspeed"

get_netspeed() {
    local rx=0 tx=0
    for dev in /sys/class/net/*; do
        local iface=$(basename "$dev")
        [[ "$iface" == "lo" ]] && continue
        
        if [[ -f "$dev/statistics/rx_bytes" ]]; then
            rx=$((rx + $(cat "$dev/statistics/rx_bytes" 2>/dev/null || echo 0)))
            tx=$((tx + $(cat "$dev/statistics/tx_bytes" 2>/dev/null || echo 0)))
        fi
    done
    
    echo "$rx $tx"
}

format_speed() {
    local bytes=$1
    if [ "$bytes" -ge 1073741824 ] 2>/dev/null; then
        printf "%.1f" "$(echo "$bytes 1073741824" | awk '{print $1/$2}')"
        printf "G"
    elif [ "$bytes" -ge 1048576 ] 2>/dev/null; then
        printf "%.1f" "$(echo "$bytes 1048576" | awk '{print $1/$2}')"
        printf "M"
    elif [ "$bytes" -ge 512 ] 2>/dev/null; then
        printf "%.0f" "$(echo "$bytes 1024" | awk '{print $1/$2}')"
        printf "K"
    else
        echo "0"
    fi
}

curr_data=$(get_netspeed)
curr_rx=$(echo "$curr_data" | awk '{print $1}')
curr_tx=$(echo "$curr_data" | awk '{print $2}')

sleep 1

new_data=$(get_netspeed)
new_rx=$(echo "$new_data" | awk '{print $1}')
new_tx=$(echo "$new_data" | awk '{print $2}')

echo "$new_data" > "$NETDEV"

dl_speed=0
up_speed=0
dl_speed=0
up_speed=0

if [[ $new_rx -ge $curr_rx ]]; then
    dl_speed=$(( new_rx - curr_rx ))
fi

if [[ $new_tx -ge $curr_tx ]]; then
    up_speed=$(( new_tx - curr_tx ))
fi

# Format output
dl_formatted=$(format_speed "$dl_speed")
up_formatted=$(format_speed "$up_speed")

# Output JSON
jq -n -c \
    --arg dl "$dl_formatted" \
    --arg up "$up_formatted" \
    --arg dlRaw "$dl_speed" \
    --arg upRaw "$up_speed" \
    '{download: $dl, upload: $up, downloadRaw: ($dlRaw | tonumber), uploadRaw: ($upRaw | tonumber)}'