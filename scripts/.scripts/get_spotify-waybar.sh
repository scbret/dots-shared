#!/bin/bash
# get_spotify-waybar.sh — one-shot for Waybar

# Prefer the specific Spotify player; fall back to any MPRIS player named spotify
PLAYER="spotify"

status=$(playerctl -p "$PLAYER" status 2>/dev/null || echo "NoPlayer")

if [ "$status" = "Playing" ] || [ "$status" = "Paused" ]; then
  artist=$(playerctl -p "$PLAYER" metadata artist 2>/dev/null)
  album=$(playerctl -p "$PLAYER" metadata album 2>/dev/null)
  title=$(playerctl -p "$PLAYER" metadata title 2>/dev/null)
  # Fallbacks in case any field is missing
  [ -z "$artist" ] && artist="Unknown Artist"
  [ -z "$album" ] && album="Unknown Album"
  [ -z "$title" ] && title="Unknown Title"
  echo "$artist - $album - $title"
else
  # Icon when not playing / no player
  echo "󰝛"
fi
