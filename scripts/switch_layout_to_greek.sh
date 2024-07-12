#!/bin/sh

current_layout=$(setxkbmap -query | grep layout | awk '{print $2}')

if [ "$current_layout" = "us,ru" ]; then
    setxkbmap -layout gr,us
else
    setxkbmap -layout us,ru
fi
