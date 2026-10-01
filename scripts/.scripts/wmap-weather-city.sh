#!/bin/bash

# Your OpenWeatherMap API key
API_KEY="036e0dfa07677fbab9bb06a485e5b54e"

# --- DEFAULT LOCATION ---
DEFAULT_CITY="Mason City"
DEFAULT_STATE="IA"
COUNTRY_CODE="US"

# --- USER INPUT SECTION ---
echo "----------------------------------------"
echo " Weather & Air Quality Report"
echo "----------------------------------------"
echo "Press ENTER to use default: ${DEFAULT_CITY}, ${DEFAULT_STATE}"
read -p "Enter city name (or leave blank for default): " CITY_INPUT

if [ -z "$CITY_INPUT" ]; then
  CITY_INPUT="$DEFAULT_CITY"
  STATE="$DEFAULT_STATE"
  echo "Using default city: ${CITY_INPUT}, ${STATE}"
else
  read -p "Enter state code (e.g. IA): " STATE
fi

# URL encode the city name (replace spaces with %20)
CITY=$(echo "$CITY_INPUT" | sed 's/ /%20/g')

# Base URL for the OpenWeatherMap API
BASE_URL="http://api.openweathermap.org/data/2.5/weather?"
URL="${BASE_URL}q=${CITY},${STATE},${COUNTRY_CODE}&appid=${API_KEY}&units=imperial"

# Request data
response=$(curl -s "$URL")

# Check for API errors
if echo "$response" | grep -q '"message"'; then
  error_message=$(echo "$response" | jq -r '.message')
  echo -e "\033[1;31mError:\033[0m $error_message"
  exit 1
fi

# Extract data
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

# --- PRECIPITATION ---
rain_1h=$(echo "$response" | jq -r '.rain["1h"] // 0')
rain_3h=$(echo "$response" | jq -r '.rain["3h"] // 0')
snow_1h=$(echo "$response" | jq -r '.snow["1h"] // 0')
snow_3h=$(echo "$response" | jq -r '.snow["3h"] // 0')
mm_to_in() { awk "BEGIN {printf \"%.2f\", ($1)/25.4}"; }
rain_1h_in=$(mm_to_in "$rain_1h")
rain_3h_in=$(mm_to_in "$rain_3h")
snow_1h_in=$(mm_to_in "$snow_1h")
snow_3h_in=$(mm_to_in "$snow_3h")

# Visibility miles
if [[ "$visibility" != "N/A" ]]; then
  visibility_miles=$(awk "BEGIN {printf \"%.2f\", $visibility / 1609.34}")
else
  visibility_miles="N/A"
fi

# Wind direction compass
get_wind_direction() {
  local deg=$1
  if [[ -z "$deg" || "$deg" == "null" ]]; then echo "N/A"; return; fi
  local dirs=("N" "NE" "E" "SE" "S" "SW" "W" "NW")
  local idx=$(((deg + 22) / 45 % 8))
  echo "${dirs[$idx]}"
}
wind_dir=$(get_wind_direction "$wind_deg")

# Colors
BOLD="\033[1m"; RESET="\033[0m"
BLUE="\033[34m"; CYAN="\033[36m"; YELLOW="\033[33m"; GREEN="\033[32m"; MAGENTA="\033[35m"; WHITE="\033[97m"; RED="\033[31m"

# Temperature color scale
TEMP_COLOR="$WHITE"
temp_int=$(awk -v t="${temperature}" 'BEGIN {if(t==""||t=="null"){print"nan";exit} gsub(",",".",t); printf "%.0f", t}')
if [[ "$temp_int" != "nan" ]]; then
  if   (( temp_int <= 32 )); then TEMP_COLOR="$BLUE"
  elif (( temp_int <= 50 )); then TEMP_COLOR="$CYAN"
  elif (( temp_int <= 70 )); then TEMP_COLOR="$GREEN"
  elif (( temp_int <= 85 )); then TEMP_COLOR="$YELLOW"
  else                           TEMP_COLOR="$RED"
  fi
fi

# --- FEELS LIKE ---
feels_like=""
if awk -v T="$temperature" -v V="$wind_speed" 'BEGIN{exit ! (T <= 50 && V >= 3)}'; then
  feels_like=$(awk -v t="$temperature" -v v="$wind_speed" 'BEGIN {
    printf "%.1f", 35.74 + 0.6215*t - 35.75*(v^0.16) + 0.4275*t*(v^0.16)
  }')
