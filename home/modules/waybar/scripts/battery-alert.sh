# Configuration
THRESHOLD=15
NOTIF_ID=9991 


CURRENT_BAT_LVL=$(acpi -b | awk -F'[, %]+' '/until charged|remaining/ {print $4}')
IS_DISCHARGING=$(acpi -b | grep -E -o "$CURRENT_BAT_LVL%,.*remaining")
if [ "$CURRENT_BAT_LVL" -le "$THRESHOLD" ] && [ -n "$IS_DISCHARGING" ]; then
    dunstify -u critical -r $NOTIF_ID -i "$HOME/.config/waybar/scripts/icons/battery-quarter.svg" \
             "Battery Low ${CURRENT_BAT_LVL}%"
fi
