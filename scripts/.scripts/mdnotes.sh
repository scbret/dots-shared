#!/usr/bin/env sh
set -eu

#folder="$HOME/repos/linux/mdnotes" # no trailing slash
folder="$HOME/repos/zk-notes" # no trailing slash; notes are listed from all subfolders
newdir="$folder/notes"         # where new notes go unless a subfolder is given
mkdir -p "$newdir"

open_note() {
  nvim -- "$1"
}

new_note() {
  # Optional $1 is the name; without it, prompt for one.
  name="${1:-}"
  if [ -z "$name" ]; then
    printf "Enter a name (no extension; e.g. idea or jeep/oil-change): " 1>&2
    IFS= read -r name || name=""
  fi
  [ -z "${name:-}" ] && return 0
  case "$name" in
  */*) dir="$folder" ;; # subfolder given: relative to the zk-notes root
  *) dir="$newdir" ;;
  esac
  case "$name" in
  *.md) note="$dir/$name" ;;
  *) note="$dir/$name.md" ;;
  esac
  mkdir -p "$(dirname "$note")"
  open_note "$note"
}

list_files() {
  # Newest first, paths relative to $folder (e.g. jeep/foo.md); safe with spaces.
  # Skips .git and .zk (zk's config and templates).
  find "$folder" \( -name .git -o -name .zk \) -prune -o \
    -type f -name '*.md' -printf '%T@ %P\n' |
    sort -nr |
    awk '{ $1=""; sub(/^ /,""); print }'
}

choose_and_open() {
  while :; do
    files="$(list_files || true)"

    if command -v fzf >/dev/null 2>&1; then
      # --print-query: line 1 is what was typed, line 2 the selected entry.
      # Typing a name that matches nothing and pressing Enter gives only line 1,
      # which creates a new note with that name. Esc gives nothing and quits.
      out=$( (
        printf '%s\n' "New"
        printf '%s\n' "$files"
      ) |
        fzf --print-query --prompt="Choose note or type a new name: " --height=55% --reverse --tac || true)
      query=$(printf '%s\n' "$out" | sed -n 1p)
      choice=$(printf '%s\n' "$out" | sed -n 2p)
      case "${choice:-}" in
      "")
        [ -z "$query" ] && break
        new_note "$query"
        ;;
      "New") new_note ;;
      *".md") open_note "$folder/$choice" ;;
      esac
    else
      echo "Choose note or create new:"
      echo "  0) New"
      i=1
      # shellcheck disable=SC2086
      for f in $files; do
        printf "  %d) %s\n" "$i" "$f"
        i=$((i + 1))
      done
      printf "Enter a number (blank to quit): " 1>&2
      IFS= read -r ans || break
      case "${ans:-}" in
      "") break ;;
      0) new_note ;;
      *[!0-9]*)
        echo "Not a number, exiting." >&2
        break
        ;;
      *)
        idx="$ans"
        j=1
        sel=""
        # shellcheck disable=SC2086
        for f in $files; do
          [ "$j" -eq "$idx" ] && sel="$f" && break
          j=$((j + 1))
        done
        [ -z "$sel" ] && {
          echo "Invalid selection."
          continue
        }
        open_note "$folder/$sel"
        ;;
      esac
    fi
  done
}

choose_and_open
