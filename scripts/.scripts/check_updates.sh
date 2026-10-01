#!/bin/bash

# Update the package database
sudo pacman -Sy --noconfirm &> /dev/null

# Check for upgradable packages and count them
upgradable_count=$(pacman -Qu | wc -l)

if [ "$upgradable_count" -eq 0 ]; then
    echo "No updates available."
else
    echo "Number of packages that can be updated: $upgradable_count"
fi
