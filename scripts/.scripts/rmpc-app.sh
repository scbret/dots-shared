#!/usr/bin/env bash
# Smart rmpc launcher (desktop-friendly)
# Name: rmpc-app

if command -v kitty >/dev/null 2>&1; then
  # Detect GUI (Wayland or X11)
  if [ -n "$WAYLAND_DISPLAY" ] || [ -n "$DISPLAY" ] || [ "${XDG_SESSION_TYPE}" = "wayland" ] || [ "${XDG_SESSION_TYPE}" = "x11" ]; then
    exec kitty --class RMPC -e rmpc
  else
    printf '%s\n' 'kitty is installed but no GUI session detected. Falling back to nvim.'
  fi
fi

exec rmpc
