#!/usr/bin/env bash

# Options
options=" Shutdown
 Reboot
 Suspend
󰒲 Hibernate
 Lock
󰗽 Logout
Cancel"

chosen="$(echo -e "$options" | rofi -dmenu -no-show-icons -p "Power" -i)"

case "$chosen" in
    " Shutdown")
        systemctl poweroff
        ;;
    " Reboot")
        systemctl reboot
        ;;
    " Suspend")
        systemctl suspend
        ;;
    "󰒲 Hibernate")
        systemctl hibernate
        ;;
    " Lock")
        hyprlock
        ;;
    "󰗽 Logout")
        pkill -KILL -u "$USER"
        ;;
    "Cancel" | *)
        exit 0
        ;;
esac

