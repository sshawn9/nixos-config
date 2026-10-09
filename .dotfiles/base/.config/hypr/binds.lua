-- Keep everyday shortcuts aligned with the Niri configuration.
local mod = "SUPER"

hl.bind(mod .. " + Return", hl.dsp.exec_cmd("uwsm app -- ghostty"))
hl.bind(mod .. " + D", hl.dsp.exec_cmd("noctalia msg panel-toggle launcher"))
hl.bind(mod .. " + B", hl.dsp.exec_cmd("uwsm app -- google-chrome"))
hl.bind(mod .. " + E", hl.dsp.exec_cmd("uwsm app -- nautilus"))
hl.bind(mod .. " + Escape", hl.dsp.exec_cmd("noctalia msg session lock"))
hl.bind(mod .. " + SHIFT + E", hl.dsp.exec_cmd("noctalia msg panel-toggle session"))
hl.bind(mod .. " + CTRL + R", hl.dsp.exec_cmd("hyprctl reload"))

hl.bind(mod .. " + Q", hl.dsp.window.close())
hl.bind(mod .. " + F", hl.dsp.window.fullscreen({ mode = "maximized" }))
hl.bind(mod .. " + SHIFT + F", hl.dsp.window.fullscreen())
hl.bind(mod .. " + SHIFT + Space", hl.dsp.window.float())
hl.bind(mod .. " + R", hl.dsp.layout("togglesplit"))
hl.bind(mod .. " + Tab", hl.dsp.window.cycle_next())
hl.bind(mod .. " + SHIFT + Tab", hl.dsp.window.cycle_next({ next = false }))

local directions = {
	H = "l",
	J = "d",
	K = "u",
	L = "r",
	Left = "l",
	Down = "d",
	Up = "u",
	Right = "r",
}
for key, direction in pairs(directions) do
	hl.bind(mod .. " + " .. key, hl.dsp.focus({ direction = direction }))
	hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ direction = direction }))
	hl.bind(mod .. " + CTRL + " .. key, hl.dsp.focus({ monitor = direction }))
	hl.bind(mod .. " + CTRL + SHIFT + " .. key, hl.dsp.window.move({ monitor = direction }))
end

for workspace = 1, 10 do
	local key = workspace % 10
	hl.bind(mod .. " + " .. key, hl.dsp.focus({ workspace = workspace }))
	hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = workspace, follow = false }))
end
hl.bind(mod .. " + Comma", hl.dsp.focus({ workspace = "previous" }))
hl.bind(mod .. " + Page_Up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mod .. " + Page_Down", hl.dsp.focus({ workspace = "e+1" }))

hl.bind(mod .. " + Minus", hl.dsp.window.resize({ x = -80, y = 0, relative = true }), { repeating = true })
hl.bind(mod .. " + Equal", hl.dsp.window.resize({ x = 80, y = 0, relative = true }), { repeating = true })
hl.bind(mod .. " + SHIFT + Minus", hl.dsp.window.resize({ x = 0, y = -80, relative = true }), { repeating = true })
hl.bind(mod .. " + SHIFT + Equal", hl.dsp.window.resize({ x = 0, y = 80, relative = true }), { repeating = true })
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind("Print", hl.dsp.exec_cmd("uwsm app -- flameshot gui --clipboard --accept-on-select"))
hl.bind("CTRL + Print", hl.dsp.exec_cmd("uwsm app -- flameshot full --clipboard"))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd("uwsm app -- flameshot gui"))
hl.bind(mod .. " + Print", hl.dsp.exec_cmd("uwsm app -- gsr-ui launch-show"))

local hardware = { locked = true, repeating = true }
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), hardware)
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), hardware)
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set 5%+"), hardware)
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"), hardware)
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
hl.bind("XF86AudioStop", hl.dsp.exec_cmd("playerctl stop"), { locked = true })
