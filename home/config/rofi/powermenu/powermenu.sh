#!/usr/bin/env bash

# Rofi Power Menu for Hyprland with Nerd Font icons

# Icons (Nerd Font)
shutdown=""
reboot=""
lock=""
suspend=""
hibernate=""
logout=""

rofi_command="rofi -dmenu -i -p Power -theme-str 'window {width: 400px;}'"

options="$lock  Lock\n$suspend  Suspend\n$hibernate  Hibernate\n$logout  Logout\n$reboot  Reboot\n$shutdown  Shutdown"

chosen=$(echo -e "$options" | eval "$rofi_command")

case "$chosen" in
    "$lock  Lock")
        hyprlock
        ;;
    "$suspend  Suspend")
        systemctl suspend
        ;;
    "$hibernate  Hibernate")
        systemctl hibernate
        ;;
    "$logout  Logout")
        hyprctl dispatch exit
        ;;
    "$reboot  Reboot")
        systemctl reboot
        ;;
    "$shutdown  Shutdown")
        systemctl poweroff
        ;;
    *)
        exit 1
        ;;
esac
