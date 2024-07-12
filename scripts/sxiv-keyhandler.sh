#!/bin/bash

echo "$1" "$2" "$3"

case "$1" in
    "r")
        convert "$3" -rotate 90 "$3"
        echo "Rotated $3 90 degrees clockwise"
        ;;
    "R")
        convert "$3" -rotate -90 "$3"
        echo "Rotated $3 90 degrees counterclockwise"
        ;;
esac
