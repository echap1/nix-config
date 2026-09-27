-- Hyprland config (distilled from old CachyOS setup)
-- Lives at home/linux/hyprland.lua in the Nix config; home/linux/default.nix inlines it
-- into Hyprland's config, so rebuild after editing.

------------------------
---- DEFAULT APPS ----
------------------------
local TERMINAL     = "alacritty"
local FILE_MANAGER = "nautilus"
local BROWSER      = "brave"

local mainMod  = "SUPER"
local noctCall = "noctalia msg "

local left, right, up, down = "h", "l", "k", "j"

----------------
---- COLORS ----
----------------
-- Fallbacks; Noctalia's generated theme overrides the borders at the bottom of this file.
local LGREEN = "rgba(82dcccff)"
local DGREEN = "rgba(007d6fff)"
local LBLUE  = "rgba(01ccffff)"
local DBLUE  = "rgba(111826ff)"
local GRAY   = "rgba(798bb2ff)"

------------------
---- MONITORS ----
------------------
local INTERNAL = "eDP-1"
local LEFT     = "DP-2"
local RIGHT    = "DP-4"

local function read_lid_state()
    for _, dev in ipairs({ "LID0", "LID", "LID1", "PNP0C0D:00" }) do
        local f = io.open("/proc/acpi/button/lid/" .. dev .. "/state", "r")
        if f then
            local s = f:read("*l") or ""
            f:close()
            return s:match("closed") ~= nil
        end
    end
    local p = io.popen("cat /proc/acpi/button/lid/*/state 2>/dev/null")
    if p then
        local s = p:read("*a") or ""
        p:close()
        if s ~= "" then return s:match("closed") ~= nil end
    end
    return false
end

local lid_closed = read_lid_state()

local function externals_present()
    for _, m in ipairs(hl.get_monitors()) do
        if m.name ~= INTERNAL then return true end
    end
    return false
end

local function apply_layout()
    local internal_off = lid_closed and externals_present()

    hl.monitor({ output = INTERNAL, mode = "preferred", position = "0x0", scale = 1, disabled = internal_off })

    if internal_off then
        hl.monitor({ output = LEFT,  mode = "2560x1440@180", position = "0x0",    scale = 1 })
        hl.monitor({ output = RIGHT, mode = "2560x1440@180", position = "2560x0", scale = 1 })
    else
        -- auto-right places each screen to the right of the previous one,
        -- so this still lines up whatever the laptop panel's resolution is
        hl.monitor({ output = LEFT,  mode = "2560x1440@180", position = "auto-right", scale = 1 })
        hl.monitor({ output = RIGHT, mode = "2560x1440@180", position = "auto-right", scale = 1 })
    end

    hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })
end

apply_layout()
hl.on("monitor.added",   apply_layout)
hl.on("monitor.removed", apply_layout)
hl.on("hyprland.start",  apply_layout)

hl.bind("switch:on:Lid Switch",  function() lid_closed = true;  apply_layout() end, { locked = true })
hl.bind("switch:off:Lid Switch", function() lid_closed = false; apply_layout() end, { locked = true })

-------------------
---- AUTOSTART ----
-------------------
-- Noctalia and the dbus/systemd environment are started by home.nix, not here.
hl.on("hyprland.start", function()
    hl.exec_cmd("xhost +SI:localuser:root")
end)

-----------------------
---- LOOK AND FEEL ----
-----------------------
hl.config({
    general = {
        gaps_in                 = 3,
        gaps_out                = 8,
        border_size             = 2,
        extend_border_grab_area = 10,
        resize_on_border        = true,
        col = {
            active_border   = { colors = { LGREEN, DGREEN }, angle = 45 },
            inactive_border = GRAY,
        },
    },
    group = {
        col = {
            border_active          = LBLUE,
            border_inactive        = GRAY,
            border_locked_active   = DBLUE,
            border_locked_inactive = GRAY,
        },
        groupbar = {
            col = {
                active          = LGREEN,
                inactive        = GRAY,
                locked_active   = DBLUE,
                locked_inactive = GRAY,
            },
        },
    },
    decoration = {
        dim_special        = 0.3,
        rounding           = 10,
        active_opacity     = 1,
        inactive_opacity   = 1,
        fullscreen_opacity = 1,
        blur = {
            size    = 5,
            passes  = 4,
            special = true,
        },
    },
    dwindle = {
        preserve_split = true,
    },
    misc = {
        col = { splash = LGREEN },
        middle_click_paste = false,
        enable_swallow     = true,
        swallow_regex      = "(kitty|ghostty|[Kk]onsole|Alacritty|gnome-terminal|xfce[0-9]?-terminal)",
        vrr                = 3,
    },
    xwayland = {
        force_zero_scaling = true,
    },
    ecosystem = {
        no_update_news  = true,
        no_donation_nag = true,
    },
})

