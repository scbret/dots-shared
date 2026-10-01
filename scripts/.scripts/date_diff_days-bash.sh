#!/usr/bin/env bash

# Function to calculate the difference in days between two dates
date_diff() {
  local date1="$1"
  local date2="$2"
  
  # Convert dates to seconds since the epoch
  local date1_sec=$(date -d "$date1" "+%s")
  local date2_sec=$(date -d "$date2" "+%s")
  
  # Calculate the difference in seconds and convert to days
  local diff_sec=$((date2_sec - date1_sec))
  local diff_days=$((diff_sec / 86400))
  
  # Adjust for inclusive range
  if [ "$diff_sec" -ge 0 ]; then
    diff_days=$((diff_days + 1))
  else
    diff_days=$((diff_days - 1))
  fi
  
  echo "The difference between $date1 and $date2 is $diff_days days."
}

# Prompt the user for the first date
echo "Enter the first date (YYYY-MM-DD):"
read date1

# Prompt the user for the second date
echo "Enter the second date (YYYY-MM-DD):"
read date2

# Calculate and display the difference in days
date_diff "$date1" "$date2"

