#!/bin/bash

# --- Configuration ---
OUT_FILE="/tmp/wttr"
TEMP_FILE="/tmp/wttr_tmp"
LOCATION="Mason+City"

# This is what shows when the internet is down.
# You can paste a Nerd Font icon here (e.g.,  , 睊 , or  )
OFFLINE_ICON="⚠️" 

# --- Execution ---

# 1. Try to fetch weather
if curl -sf --max-time 10 "wttr.in/$LOCATION?u&format=%m+%C,+H:%h,+A:%t,+F:%f,+W:%w\n" > "$TEMP_FILE"; then
    mv "$TEMP_FILE" "$OUT_FILE"

else
    # 2. If it failed, wait 2 seconds and try one last time
    sleep 2
    if curl -sf --max-time 10 "wttr.in/$LOCATION?u&format=%m+%C,+H:%h,+A:%t,+F:%f,+W:%w\n" > "$TEMP_FILE"; then
        mv "$TEMP_FILE" "$OUT_FILE"
    else
        # 3. If it still fails, print the icon
        echo "$OFFLINE_ICON" > "$TEMP_FILE"
        mv "$TEMP_FILE" "$OUT_FILE"
    fi
fi
