#!/usr/bin/env sh
set -eu

#folder="$HOME/repos/linux/mdnotes" # no trailing slash
folder="$HOME/repos/zk-notes/notes" # no trailing slash
mkdir -p "$folder"

open_note() {
  nvim -- "$1"
}

new_note() {
  printf "Enter a name (no extension): " 1>&2
  IFS= read -r name || name=""
  [ -z "${name:-}" ] && return 0
  case "$name" in
  *.md) note="$folder/$name" ;;
  *) note="$folder/$name.md" ;;
  esac
  open_note "$note"
}

list_files() {
  # Newest first, filenames only; safe with spaces
  find "$folder" -maxdepth 1 -type f -name '*.md' -printf '%T@ %f\n' |
    sort -nr |
    awk '{ $1=""; sub(/^ /,""); print }'
}

choose_and_open() {
  while :; do
    files="$(list_files || true)"

    if command -v fzf >/dev/null 2>&1; then
      choice=$( (
        printf '%s\n' "New"
        printf '%s\n' "$files"
      ) |
        fzf --prompt="Choose note or create new: " --height=55% --reverse --tac || true)
      case "${choice:-}" in
      "") break ;;
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
