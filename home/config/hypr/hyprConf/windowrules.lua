-- ~/.config/hypr/workspace-monitor-assign.lua
--
-- Keeps workspaces 1 and 2 bound to HDMI-A-1 whenever it's connected,
-- falling back to eDP-1 otherwise. Workspace 3 onward are explicitly
-- pinned to the fallback monitor (eDP-1) — left unset, Hyprland's own
-- auto-assignment will grab the next free workspace number for whichever
-- monitor doesn't have one of the pinned workspaces, which is exactly
-- what was landing workspace 3 on HDMI-A-1.
--
-- Fully native — no external scripts, jq, or socat needed. Re-evaluates
-- automatically whenever a monitor is plugged or unplugged via Hyprland's
-- own Lua event hooks.

local PINNED_WORKSPACES = { "1", "2" }
local PREFERRED = "HDMI-A-1"
local FALLBACK = "eDP-1"

-- "The rest" — adjust the range if you use more than 10 workspaces.
local REST_WORKSPACES = { "3", "4", "5", "6", "7", "8", "9", "10" }

local function pick_target()
    for _, m in ipairs(hl.get_monitors()) do
        if m.name == PREFERRED then
            return PREFERRED
        end
    end
    return FALLBACK
end

local function assign()
    local target = pick_target()

    -- Workspaces 1-2: bound to whichever monitor is currently preferred.
    hl.workspace_rule({ workspace = PINNED_WORKSPACES[1], monitor = target, default = true })
    hl.workspace_rule({ workspace = PINNED_WORKSPACES[2], monitor = target })

    for _, ws in ipairs(PINNED_WORKSPACES) do
        hl.dispatch(hl.dsp.workspace.move({ workspace = tonumber(ws), monitor = target }))
    end

    -- Everything else: always pinned to the fallback monitor, so it never
    -- ends up on HDMI-A-1 just because HDMI-A-1 needed *some* default
    -- workspace of its own.
    for _, ws in ipairs(REST_WORKSPACES) do
        hl.workspace_rule({ workspace = ws, monitor = FALLBACK })
    end
end

-- Run once at config load...
assign()

-- ...and again every time a monitor is connected or disconnected.
hl.on("monitor.added", assign)
hl.on("monitor.removed", assign)
