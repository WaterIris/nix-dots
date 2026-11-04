---------------------
---- MY PROGRAMS ----
---------------------

-- Set programs that you use
local terminal      = "alacritty"
local fileManager   = "nemo"
local menu          = "rofi -show drun"
local browser       = "firefox"
local powermenu     = "qs -p ~/.config/quickshell/powermenu.qml"
local audiomenu     = "qs -p ~/.config/quickshell/audiocontrol.qml"
local bluetoothmenu = "qs -p ~/.config/quickshell/bluetoothcontrol.qml"
local keybindsmenu  = "qs -p ~/.config/quickshell/keybinds.qml"
local wifimenu      = "qs -p ~/.config/quickshell/wificontrol.qml"

---------------------
---- KEYBINDINGS ----
---------------------

local mainMod       = "SUPER" -- Sets "Windows" key as main modifier

-- Descriptions use the "Group: Action" format; keybinds.qml groups the
-- cheatsheet by the part before the colon. Binds without a description
-- are left out of the cheatsheet.

-- Private binds
hl.bind(mainMod .. " + Escape", hl.dsp.exec_cmd(powermenu), { description = "Menus: Power menu" })
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd(audiomenu), { description = "Menus: Audio control" })
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(bluetoothmenu))
hl.bind(mainMod .. " + slash", hl.dsp.exec_cmd(keybindsmenu), { description = "Menus: Show keybindings" })
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd(wifimenu), { description = "Menus: Wi-Fi control" })
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ action = "toggle" }),
    { description = "Windows: Toggle fullscreen" })

-- Swap the focused window with its neighbor (vim-style: l = horizontal/right, k = vertical/up)
hl.bind(mainMod .. " + CTRL + L", hl.dsp.window.swap({ direction = "right" }),
    { description = "Windows: Swap with right" })
hl.bind(mainMod .. " + CTRL + H", hl.dsp.window.swap({ direction = "left" }),
    { description = "Windows: Swap with left" })
hl.bind(mainMod .. " + CTRL + K", hl.dsp.window.swap({ direction = "up" }), { description = "Windows: Swap with above" })
hl.bind(mainMod .. " + CTRL + J", hl.dsp.window.swap({ direction = "down" }),
    { description = "Windows: Swap with below" })

-- Rotate the current split from side-by-side to stacked (top/bottom) and back
hl.bind(mainMod .. " + CTRL + R", hl.dsp.layout("togglesplit"), { description = "Windows: Toggle split direction" })

-- Example binds, see https://wiki.hypr.land/Configuring/Basics/Binds/ for more
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal), { description = "Apps: Terminal" })
local closeWindowBind = hl.bind(mainMod .. " + C", hl.dsp.window.close(), { description = "Windows: Close" })
-- closeWindowBind:set_enabled(false)
hl.bind(mainMod .. " + M",
    hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"),
    { description = "Session: Exit Hyprland" })
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager), { description = "Apps: File manager" })
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }), { description = "Windows: Toggle floating" })
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd(menu), { description = "Apps: App launcher" })
hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(browser), { description = "Apps: Browser" })
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo(), { description = "Windows: Toggle pseudotile" })

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }), { description = "Focus: Left" })
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }), { description = "Focus: Right" })
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }), { description = "Focus: Up" })
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }), { description = "Focus: Down" })

-- Switch workspaces with mainMod + [1-5]
-- Move active window to a workspace with mainMod + SHIFT + [1-5]
for i = 1, 5 do
    hl.bind(mainMod .. " + " .. i, hl.dsp.focus({ workspace = i }),
        { description = "Workspaces: Go to workspace " .. i })
    hl.bind(mainMod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }),
        { description = "Workspaces: Move window to workspace " .. i })
end

-- Example special workspace (scratchpad)
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"), { description = "Workspaces: Toggle scratchpad" })
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }),
    { description = "Workspaces: Move window to scratchpad" })

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }), { description = "Workspaces: Next" })
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }), { description = "Workspaces: Previous" })

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true, description = "Windows: Drag to move" })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true, description = "Windows: Drag to resize" })

-- Laptop multimedia keys for volume and LCD brightness
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),
    { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
    { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
    { locked = true, repeating = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
    { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })

-- Requires playerctl
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
