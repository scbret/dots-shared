#!/usr/bin/env bash

# Function to calculate the new date based on input date and number of days
calculate_new_date() {
  local start_date="$1"
  local days="$2"
  
  # Calculate the new date
  local new_date=$(date -d "$start_date +$days days" "+%Y-%m-%d")
  
  echo "The new date, after adding $days days to $start_date, is $new_date."
}

# Prompt the user for the starting date
echo "Enter the starting date (YYYY-MM-DD):"
read start_date

# Prompt the user for the number of days to add (use negative number to subtract days)
echo "Enter the number of days to add (use negative number to subtract days):"
read days

# Calculate and display the new date
calculate_new_date "$start_date" "$days"


