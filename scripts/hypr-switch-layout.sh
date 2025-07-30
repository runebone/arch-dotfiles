#!/bin/bash

if (grep -rq "rpd" $HOME/.config/hypr/xkb.conf); then
    ln -sf $HOME/.dotfiles/config/hypr/xkb-qwerty.conf $HOME/.config/hypr/xkb.conf
else
    ln -sf $HOME/.dotfiles/config/hypr/xkb-rpd.conf $HOME/.config/hypr/xkb.conf
fi
