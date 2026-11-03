--[[
Workspace-to-monitor assignment and lid switch handling.

Loaded from hyprland.lua via require("hyprConf.workspaces").

Behavior:
  - Workspaces 1 and 2 default to HDMI-A-1 and stay there whenever it's
    available, regardless of the laptop panel's state.
  - When eDP-1 (laptop panel) is disabled/disconnected (lid closed) and
    HDMI-A-1 is present, ALL remaining workspaces on eDP-1 are moved to
    HDMI-A-1.
  - When eDP-1 is re-enabled/reconnected (lid opened), workspaces 3, 4, 5
    are moved back onto eDP-1. 1, 2, and everything else stay on
    HDMI-A-1.

Requires Hyprland >= 0.55 (native hl.* Lua config API).
--]]

local LAPTOP             = "eDP-1"
local EXTERNAL           = "HDMI-A-1"
local REASSIGN_ON_OPEN   = { 3, 4, 5 }
local PINNED_TO_EXTERNAL = { 1, 2 }

local function monitor_exists(name)
    return hl.get_monitor(name) ~= nil
end

-- Move every non-special workspace currently living on `from` to `to`,
-- provided `to` actually exists.
local function move_all_workspaces(from, to)
    if not monitor_exists(to) then
        return
    end
    for _, ws in ipairs(hl.get_workspaces()) do
        if not ws.special and ws.monitor and ws.monitor.name == from then
            hl.dispatch(hl.dsp.workspace.move({ workspace = ws.id, monitor = to }))
        end
    end
end

-- Move a fixed set of workspace IDs onto `target`, provided it exists.
local function reassign_workspaces(ids, target)
    if not monitor_exists(target) then
        return
    end
    for _, id in ipairs(ids) do
        hl.dispatch(hl.dsp.workspace.move({ workspace = tostring(id), monitor = target }))
    end
end

-- Keep 1/2 pinned to the external monitor at all times.
hl.workspace_rule({ workspace = "1", monitor = EXTERNAL })
hl.workspace_rule({ workspace = "2", monitor = EXTERNAL })

-- Keep 3/4/5 defaulting to the laptop panel whenever it's present, so newly
-- created workspaces land in the right place even before any event fires.
hl.workspace_rule({ workspace = "3", monitor = LAPTOP })
hl.workspace_rule({ workspace = "4", monitor = LAPTOP })
hl.workspace_rule({ workspace = "5", monitor = LAPTOP })

-- React to the laptop panel disappearing (lid closed -> eDP-1 disabled).
hl.on("monitor.removed", function(monitor)
    if monitor.name == LAPTOP then
        move_all_workspaces(LAPTOP, EXTERNAL)
    end
end)

-- React to monitors appearing.
hl.on("monitor.added", function(monitor)
    if monitor.name == LAPTOP then
        reassign_workspaces(REASSIGN_ON_OPEN, LAPTOP)
    elseif monitor.name == EXTERNAL then
        reassign_workspaces(PINNED_TO_EXTERNAL, EXTERNAL)
        if not monitor_exists(LAPTOP) then
            -- External plugged in while lid is already closed.
            move_all_workspaces(LAPTOP, EXTERNAL)
        end
    end
end)

-- Initial sync once on startup, in case Hyprland launches with the lid
-- already closed, or HDMI-A-1 is already connected.
hl.on("hyprland.start", function()
    if monitor_exists(EXTERNAL) then
        reassign_workspaces(PINNED_TO_EXTERNAL, EXTERNAL)
    end
    if not monitor_exists(LAPTOP) then
        move_all_workspaces(LAPTOP, EXTERNAL)
    end
end)

--------------------------------------------------------------------------
-- Lid switch -> actually enable/disable the eDP-1 output.
-- Hyprland does not do this on its own; it only reacts to monitors that
-- are actually enabled/disabled/(dis)connected. `locked = true` is
-- required so the bind still fires on a locked screen.
--------------------------------------------------------------------------
hl.bind("switch:on:Lid Switch", function()
    hl.monitor({ output = LAPTOP, disabled = true })
end, { locked = true })

hl.bind("switch:off:Lid Switch", function()
    hl.monitor({ output = LAPTOP, mode = "1920x1080@144", position = "0x0", scale = "1", disabled = false })
end, { locked = true })
