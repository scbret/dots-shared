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
  echo -e "\033[1;31mError:\033[0m $error_message"
  exit 1
fi

# Extract weather information using jq
city_name=$(echo "$response" | jq -r '.name')
temperature=$(echo "$response" | jq -r '.main.temp')
weather_description=$(echo "$response" | jq -r '.weather[0].description')
humidity=$(echo "$response" | jq -r '.main.humidity')
wind_speed=$(echo "$response" | jq -r '.wind.speed')
wind_deg=$(echo "$response" | jq -r '.wind.deg')
wind_gust=$(echo "$response" | jq -r '.wind.gust // "N/A"')
visibility=$(echo "$response" | jq -r '.visibility // "N/A"')
cloud_cover=$(echo "$response" | jq -r '.clouds.all // "N/A"')
lat=$(echo "$response" | jq -r '.coord.lat')
lon=$(echo "$response" | jq -r '.coord.lon')

# Convert visibility from meters to miles (if numeric)
if [[ "$visibility" != "N/A" ]]; then
  visibility_miles=$(awk "BEGIN {printf \"%.2f\", $visibility / 1609.34}")
else
  visibility_miles="N/A"
fi

# Convert wind degrees to compass direction
get_wind_direction() {
  local deg=$1
  local dirs=("N" "NE" "E" "SE" "S" "SW" "W" "NW")
  local idx=$(((deg + 22) / 45 % 8))
  echo "${dirs[$idx]}"
}

wind_dir=$(get_wind_direction "$wind_deg")

# ANSI color codes
BOLD="\033[1m"
RESET="\033[0m"
BLUE="\033[34m"
CYAN="\033[36m"
YELLOW="\033[33m"
GREEN="\033[32m"
MAGENTA="\033[35m"
WHITE="\033[97m"

# Display the weather information
echo -e "${BOLD}${WHITE}Weather in ${CYAN}${city_name}, ${STATE}:${RESET}"
echo -e "${BLUE}Temperature:${RESET} ${BOLD}${temperature}°F${RESET}"
echo -e "${GREEN}Description:${RESET} ${weather_description}"
echo -e "${MAGENTA}Humidity:${RESET} ${humidity}%"
echo -e "${YELLOW}Wind:${RESET} ${wind_speed} mph from ${wind_dir}"
echo -e "${YELLOW}Wind Gust:${RESET} ${wind_gust} mph"
echo -e "${CYAN}Visibility:${RESET} ${visibility_miles} miles"
echo -e "${WHITE}Cloud Cover:${RESET} ${cloud_cover}%"

# --- AIR QUALITY SECTION ---
echo
echo -e "${BOLD}${WHITE}Fetching Air Quality Data...${RESET}"

aq_url="http://api.openweathermap.org/data/2.5/air_pollution?lat=${lat}&lon=${lon}&appid=${API_KEY}"
aq_response=$(curl -s "$aq_url")

if echo "$aq_response" | grep -q '"list"'; then
  aqi=$(echo "$aq_response" | jq -r '.list[0].main.aqi')
  pm2_5=$(echo "$aq_response" | jq -r '.list[0].components.pm2_5')
  pm10=$(echo "$aq_response" | jq -r '.list[0].components.pm10')
  o3=$(echo "$aq_response" | jq -r '.list[0].components.o3')
  co=$(echo "$aq_response" | jq -r '.list[0].components.co')

  case $aqi in
    1) aqi_desc="Good"; color="\033[32m" ;;    # Green
    2) aqi_desc="Fair"; color="\033[36m" ;;    # Cyan
    3) aqi_desc="Moderate"; color="\033[33m" ;; # Yellow
    4) aqi_desc="Poor"; color="\033[35m" ;;    # Magenta
    5) aqi_desc="Very Poor"; color="\033[31m" ;; # Red
    *) aqi_desc="Unknown"; color="\033[0m" ;;
  esac

  echo -e "${BOLD}${WHITE}Air Quality Index:${RESET} ${color}${aqi} (${aqi_desc})${RESET}"
  echo -e "${MAGENTA}Fine Particles (PM2.5):${RESET} ${pm2_5} µg/m³"
  echo -e "${MAGENTA}Coarse Particles (PM10):${RESET} ${pm10} µg/m³"
  echo -e "${MAGENTA}Ozone (O3):${RESET} ${o3} µg/m³"
  echo -e "${MAGENTA}Carbon Monoxide (CO):${RESET} ${co} µg/m³"
else
  echo -e "\033[1;31mAir quality data unavailable.\033[0m"
fi

