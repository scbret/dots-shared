#!/usr/bin/env bash

# Change directory to /repos/journal
cd /home/steve/repos/journal || exit

# Push changes to the remote repository
git pull
sleep 2
# cd back to home
cd  /home/steve || exit

notify-send "Journal pull update complete!"
