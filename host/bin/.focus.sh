#!/bin/bash
# utility script - controls the window manager and ensures kweb is always frontmost for the touchscreen display.
# only needs to be ran on 4ktouch, standalone and LCHR configs.
# !!! Not needed on 4kscreen !!!

while true; do
  if  ps -A | grep kweb
    then
      if [ $(env DISPLAY=:0 xprop -root _NET_ACTIVE_WINDOW | cut -d " " -f5) != $(env DISPLAY=:0 XAUTHORITY=/home/pi/.Xauthority wmctrl -l | grep kweb | cut -d " " -f1) ]
        then
          env DISPLAY=:0 XAUTHORITY=/home/pi/.Xauthority wmctrl -a "kweb"
      fi
  fi
  sleep 1s
done
