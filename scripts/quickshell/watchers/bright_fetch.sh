#!/usr/bin/env bash

get_brightness() {
    local bright=""
    if command -v brightnessctl &> /dev/null; then
        bright=$(brightnessctl -m -d intel_backlight get 2>/dev/null || brightnessctl get 2>/dev/null)
        if [ -n "$bright" ]; then
            local max=$(brightnessctl -m -d intel_backlight max 2>/dev/null || brightnessctl max 2>/dev/null)
            if [ -n "$max" ] && [ "$max" -gt 0 ]; then
                bright=$((bright * 100 / max))
            fi
        fi
    fi
    echo "${bright:-100}"
}

get_brightness_icon() {
    echo "󰛩"
}

case $1 in
    --toggle) 
        if command -v brightnessctl &> /dev/null; then
            brightnessctl set 10%+ 2>/dev/null
            notify-send -u low -i brightness "Brightness" "$(get_brightness)%"
        fi
        ;;
    --up) 
        if command -v brightnessctl &> /dev/null; then
            brightnessctl set 1%+ 2>/dev/null
        fi
        ;;
    --down) 
        if command -v brightnessctl &> /dev/null; then
            brightnessctl set 1%- 2>/dev/null
        fi
        ;;
    *) jq -n -c --arg brightness "$(get_brightness)" --arg icon "$(get_brightness_icon)" '{brightness: $brightness, icon: $icon}' ;;
esac