#!/bin/bash
# -----------------------------------------------------------
#  zk-wmap-weather.sh
#  Fetches current weather + air quality using OpenWeatherMap
#  Logs output for debugging and inserts summary into ZK notes
# -----------------------------------------------------------

# Log setup
LOG_DIR="$HOME/.zk-logs"
LOG_FILE="$LOG_DIR/weather.log"
mkdir -p "$LOG_DIR"

# Rotate logs older than 7 days
find "$LOG_DIR" -name "*.log" -mtime +7 -delete >/dev/null 2>&1

{
  echo "#### Weather Time: $(date '+%Y-%m-%d %H:%M:%S')  "

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
  
  
  # Display the weather information
  echo -e "Weather in ${city_name}, ${STATE} 📍 ${RESET}"
  echo -e "Temperature:${RESET} ${temperature}°F 🌡️ ${RESET}"
  echo -e "Description:${RESET} ${weather_description} ☁️ "
  echo -e "Humidity:${RESET} ${humidity}% 💧 "
  echo -e "Wind:${RESET} ${wind_speed} mph from ${wind_dir} 🌬️ "
  echo -e "Wind Gust:${RESET} ${wind_gust} mph 🌬️ "
  echo -e "Visibility:${RESET} ${visibility_miles} miles 👁️ "
  echo -e "Cloud Cover:${RESET} ${cloud_cover}% ☁️ "
  
  # --- AIR QUALITY SECTION ---
  echo
  echo -e "#### Air Quality Data...${RESET}  "
  
  aq_url="http://api.openweathermap.org/data/2.5/air_pollution?lat=${lat}&lon=${lon}&appid=${API_KEY}"
  aq_response=$(curl -s "$aq_url")
  
  if echo "$aq_response" | grep -q '"list"'; then
    aqi=$(echo "$aq_response" | jq -r '.list[0].main.aqi')
    pm2_5=$(echo "$aq_response" | jq -r '.list[0].components.pm2_5')
    pm10=$(echo "$aq_response" | jq -r '.list[0].components.pm10')
    o3=$(echo "$aq_response" | jq -r '.list[0].components.o3')
    co=$(echo "$aq_response" | jq -r '.list[0].components.co')
  
    case $aqi in
      1) aqi_desc="Good";  ;;
      2) aqi_desc="Fair";  ;;
      3) aqi_desc="Moderate";  ;;
      4) aqi_desc="Poor";  ;;
      5) aqi_desc="Very Poor";  ;;
      *) aqi_desc="Unknown";  ;;
    esac
  
    echo -e "Air Quality Index:${RESET} ${color}${aqi} (${aqi_desc})${RESET}  "
    echo -e "Fine Particles (PM2.5):${RESET} ${pm2_5} µg/m³  "
    echo -e "Coarse Particles (PM10):${RESET} ${pm10} µg/m³  "
    echo -e "Ozone - O₃:${RESET} ${o3} µg/m³  "
    echo -e "Carbon Monoxide (CO):${RESET} ${co} µg/m³  "
    echo " "
  else
    echo -e "\033[1;31m⚠️ Air quality data unavailable.\033[0m  "
  fi

 } 2>&1 | tee -a "$LOG_FILE" 
