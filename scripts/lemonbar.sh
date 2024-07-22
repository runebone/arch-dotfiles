#!/bin/bash

BG="#1c1b19"
FG="#fce8c3"
IAFG="#918175"
# HL="#2c78bf" # Blue
# HL="#e02c6d" # Magenta
# HL="#fbb829" # Yellow
HL=$FG
FONT="-misc-mononoki nerd font-medium-r-normal--24-0-0-0-m-0-ascii-0"

get_datetime() {
    DATETIME=$(date "+%Y-%m-%d %A %H:%M:%S")
    echo "DT$DATETIME"
}

get_battery() {
    BATTERY=$(cat /sys/class/power_supply/BAT0/capacity)
    STATUS=$(cat /sys/class/power_supply/BAT0/status | sed 's/.*/\L&/')

    if [ "$STATUS" = "charging" ]; then
        STATUS="($STATUS) "
    else
        STATUS=""
    fi

    echo "B$STATUS$BATTERY"
}

get_volume() {
    if [ $(pamixer --get-mute) == "false" ]; then
        VOLUME=$(pamixer --get-volume)
    else
        VOLUME="muted"
    fi
    echo "V$VOLUME"
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
            # output="${output}%{A:bspc desktop -f $ws:}%{B$HL}%{F$BG}$x%{B$BG}%{F$FG}%{A}"
            # output="${output}%{A:reboot:}%{B$HL}%{F$BG}$x%{B$BG}%{F$FG}%{A}"
        else
            cmd=$(echo "$active" | grep "$ws")
            if [[ $? != 0 ]]; then
                output="${output}%{F$IAFG}$x%{F$FG}"
            else
                output="${output}$x"
            fi
        fi
    done
    echo -n "WS$output"
}

# LEMONBAR_FIFO="$HOME/.fifo/lemonbar.fifo"
LEMONBAR_FIFO="$(mktemp -u)$(tty | tr "/" "-")-lemonbar.fifo"
[ -e LEMONBAR_FIFO ] && rm "$LEMONBAR_FIFO"
mkfifo "$LEMONBAR_FIFO"
trap "rm -f $LEMONBAR_FIFO" EXIT

run_datetime() {
    while true; do
        get_datetime > "$LEMONBAR_FIFO"
        sleep 1
    done
}

run_battery() {
    while true; do
        get_battery > "$LEMONBAR_FIFO"
        sleep 3
    done
}

run_volume() {
    while true; do
        get_volume > "$LEMONBAR_FIFO"
        sleep 0.5 # TODO: find a better way, maybe react on sxhkd
    done
}

run_workspaces() {
    bspc subscribe report | while read -r line; do
        get_workspaces > "$LEMONBAR_FIFO"
    done
}

run_layout() {
    while true; do
        current_variant=$(setxkbmap -query | grep variant | awk '{print $2}')

        if [ "$current_variant" = "dvorak," ]; then
            echo "LDvorak" > "$LEMONBAR_FIFO"
        else
            echo "LQwerty" > "$LEMONBAR_FIFO"
        fi
        sleep 0.5 # TODO: same
    done
}

update_lemonbar() {
    read -r line < "$LEMONBAR_FIFO"

    case $line in
        DT*) DATETIME="${line#??}";;
        B*) BATTERY="${line#?}";;
        V*) VOLUME="${line#?}";;
        WS*) WS="${line#??}";;
        L*) LAYOUT="${line#?}";;
    esac

    echo -e "%{l}$WS %{c}$DATETIME %{r}Volume $VOLUME | Battery $BATTERY | $LAYOUT "
}

run_datetime &
run_battery &
run_volume &
run_workspaces &
run_layout &

while true; do
    update_lemonbar
done | lemonbar -g x32 -B "$BG" -F "$FG" -f "$FONT" -p
