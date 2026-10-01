#!/usr/bin/env bash
set -euo pipefail

# Launch meteo-qt in the background
meteo-qt &

# --- Get primary monitor geometry (WxH+X+Y); fallback to first connected if no "primary"
geom_line=$(xrandr --query | awk '
  / connected primary / && match($0, /[0-9]+x[0-9]+\+[0-9]+\+[0-9]+/) {print substr($0, RSTART, RLENGTH); found=1}
  END { if (!found) exit 1 }')

if [[ -z "${geom_line:-}" ]]; then
  geom_line=$(xrandr --query | awk '
    / connected / && match($0, /[0-9]+x[0-9]+\+[0-9]+\+[0-9]+/) {print substr($0, RSTART, RLENGTH); exit}')
fi

# Parse WxH+X+Y
W=$(awk -v g="$geom_line" 'BEGIN { split(g,a,/[x+]/); print a[1] }')
H=$(awk -v g="$geom_line" 'BEGIN { split(g,a,/[x+]/); print a[2] }')
XOFF=$(awk -v g="$geom_line" 'BEGIN { split(g,a,/[x+]/); print a[3] }')
YOFF=$(awk -v g="$geom_line" 'BEGIN { split(g,a,/[x+]/); print a[4] }')

# Compute target size (integers): 60% × 40%, centered on that monitor
TW=$(awk -v w="$W" 'BEGIN { printf "%d", w*0.60 }')
TH=$(awk -v h="$H" 'BEGIN { printf "%d", h*0.40 }')
TX=$(awk -v w="$W" -v tw="$TW" -v xo="$XOFF" 'BEGIN { printf "%d", xo + (w - tw)/2 }')
TY=$(awk -v h="$H" -v th="$TH" -v yo="$YOFF" 'BEGIN { printf "%d", yo + (h - th)/2 }')

# Wait for the meteo-qt window (by WM_CLASS), up to ~5s
wid=""
for _ in $(seq 1 50); do
  # Match by class so title is irrelevant; -onlyvisible is not used in case it starts hidden
  if wid=$(xdotool search --class 'meteo-qt' 2>/dev/null | head -n1); then
    [[ -n "$wid" ]] && break
  fi
  sleep 0.1
done

# If not found yet, give it a tiny bit more time and try once more
if [[ -z "${wid:-}" ]]; then
  sleep 0.5
  wid=$(xdotool search --class 'meteo-qt' 2>/dev/null | head -n1 || true)
fi

# Resize/move if we found the window
if [[ -n "${wid:-}" ]]; then
  # Use wmctrl with -i (window id) to avoid title matching issues; gravity=0
  wmctrl -i -r "$wid" -e "0,${TX},${TY},${TW},${TH}"
else
  echo "Warning: Could not find meteo-qt window to resize."
fi

