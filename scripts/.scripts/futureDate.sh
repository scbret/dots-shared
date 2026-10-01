#!/bin/bash

# Get the start date from the user
echo "Enter start date (YYYY-MM-DD):"
read startDate

# Get the number of days to add from the user
echo "Enter number of days to add:"
read addDays

# Calculate the new date using the 'date' command with date math
newDate=$(date -d "$startDate + $addDays days" +%Y-%m-%d)

# Output the result
echo "New Date: $newDate"

