#!/bin/bash

if (grep -rq "rpd" $HOME/.config/hypr/xkb.lua); then
    ln -sf $HOME/.dotfiles/config/hypr/xkb-qwerty.lua $HOME/.config/hypr/xkb.lua
else
    ln -sf $HOME/.dotfiles/config/hypr/xkb-rpd.lua $HOME/.config/hypr/xkb.lua
fi
