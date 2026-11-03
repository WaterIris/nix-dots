-------------------
---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

-- Autostart necessary processes (like notifications daemons, status bars, etc.)
-- Or execute your favorite apps at launch like this:

hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd --all")
    hl.exec_cmd("waybar & hyprpaper")
    hl.exec_cmd("udiskie")
    hl.exec_cmd("dunst")
    hl.exec_cmd("wlsunset -S 06:00 -s 21:00 -t 5500 -T 6500")
end)
