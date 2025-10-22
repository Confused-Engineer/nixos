#!/usr/bin/env bash
#    ___                    
#   / _ \___ _    _____ ____
#  / ___/ _ \ |/|/ / -_) __/
# /_/   \___/__,__/\__/_/   
#                           

pkill -f nwg-dock-hyprland || nwg-dock-hyprland -i 40 -w 5 -mb 10 -x -s style.css -c "rofi -show drun" &