--------------------
---- ANIMATIONS ----
--------------------
hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1}   } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}   } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}      } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1}   } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}    } })
hl.curve("overshoot",      { type = "bezier", points = { {0.5, 0.9},   {0.1, 1.1}  } })

hl.curve("easy",   { type = "spring", mass = 1, stiffness = 71.2633, dampening = 15.8273644 })
hl.curve("rubber", { type = "spring", mass = 1, stiffness = 70,      dampening = 10 })

hl.animation({ leaf = "global",              enabled = true,  speed = 3, bezier = "quick" })
-- Windows open, close and move instantly (like AeroSpace). Set enabled = true for the old slide.
hl.animation({ leaf = "windows",             enabled = false, speed = 3, spring = "easy",  style = "slide" })
hl.animation({ leaf = "workspaces",          enabled = false, speed = 5, bezier = "quick", style = "slide 20%" })
hl.animation({ leaf = "specialWorkspaceIn",  enabled = true,  speed = 2, bezier = "quick", style = "slide top" })
hl.animation({ leaf = "specialWorkspaceOut", enabled = true,  speed = 2, bezier = "quick", style = "slide bottom" })
hl.animation({ leaf = "monitorAdded",        enabled = false })

---------------
---- INPUT ----
---------------
hl.config({
    input = {
        kb_layout     = "us",
        accel_profile = "flat",
        sensitivity   = 0.0,
        touchpad = {
            scroll_factor = 0.6,
        },
    },
})

hl.device({
    name          = "pixa3854:00-093a:0274-touchpad",
    accel_profile = "custom 0.5 0.000 0.425 0.920 1.515 2.240 3.125 4.200 5.495 7.040 8.865 11.000 13.475 16.320 19.565 23.240 27.375 32.000 37.145 42.840 49.115",
})

hl.gesture({ fingers = 4, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 3, direction = "down",       action = "close" })
hl.gesture({ fingers = 3, direction = "up",         action = "fullscreen" })
hl.gesture({ fingers = 3, direction = "left",       action = "float" })

