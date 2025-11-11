#!/bin/sh
# ~/bin/open-last-screenshot

LAST_SCREENSHOT="$(ls -t ~/Pictures/Screenshots 2>/dev/null | head -n 1)"
if [ -n "$LAST_SCREENSHOT" ]; then
    xdg-open "$HOME/Pictures/Screenshots/$LAST_SCREENSHOT"
fi
