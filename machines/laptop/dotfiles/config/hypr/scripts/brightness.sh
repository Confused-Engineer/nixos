#!/usr/bin/env bash

case $1 in
    10)
        brightnessctl -q s 10%+
        exit 0
        ;;
    -10)
        CURRENT_BRIGHTNESS=$(brightnessctl get)
        MAX_BRIGHTNESS=$(brightnessctl max)
        BRIGHTNESS_PERCENTAGE=$(($CURRENT_BRIGHTNESS * 100 / $MAX_BRIGHTNESS))
        if (( $BRIGHTNESS_PERCENTAGE <= 10 )); then
            brightnessctl -q s 1%
        else
            brightnessctl -q s 10%-
        fi
        exit 0
        ;;
    *)
        
        ;;
esac


echo "Current brightness percentage: $BRIGHTNESS_PERCENTAGE%"