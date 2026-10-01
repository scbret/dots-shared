#!/usr/bin/env bash
# Smart Vimwiki launcher (desktop-friendly)
# Name: vimwiki-app

if command -v alacritty >/dev/null 2>&1; then
  # Detect GUI (Wayland or X11)
  if [ -n "$WAYLAND_DISPLAY" ] || [ -n "$DISPLAY" ] || [ "${XDG_SESSION_TYPE}" = "wayland" ] || [ "${XDG_SESSION_TYPE}" = "x11" ]; then
    exec alacritty --class VW -e nvim -c VimwikiIndex
  else
    printf '%s\n' 'Alacritty is installed but no GUI session detected. Falling back to nvim.'
  fi
fi

exec nvim -c VimwikiIndex
