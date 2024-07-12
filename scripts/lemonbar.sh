#!/bin/bash

# Colors and font
BG="#1c1b19"
FG="#fce8c3"
IAFG="#918175"
HL="#2c78bf"
FONT="-misc-mononoki nerd font-medium-r-normal--24-0-0-0-m-0-ascii-0"

get_datetime() {
    # date "+%Y-%m-%d %H:%M:%S"
    date "+%Y-%m-%d %A %H:%M:%S"
}

get_battery() {
    BATTERY=$(cat /sys/class/power_supply/BAT0/capacity)
    echo "$BATTERY"
}

get_volume() {
    if [ $(pamixer --get-mute) == "false" ]; then
        VOLUME=$(pamixer --get-volume)
    else
        VOLUME="muted"
    fi
    echo "$VOLUME"
}

get_wifi() {
    WIFI=$(nmcli device show | grep GENERAL.CONNECTION | grep -v "\--" | grep -v lo | awk '{printf $2}')
    echo "$WIFI"
}

get_ip4() {
    IP4=$(nmcli device show | grep IP4.ADDRESS | grep -v 127.0.0.1 | awk '{printf $2}')
    echo "$IP4"
}

get_workspaces() {
    workspaces=$(bspc query -D --names)
    current=$(bspc query -D -d focused --names)
    active=$(bspc wm -g | tr ":" " " | grep -o "o." | tr -d "o" | tr "\n" " ")

    output=""
    for ws in $workspaces; do
        x=" $ws "
        if [ "$ws" == "$current" ]; then
            output="${output}%{B$HL}%{F$BG}$x%{B$BG}%{F$FG}"
        else
            cmd=$(echo "$active" | grep "$ws")
            if [[ $? != 0 ]]; then
                output="${output}%{F$IAFG}$x%{F$FG}"
            else
                output="${output}$x"
            fi
        fi
    done
    echo -n "$output"
}

update_lemonbar() {
    DATETIME=$(get_datetime)
    BATTERY=$(get_battery)
    VOLUME=$(get_volume)
    WIFI=$(get_wifi)
    WS=$(get_workspaces)

    # Create the status line
    echo -e "%{l}$WS %{c}$DATETIME %{r}Volume $VOLUME | Battery $BATTERY "
}

# Infinite loop to update bar
while true; do
    update_lemonbar
    sleep 1
done | lemonbar -g x32 -B "$BG" -F "$FG" -f "$FONT" -p
