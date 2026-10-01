#!/usr/bin/env bash

# Change directory to /repos/linux/mdnotes
cd /home/steve/repos/linux/mdnotes || exit

# Push changes to the remote repository
git pull
sleep 2
# cd back to home
cd  /home/steve || exit

notify-send "mdnotes pull update complete!"
