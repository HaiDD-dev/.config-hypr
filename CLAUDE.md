# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Reload / Apply Changes

```bash
# Hot-reload the quickshell UI (TopBar + Main overlay)
~/.config/hypr/scripts/reload.sh          # touches both QML files → quickshell picks up changes

# Reload Hyprland config (keybinds, window rules, etc.)
hyprctl reload

# Restart a specific quickshell process if reload isn't enough
pkill -f "quickshell.*TopBar" && quickshell -p ~/.config/hypr/scripts/quickshell/TopBar.qml &
pkill -f "quickshell.*Main"   && quickshell -p ~/.config/hypr/scripts/quickshell/Main.qml &
```

Settings changes in `settings.json` apply live — the file is watched by inotifywait in both `Main.qml` and `scripts/settings_watcher.sh`.

## Architecture

### Two-process Quickshell UI

The UI runs as two independent `quickshell` processes:

| Process | Entry point | Role |
|---|---|---|
| **TopBar** | `scripts/quickshell/TopBar.qml` | Per-screen top panel (`Variants` over `Quickshell.screens`). Handles bar icons, workspace indicators, morph mask for the settings sidebar. |
| **Main** | `scripts/quickshell/Main.qml` | Full-screen invisible overlay. Owns the `StackView` that renders all popup widgets, the `NotificationServer`, and the IPC file watcher. |

`qs_manager.sh` acts as a watchdog — it restarts either process if it's not running, then routes the IPC command.

### IPC: `/tmp/qs_widget_state`

Shell scripts open/close popups by writing to this file:

```bash
echo "toggle:volume"          > /tmp/qs_widget_state
echo "open:network:wifi"      > /tmp/qs_widget_state
echo "close"                  > /tmp/qs_widget_state
```

`Main.qml` watches it with `inotifywait`. Use `qs_manager.sh` rather than writing directly — it handles pre-work (bluetooth scan, wallpaper thumbnail generation, etc.) and runs the watchdog.

### Widget Registry (`scripts/quickshell/WindowRegistry.js`)

All popup widget names, QML component paths, and layout dimensions (position + size, scaled to screen width) are declared in `getLayout()`. **To add a new popup widget, add an entry here** and create the corresponding QML file in its own subdirectory under `scripts/quickshell/`.

### Scaling

`Scaler.qml` and `WindowRegistry.js::getScale()` derive a `baseScale` from screen width relative to 1920px. The `s(val)` helper converts logical sizes to physical pixels. `settings.json::uiScale` is a user multiplier on top of this. Always use `s()` for sizes in TopBar; use the registry's scale for popup layouts.

### Colors

`MatugenColors.qml` exposes the matugen-generated palette (sourced from `scripts/quickshell/qs_colors.json`). Wallpaper changes regenerate this file via `scripts/quickshell/wallpaper/matugen_reload.sh`, which causes the UI to re-read colors.

### Watchers (`scripts/quickshell/watchers/`)

Each system resource (audio, battery, brightness, Bluetooth, network, etc.) has two scripts:
- `*_fetch.sh` — one-shot read of current state (stdout → QML `Process`)
- `*_wait.sh` — blocks until state changes, then exits (used to trigger re-fetch)

QML components pair these: run `wait`, on exit run `fetch`, then restart `wait`.

### Runtime Settings (`settings.json`)

```json
{ "uiScale": 1, "workspaceCount": 5, "wallpaperDir": "...", "language": "us", "kbOptions": "" }
```

Changing this file propagates live to the UI. `scripts/settings_watcher.sh` applies keyboard layout changes via `hyprctl` on write.

### Key External Tools

| Tool | Purpose |
|---|---|
| `hyprctl` | Hyprland IPC (dispatch, keyword, reload) |
| `quickshell` | QML shell runtime |
| `wpctl` / `pactl` | Audio (PipeWire) |
| `brightnessctl` | Backlight |
| `playerctl` | MPRIS media |
| `cliphist` | Clipboard history |
| `awww` / `mpvpaper` | Wallpaper |
| `matugen` | Color scheme generation from wallpaper |
| `nmcli` / `bluetoothctl` | Network / Bluetooth |
| `swayosd-server` | OSD overlays (volume/brightness visuals) |
