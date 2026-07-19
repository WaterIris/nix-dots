-- Keeps workspaces 1 and 2 bound to HDMI-A-1 whenever it's connected,
-- falling back to eDP-1 otherwise. Workspaces 3+ are left untouched.
--
-- Fully native — no external scripts, jq, or socat needed. Re-evaluates
-- automatically whenever a monitor is plugged or unplugged via Hyprland's
-- own Lua event hooks.

local WORKSPACES = { "1", "2" }
local PREFERRED = "HDMI-A-1"
local FALLBACK = "eDP-1"

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

    -- Binds where these workspaces get (re)created.
    hl.workspace_rule({ workspace = WORKSPACES[1], monitor = target, default = true })
    hl.workspace_rule({ workspace = WORKSPACES[2], monitor = target })

    -- Also relocate them live if they're already open on a different
    -- monitor, so plugging in HDMI-A-1 mid-session moves them immediately
    -- rather than only affecting future workspace creation.
    for _, ws in ipairs(WORKSPACES) do
        hl.dispatch(hl.dsp.workspace.move({ workspace = tonumber(ws), monitor = target }))
    end
end

-- Run once at config load...
assign()

-- ...and again every time a monitor is connected or disconnected.
hl.on("monitor.added", assign)
hl.on("monitor.removed", assign)
