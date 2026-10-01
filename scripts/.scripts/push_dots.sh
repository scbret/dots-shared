#!/usr/bin/env bash

# Change directory to /dotfiles
cd /home/steve/dotfiles || exit

# get hostname of device being run on
hostname=$(hostnamectl | awk -F ': ' '/Static hostname/ {print $2}')
sleep 2
# Add all changes to the staging area
git add .
sleep 2
# Commit changes
git commit -m "$hostname"
sleep 4
# Push changes to the remote repository
git push
sleep 2
# cd back to home
cd /home/steve || exit

notify-send "Dotfiles push update complete!"
