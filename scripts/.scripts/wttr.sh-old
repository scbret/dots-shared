#!/bin/bash

# This function checks if wttr.in is available before the weather info is fetched
ck_curl() {
  curl -sf wttr.in >/dev/null
}

ck_curl
if [ $? -eq 0 ]; then # $? means "output of the last command"
  curl -s "wttr.in/mason+city?u&format=%m+%C,+H:%h,+A:%t,+F:%f,+W:%w\n" >/tmp/wttr
  wttr_net=1
else                                     # Non-zero output would appear both when the site \
  for ((cntr = 0; cntr < 3; cntr++)); do #   is down and when you're physically offline
    echo "Probing weather.  " >/tmp/wttr
    sleep 0.5
    echo "Probing weather.. " >/tmp/wttr
    sleep 0.5
    echo "Probing weather..." >/tmp/wttr
    sleep 0.5 # A wee bit of animation
  done
  ck_curl # Online check is rerun only once, if the first check fails.
fi        #   In case you're using wifi, and the cron job runs before \
#   it authenticates
if ! [ $wttr_net ]; then
  echo "Weather Offline" >/tmp/wttr
fi

