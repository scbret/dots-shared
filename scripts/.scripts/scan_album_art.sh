#!/usr/bin/env bash
# Scan a music library for albums with small embedded art and/or small folder cover files.
# Usage: scan_album_art.sh [ROOT_DIR(default=~/Music)] [THRESHOLD_PX(default=1000)]

set -euo pipefail

ROOT="${1:-$HOME/Music}"
THRESH="${2:-1000}" # min acceptable size (px)

# --- deps check (fail fast with a helpful message) ---
need() { command -v "$1" >/dev/null 2>&1 || {
  echo "Missing: $1"
  exit 1
}; }
need ffprobe
need identify
command -v metaflac >/dev/null 2>&1 || echo "Note: 'metaflac' not found; FLAC embedded art checks may be less reliable."

shopt -s nullglob

declare -A album_max          # album_dir -> max_px seen in embedded art
declare -A album_any_small    # album_dir -> 1 if any embedded < THRESH
declare -A album_folder_small # album_dir -> 1 if folder cover < THRESH

# Return the max dimension (px) of embedded art in a file, or non-zero if none.
get_dim() {
  local f="$1" dim w h

  # Try ffprobe on attached picture stream
  dim="$(ffprobe -v error -select_streams v:0 \
    -show_entries stream=width,height \
    -of csv=s=x:p=0 -- "$f" 2>/dev/null || true)"

  # If empty and it's FLAC, try extracting with metaflac then identify
  if [[ -z "${dim}" && "$f" == *.flac ]]; then
    if command -v metaflac >/dev/null 2>&1; then
      local tmp
      tmp="$(mktemp -t artXXXXXX.jpg)"
      if metaflac --export-picture-to="$tmp" -- "$f" >/dev/null 2>&1 && [[ -s "$tmp" ]]; then
        dim="$(identify -format '%wx%h' -- "$tmp" 2>/dev/null || true)"
      fi
      rm -f -- "$tmp"
    fi
  fi

  # If still empty, no embedded art
  [[ -n "${dim}" ]] || return 1

  # Some tools can print multiple lines; take the first token that looks like WxH
  dim="${dim%%$'\n'*}"
  [[ "$dim" =~ ^[0-9]+x[0-9]+$ ]] || return 1

  w="${dim%x*}"
  h="${dim#*x}"

  # Echo the larger side
  if ((w > h)); then
    echo "$w"
  else
    echo "$h"
  fi
}

check_folder_img() {
  local dir="$1" img dim w h m
  for img in "$dir"/{cover,folder}.{jpg,jpeg,png,JPG,JPEG,PNG}; do
    [[ -f "$img" ]] || continue
    dim="$(identify -format '%wx%h' -- "$img" 2>/dev/null || true)"
    [[ -n "$dim" && "$dim" =~ ^[0-9]+x[0-9]+$ ]] || continue
    w="${dim%x*}"
    h="${dim#*x}"
    m=$((w > h ? w : h))
    ((m < THRESH)) && return 0
  done
  return 1
}

# Walk the library and gather embedded art sizes
while IFS= read -r -d '' f; do
  dir="$(dirname -- "$f")"
  if max="$(get_dim "$f" 2>/dev/null)"; then
    # track per-album maximum
    if [[ -z "${album_max[$dir]:-}" || "$max" -gt "${album_max[$dir]}" ]]; then
      album_max["$dir"]="$max"
    fi
    # mark album if this track is small
    ((max < THRESH)) && album_any_small["$dir"]=1
  fi
done < <(find "$ROOT" -type f \
  \( -iname '*.mp3' -o -iname '*.m4a' -o -iname '*.flac' -o -iname '*.ogg' \) -print0)

# check folder images for each album we saw
for a in "${!album_max[@]}"; do
  if check_folder_img "$a"; then
    album_folder_small["$a"]=1
  fi
done

# report
printf '=== Albums needing attention (< %d px) ===\n' "$THRESH"
{
  for a in "${!album_max[@]}"; do
    need=""
    [[ -n "${album_any_small[$a]:-}" ]] && need="embedded"
    [[ -n "${album_folder_small[$a]:-}" ]] && need="${need:+$need & }folder"
    [[ -n "$need" ]] && printf '%s  [max embedded: %spx]  -> %s\n' "$a" "${album_max[$a]}" "$need"
  done
} | sort || true

echo
echo "Tip: Open these folders in Picard, remove & refetch cover art (Release Group if needed), Save, then run: mpc update"
