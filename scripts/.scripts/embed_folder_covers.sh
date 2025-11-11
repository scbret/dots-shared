#!/usr/bin/env bash
# Re-embed folder cover images into MP3 tags across a music library.
# Uses eyeD3's "art" plugin to import from art files (-T).
# Dry-run by default; pass --apply to actually modify files.

set -euo pipefail

ROOT="${1:-$HOME/Music}"
APPLY=0
BACKUP=0

# Parse flags
for arg in "${@:2}"; do
  case "$arg" in
  --apply) APPLY=1 ;;
  --backup) BACKUP=1 ;;
  *)
    echo "Unknown option: $arg"
    exit 2
    ;;
  esac
done

need() { command -v "$1" >/dev/null 2>&1 || {
  echo "Missing: $1"
  exit 1
}; }
need eyeD3
need find

shopt -s nullglob

# Candidate cover filenames (add more if you use other names)
CANDIDATES=(cover.jpg cover.jpeg cover.png folder.jpg folder.jpeg folder.png front.jpg front.jpeg front.png)

changed=0
scanned=0
albums=0

printf 'Scanning: %s\n' "$ROOT"
printf '(dry-run by default; use --apply to write tags, --backup to keep *.orig files)\n\n'

# Find album-like directories (contain at least one mp3)
while IFS= read -r -d '' dir; do
  ((albums++)) || true
  cover=""
  for name in "${CANDIDATES[@]}"; do
    if [[ -f "$dir/$name" ]]; then
      cover="$dir/$name"
      break
    fi
  done

  if [[ -z "$cover" ]]; then
    printf '[skip] No cover file in: %s\n' "$dir"
    continue
  fi

  # Show what we'll do
  printf '[album] %s\n' "$dir"
  printf '        using cover: %s\n' "$(basename "$cover")"

  # Import that cover into each mp3 via art plugin (-T = update tags from art files)
  mp3s=("$dir"/*.mp3)
  if ((${#mp3s[@]} == 0)); then
    printf '        (no mp3 files here)\n\n'
    continue
  fi

  if ((APPLY == 1)); then
    for f in "${mp3s[@]}"; do
      if ((BACKUP == 1)); then
        eyeD3 --backup -P art -T "$f" >/dev/null || {
          echo "        !! eyeD3 failed on $f"
          continue
        }
      else
        eyeD3 -P art -T "$f" >/dev/null || {
          echo "        !! eyeD3 failed on $f"
          continue
        }
      fi
      ((changed++)) || true
    done
    printf '        -> embedded cover imported into %d file(s)\n\n' "${#mp3s[@]}"
  else
    printf '        (dry-run) would import into %d mp3 file(s)\n\n' "${#mp3s[@]}"
  fi

  ((scanned++)) || true
done < <(find "$ROOT" -type f -iname '*.mp3' -printf '%h\0' | sort -zu | uniq -z)

printf '\nSummary:\n'
printf '  Albums seen:   %d\n' "$albums"
printf '  Albums changed:%s\n' "$scanned"
if ((APPLY == 1)); then
  printf '  MP3s updated:  %d\n' "$changed"
else
  printf '  MP3s to update (if --apply): will vary by album\n'
fi

echo
echo "Next steps:"
echo "  1) Run again with --apply to actually write tags."
echo "  2) Then refresh MPD:  mpc update"
echo "  3) Clear rmpc cache:  rm -rf ~/.cache/rmpc"