elif awk -v T="$temperature" -v RH="$humidity" 'BEGIN{exit ! (T >= 80 && RH >= 40)}'; then
  feels_like=$(awk -v T="$temperature" -v RH="$humidity" 'BEGIN {
    printf "%.1f", -42.379 + 2.04901523*T + 10.14333127*RH \
      - 0.22475541*T*RH - 0.00683783*T*T - 0.05481717*RH*RH \
      + 0.00122874*T*T*RH + 0.00085282*T*RH*RH - 0.00000199*T*T*RH*RH
  }')
fi

# Apply same color logic to Feels Like
if [[ -n "$feels_like" ]]; then
  feels_int=$(awk -v t="${feels_like}" 'BEGIN {if(t==""||t=="null"){print"nan";exit} gsub(",",".",t); printf "%.0f", t}')
  if [[ "$feels_int" != "nan" ]]; then
    if   (( feels_int <= 32 )); then FEELS_COLOR="$BLUE"
    elif (( feels_int <= 50 )); then FEELS_COLOR="$CYAN"
    elif (( feels_int <= 70 )); then FEELS_COLOR="$GREEN"
    elif (( feels_int <= 85 )); then FEELS_COLOR="$YELLOW"
    else                           FEELS_COLOR="$RED"
    fi
  else
    FEELS_COLOR="$WHITE"
  fi
fi

# --- DISPLAY ---
echo -e "\n${BOLD}${WHITE}Weather in ${CYAN}${city_name}, ${STATE}:${RESET}"
echo -e "${BOLD}${TEMP_COLOR}Temperature: ${temperature}°F${RESET}"
if [[ -n "$feels_like" ]]; then
  echo -e "${BOLD}${FEELS_COLOR}Feels Like: ${feels_like}°F${RESET}"
fi
echo -e "${GREEN}Description:${RESET} ${weather_description}"
echo -e "${MAGENTA}Humidity:${RESET} ${humidity}%"
echo -e "${YELLOW}Wind:${RESET} ${wind_speed} mph from ${wind_dir}"
echo -e "${YELLOW}Wind Gust:${RESET} ${wind_gust} mph"
echo -e "${CYAN}Visibility:${RESET} ${visibility_miles} miles"
echo -e "${WHITE}Cloud Cover:${RESET} ${cloud_cover}%"

gt_zero() { awk "BEGIN {print ($1 > 0 ? 1 : 0)}"; }
if (( $(gt_zero "$rain_1h") )); then
  echo -e "${WHITE}Rain (1h):${RESET} ${rain_1h_in}\" (${rain_1h} mm)"
fi
if (( $(gt_zero "$rain_3h") )); then
  echo -e "${WHITE}Rain (3h):${RESET} ${rain_3h_in}\" (${rain_3h} mm)"
fi
if (( $(gt_zero "$snow_1h") )); then
  echo -e "${WHITE}Snow (1h):${RESET} ${snow_1h_in}\" (${snow_1h} mm)"
fi
if (( $(gt_zero "$snow_3h") )); then
  echo -e "${WHITE}Snow (3h):${RESET} ${snow_3h_in}\" (${snow_3h} mm)"
fi

# --- AIR QUALITY ---
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
    1) aqi_desc="Good"; aqi_color="\033[32m" ;;
    2) aqi_desc="Fair"; aqi_color="\033[36m" ;;
    3) aqi_desc="Moderate"; aqi_color="\033[33m" ;;
    4) aqi_desc="Poor"; aqi_color="\033[35m" ;;
    5) aqi_desc="Very Poor"; aqi_color="\033[31m" ;;
    *) aqi_desc="Unknown"; aqi_color="\033[0m" ;;
  esac

  echo -e "${aqi_color}${BOLD}Air Quality Index: ${aqi} (${aqi_desc})${RESET}"
  echo -e "${MAGENTA}Fine Particles (PM2.5):${RESET} ${pm2_5} µg/m³"
  echo -e "${MAGENTA}Coarse Particles (PM10):${RESET} ${pm10} µg/m³"
  echo -e "${MAGENTA}Ozone (O3):${RESET} ${o3} µg/m³"
  echo -e "${MAGENTA}Carbon Monoxide (CO):${RESET} ${co} µg/m³"
else
  echo -e "\033[1;31mAir quality data unavailable.\033[0m"
fi

