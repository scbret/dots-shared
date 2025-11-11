#!/usr/bin/sh

if [ -d /etc/X11/xinit/xinitrc.d ]; then
      for f in /etc/X11/xinit/xinitrc.d/*; do
        [ -x "$f" ] && . "$f"
     done
     unset f
 fi

feh --bg-scale ~/wallpaper/mountain-stream.jpg

exec picom --config ~/.config/picom-dwm/picom.conf &

slstatus &
dunst &

xset dpms 300 &
xss-lock -- slock &

while true; do
    # Log stderror to a file
    dwm 2> ~/.dwm.log
    # No error logging
    # dwm >/dev/null 2>&1
done

