#!/usr/bin/env bash

# Change directory to /repos/journal
cd /home/steve/dotfiles || exit

# Push changes to the remote repository
git pull
sleep 2
# cd back to home
cd  /home/steve || exit

notify-send "Dotfiles pull update complete!"
