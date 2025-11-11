#!/bin/bash

# Your OpenWeatherMap API key
API_KEY="036e0dfa07677fbab9bb06a485e5b54e"

# City for which you want the weather forecast
CITY="Mason%20City"
STATE="IA"
COUNTRY_CODE="US"

# Base URL for the OpenWeatherMap API
BASE_URL="http://api.openweathermap.org/data/2.5/weather?"

# Construct the full URL to call the API
URL="${BASE_URL}q=${CITY},${STATE},${COUNTRY_CODE}&appid=${API_KEY}&units=imperial"

# Use curl to make the API request and parse the JSON response with jq
response=$(curl -s "$URL")

# Check if the response contains an error message
if echo "$response" | grep -q '"message"'; then
  error_message=$(echo "$response" | jq -r '.message')
  echo "Error: $error_message"
  exit 1
fi

# Extract weather information using jq
city_name=$(echo "$response" | jq -r '.name')
temperature=$(echo "$response" | jq -r '.main.temp')
weather_description=$(echo "$response" | jq -r '.weather[0].description')
humidity=$(echo "$response" | jq -r '.main.humidity')
wind_speed=$(echo "$response" | jq -r '.wind.speed')
wind_deg=$(echo "$response" | jq -r '.wind.deg')

# Convert wind degrees to compass direction
get_wind_direction() {
  local deg=$1
  local dirs=("N" "NE" "E" "SE" "S" "SW" "W" "NW")
  local idx=$(((deg + 22) / 45 % 8))
  echo "${dirs[$idx]}"
}

wind_dir=$(get_wind_direction "$wind_deg")

# Display the weather information
echo "Weather in $city_name, $STATE:"
echo "Temperature: $temperature°F"
echo "Description: $weather_description"
echo "Humidity: $humidity%"
echo "Wind: $wind_speed mph from $wind_dir"
