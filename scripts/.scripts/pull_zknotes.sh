#!/usr/bin/env bash

# Change directory to /repos/zk-notes
cd /home/steve/repos/zk-notes || exit

# Push changes to the remote repository
git pull
sleep 2
# cd back to home
cd  /home/steve || exit

notify-send "zk-notes pull update complete!"