---------------------------
---- WINDOW MANAGEMENT ----
---------------------------
hl.bind(mainMod .. " + Escape",      hl.dsp.exec_cmd("hyprctl kill"))
hl.bind(mainMod .. " + Q",           hl.dsp.window.close())
hl.bind(mainMod .. " + ALT + Space", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + D",           hl.dsp.window.fullscreen({ mode = 1 }))
hl.bind(mainMod .. " + F",           hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + Slash",       hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + SHIFT + Q",   hl.dsp.exec_cmd(noctCall .. "session lock"))
hl.bind(mainMod .. " + ALT + C",     hl.dsp.exec_cmd(noctCall .. "panel-open session"))

-- Focus
hl.bind(mainMod .. " + " .. left,  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + " .. right, hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + " .. up,    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + " .. down,  hl.dsp.focus({ direction = "down" }))
hl.bind("ALT + Tab",               hl.dsp.window.cycle_next())
-- Move the current workspace to the next monitor (wraps around), like AeroSpace alt-shift-tab
hl.bind(mainMod .. " + SHIFT + Tab", hl.dsp.workspace.move({ monitor = "+1" }))

-- Move windows within the workspace
hl.bind(mainMod .. " + SHIFT + " .. right, hl.dsp.window.move({ direction = "r" }))
hl.bind(mainMod .. " + SHIFT + " .. left,  hl.dsp.window.move({ direction = "l" }))
hl.bind(mainMod .. " + SHIFT + " .. up,    hl.dsp.window.move({ direction = "u" }))
hl.bind(mainMod .. " + SHIFT + " .. down,  hl.dsp.window.move({ direction = "d" }))

-- Resize with keyboard (like AeroSpace's cmd-minus / cmd-equal)
hl.bind(mainMod .. " + equal", hl.dsp.window.resize({ x = 50,  y = 50,  relative = true }), { repeating = true })
hl.bind(mainMod .. " + minus", hl.dsp.window.resize({ x = -50, y = -50, relative = true }), { repeating = true })

-- Mouse move / resize
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

------------------
---- LAUNCHER ----
------------------
hl.bind(mainMod .. " + Return",     hl.dsp.exec_cmd(TERMINAL))
hl.bind(mainMod .. " + E",          hl.dsp.exec_cmd(FILE_MANAGER))
hl.bind(mainMod .. " + W",          hl.dsp.exec_cmd(BROWSER))
hl.bind("CONTROL + SHIFT + Escape", hl.dsp.exec_cmd(TERMINAL .. " -e btop"))
hl.bind(mainMod .. " + Z",          hl.dsp.exec_cmd(noctCall .. "settings-toggle"))
hl.bind(mainMod .. " + X",          hl.dsp.exec_cmd(noctCall .. "panel-open control-center"))
hl.bind(mainMod .. " + Space",      hl.dsp.exec_cmd(noctCall .. "panel-open launcher"))
hl.bind(mainMod .. " + period",     hl.dsp.exec_cmd(noctCall .. "launcher /emo"))

---------------------------
---- HARDWARE CONTROLS ----
---------------------------
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(noctCall .. "volume-up"),   { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(noctCall .. "volume-down"), { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd(noctCall .. "volume-mute"), { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd(noctCall .. "mic-mute"),    { locked = true, repeating = true })

hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd(noctCall .. "media toggle"),   { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd(noctCall .. "media toggle"),   { locked = true })
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd(noctCall .. "media next"),     { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd(noctCall .. "media previous"), { locked = true })

hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd(noctCall .. "brightness-up"),   { repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(noctCall .. "brightness-down"), { repeating = true })

-------------------
---- UTILITIES ----
-------------------
hl.bind(mainMod .. " + P",         hl.dsp.exec_cmd(noctCall .. "plugin:screen-toolkit colorPicker"))
-- Screenshots (Noctalia built-in): saved to ~/Pictures/Screenshots and copied to the clipboard
hl.bind("Print",                   hl.dsp.exec_cmd(noctCall .. "screenshot-region"))
hl.bind("SHIFT + Print",           hl.dsp.exec_cmd(noctCall .. "screenshot-fullscreen"))
hl.bind(mainMod .. " + Print",     hl.dsp.exec_cmd(noctCall .. "screenshot-fullscreen"))
hl.bind(mainMod .. " + R",         hl.dsp.exec_cmd(noctCall .. "plugin:screen-toolkit toggle"))
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd(noctCall .. "wallpaper toggle"))
hl.bind(mainMod .. " + V",         hl.dsp.exec_cmd(noctCall .. "launcher clipboard"))
hl.bind(mainMod .. " + A",         hl.dsp.exec_cmd(noctCall .. "notifications toggleHistory"))

--------------------
---- WORKSPACES ----
--------------------
for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key,             hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key,     hl.dsp.window.move({ workspace = i, follow = true }))
    hl.bind(mainMod .. " + CONTROL + " .. key,   hl.dsp.window.move({ workspace = i, follow = false }))
end

hl.bind(mainMod .. " + CONTROL + " .. right,         hl.dsp.focus({ workspace = "r+1" }))
hl.bind(mainMod .. " + CONTROL + " .. left,          hl.dsp.focus({ workspace = "r-1" }))
hl.bind(mainMod .. " + CONTROL + " .. down,          hl.dsp.focus({ workspace = "empty" }))
hl.bind(mainMod .. " + CONTROL + SHIFT + " .. right, hl.dsp.window.move({ workspace = "r+1" }))
hl.bind(mainMod .. " + CONTROL + SHIFT + " .. left,  hl.dsp.window.move({ workspace = "r-1" }))

hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special" }))
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special())

----------------------
---- WINDOW RULES ----
----------------------

-- Picture-in-Picture
hl.window_rule({
    match             = { title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" },
    float             = true,
    keep_aspect_ratio = true,
    move              = "73% 72%",
    size              = "25% 25%",
    pin               = true,
})

-- Gaming
local gamingApps      = "^(steam_app.*|gamescope)$"
local gamingWorkspace = "name:gaming"

hl.window_rule({ match = { content = "game" },  workspace = gamingWorkspace })
hl.window_rule({ match = { class = gamingApps }, workspace = gamingWorkspace })
hl.window_rule({ match = { class = "^(steam)$", title = "^(Friends List)$" }, float = true })
hl.window_rule({
    match     = { class = "^(steam)$", title = "^(Launching\\.{3})$" },
    float     = true,
    center    = true,
    workspace = gamingWorkspace,
})
hl.window_rule({
    match = {
        class         = gamingApps,
        title         = "^(.+)$",
        initial_title = "negative:^(.*\\\\home\\\\.*)$",
    },
    size             = "monitor_w monitor_h",
    fullscreen_state = 2,
    content          = "game",
})
hl.window_rule({
    match            = { class = "^(steam_app.*)$", initial_title = "^$" },
    float            = true,
    center           = true,
    fullscreen       = false,
    fullscreen_state = 0,
})

-- Apps
local primaryWorkspace = 1

hl.window_rule({ match = { class = "^(.*\\.exe)$", float = true }, workspace = primaryWorkspace, center = true, fullscreen_state = 0 })
hl.window_rule({ match = { class = "^(vesktop|discord)$" }, workspace = primaryWorkspace })
hl.window_rule({ match = { class = "^(.*[Cc]alculator.*)$" }, float = true, size = "380 616" })

-- Opacity overrides
local terminals = "^(kitty|ghostty|[Kk]onsole|Alacritty|gnome-terminal|xfce[0-9]?-terminal)$"

hl.window_rule({ match = { class = "^(firefox|zen|librewolf|brave-browser)$" }, opacity = "1.0 override" })
hl.window_rule({ match = { class = terminals }, opacity = "1.0 override" })
hl.window_rule({ match = { class = "^(mpv|org.kde.haruna|.*plex.*|org\\.kde\\.gwenview|.*vlc.*)$" }, opacity = "1.0 override" })

-- Float utility windows
local floatApps = {
    { class = "^(kvantummanager|qt[56]ct|nwg-look)$" },
    { class = "^(org.pulseaudio.pavucontrol|blueman-manager|nm-applet|nm-connection-editor)$" },
    { title = "^(Winetricks.*|Protontricks.*)$" },
}
for _, m in ipairs(floatApps) do hl.window_rule({ match = m, float = true }) end

hl.window_rule({ match = { float = true }, move = "50% 50%" })

-- Float common dialogs
local modalMatches = {
    { title = "^(Open|Authentication Required|Add Folder to Workspace|Choose Files|Save As|Confirm to replace files|File Operation Progress)$" },
    { initial_title = "^(Open File)$" },
    { class = "^([Xx]dg-desktop-portal-gtk)$" },
    { title = "^(File Upload|Choose wallpaper|Library)(.*)$" },
    { class = "^(.*dialog.*)$" },
    { title = "^(.*dialog.*)$" },
    { class = "^(hyprland-share-picker)$" },
}
for _, m in ipairs(modalMatches) do hl.window_rule({ match = m, float = true }) end

-- Ignore maximize requests from all apps
hl.window_rule({
    name           = "suppress-maximize-events",
    match          = { class = ".*" },
    suppress_event = "maximize",
})

-- Fix XWayland dragging issues
hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})

-- Betterbird popups
hl.window_rule({
    match = {
        class         = [[eu\.betterbird\.Betterbird]],
        initial_title = [[^(Write:|Reply:|Forward:|TbSync|Edit).*]],
    },
    float  = true,
    center = true,
    size   = "800 800",
})

local bb_w, bb_h    = 800, 800
local bb_iterations = 10
local bb_start      = 150
local bb_step       = 10

hl.window_rule({
    match  = { class = [[eu\.betterbird\.Betterbird]], initial_title = "" },
    float  = true,
    center = true,
    size   = (bb_w - bb_iterations) .. " " .. (bb_h - bb_iterations),
})

hl.on("window.open", function(w)
    if w == nil or w.class ~= "eu.betterbird.Betterbird" then return end
    if w.initial_title ~= "" then return end
    local addr = w.address
    for n = bb_iterations - 1, 0, -1 do
        local step = bb_iterations - 1 - n
        hl.timer(function()
            hl.dispatch(hl.dsp.window.resize({ x = bb_w - n, y = bb_h - n, window = "address:" .. addr }))
            hl.dispatch(hl.dsp.window.center({ window = "address:" .. addr }))
        end, { timeout = bb_start + bb_step * step, type = "oneshot" })
    end
end)

-----------------------
---- NOCTALIA THEME ----
-----------------------
-- Noctalia writes ~/.config/hypr/noctalia.lua when its "hyprland" template is enabled.
-- pcall keeps the config loading if that file doesn't exist yet.
local ok, noctalia = pcall(require, "noctalia")
if ok and noctalia and noctalia.apply_theme then
    noctalia.apply_theme()
end
