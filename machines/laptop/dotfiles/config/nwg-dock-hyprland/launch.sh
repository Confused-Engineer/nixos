#!/usr/bin/env bash
#    ___           __
#   / _ \___  ____/ /__
#  / // / _ \/ __/  '_/
# /____/\___/\__/_/\_\
#


    pkill -f nwg-dock-hyprland
    sleep 0.5
    nwg-dock-hyprland -i 48 -w 5 -mb 10 -x -s style.css -c "rofi -show drun"
