HDMI="HDMI-A-1"
LAPTOP="eDP-1"

if hyprctl monitors | grep -q "$HDMI"; then
  # HDMI connected → move 1–3 to HDMI
  for ws in 1 2 3; do
    hyprctl dispatch moveworkspacetomonitor "$ws" "$HDMI"
  done
else
  # HDMI disconnected → move 1–3 back to laptop
  for ws in 1 2 3; do
    hyprctl dispatch moveworkspacetomonitor "$ws" "$LAPTOP"
  done
fi

