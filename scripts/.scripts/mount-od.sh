#!/bin/bash

# Define the mount point path
MOUNT_POINT="$HOME/OneDrive"

# Function to check if OneDrive is mounted
check_mount() {
    if mountpoint -q "$MOUNT_POINT"; then
        # Additionally check if the mount is responsive
        if ls "$MOUNT_POINT" &>/dev/null; then
            return 0  # Mount exists and is responsive
        fi
    fi
    return 1  # Not mounted or not responsive
}

# Function to mount OneDrive
mount_onedrive() {
    echo "Mounting OneDrive..."
    nohup sh -c "rclone --vfs-cache-mode writes mount \"onedrive\": ~/OneDrive" > /dev/null 2>&1 &
    notify-send "OneDrive Mount" "OneDrive has been mounted to ~/OneDrive" -i usb-drive
}

# Create mount point directory if it doesn't exist
if [ ! -d "$MOUNT_POINT" ]; then
    mkdir -p "$MOUNT_POINT"
fi

# Main logic
if ! check_mount; then
    echo "OneDrive is not mounted or not responsive"
    # Check if there's already a mount process running
    if pgrep -f "rclone.*onedrive.*mount" > /dev/null; then
        echo "Rclone mount process is already running. Killing existing process..."
        pkill -f "rclone.*onedrive.*mount"
        sleep 2  # Wait for the process to terminate
    fi
    mount_onedrive
else
    echo "OneDrive is already mounted and responsive"
    notify-send "OneDrive Mount" "OneDrive is already mounted to ~/OneDrive" -i usb-drive
fi
