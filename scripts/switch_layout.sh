#!/bin/bash

current_variant=$(setxkbmap -query | grep variant | awk '{print $2}')

if [ "$current_variant" = "dvorak," ]; then
    setxkbmap -layout us,ru
else
    setxkbmap -layout us,ru -variant dvorak,
    xmodmap $HOME/.dotfiles/config/x11/xmodmaps/rpd.xmodmap
fi
