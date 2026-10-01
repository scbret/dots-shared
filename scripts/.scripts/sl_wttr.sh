#!/bin/bash

# Check if the file exists before trying to read it
if [ -f "/tmp/wttr" ]; then
    cat /tmp/wttr
else
    echo "..." # Display a loading text if the file doesn't exist yet
fi
