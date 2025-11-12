-- Streamlined WezTerm configuration - maintains all functionality
local wezterm = require "wezterm"
local act = wezterm.action
local config = wezterm.config_builder()

-- GitHub Dark color palette
local colors = {
  fg="#d0d7de", bg="#0d1117", comment="#8b949e", red="#ff7b72",
  green="#3fb950", yellow="#d29922", blue="#539bf5", magenta="#bc8cff",
  cyan="#39c5cf", selection="#415555", caret="#58a6ff", invisibles="#2f363d"
}

-- Leader is a prefix: tap Ctrl+Space, then the next key within the timeout.
config.leader = { key = "Space", mods = "CTRL", timeout_milliseconds = 1000 }

-- === Keys ===
config.keys = {
	-- Leader + h/j/k/l (single resize hits)
	{ key = "h", mods = "LEADER", action = act.AdjustPaneSize({ "Left", 5 }) },
	{ key = "j", mods = "LEADER", action = act.AdjustPaneSize({ "Down", 5 }) },
	{ key = "k", mods = "LEADER", action = act.AdjustPaneSize({ "Up", 5 }) },
	{ key = "l", mods = "LEADER", action = act.AdjustPaneSize({ "Right", 5 }) },

	-- Enter "resize mode": Ctrl+Space, r  → then h/j/k/l repeat until Esc/Enter
	{
		key = "r",
		mods = "LEADER",
		action = act.ActivateKeyTable({
			name = "resize",
			one_shot = false,
			replace_current = false,
			until_unknown = false,
		}),
	},
}

-- Pane management
for _, v in ipairs({
  {"Enter", act.SplitHorizontal{domain='CurrentPaneDomain'}},
  {"\\", act.SplitVertical{domain='CurrentPaneDomain'}},
  {"w", act.CloseCurrentPane{confirm=true}},
  {"LeftArrow", act.ActivatePaneDirection'Left'},
  {"RightArrow", act.ActivatePaneDirection'Right'},
  {"UpArrow", act.ActivatePaneDirection'Up'},
  {"DownArrow", act.ActivatePaneDirection'Down'},
  {"t", act.SpawnTab'CurrentPaneDomain'},
  {"q", act.CloseCurrentTab{confirm=true}},
  {"c", act.CopyTo'ClipboardAndPrimarySelection'},
  {"v", act.PasteFrom'Clipboard'},
  {"=", act.IncreaseFontSize},
  {"-", act.DecreaseFontSize},
  {"0", act.ResetFontSize}
}) do table.insert(config.keys, {mods="ALT", key=v[1], action=v[2]}) end

-- ALT+SHIFT combinations
for _, v in ipairs({
  {"j", act.DecreaseFontSize},
  {"k", act.IncreaseFontSize}
}) do table.insert(config.keys, {mods="ALT|SHIFT", key=v[1], action=v[2]}) end

-- table.insert(config.keys, {mods="ALT|SHIFT", key="Enter", action=act.SplitVertical{domain='CurrentPaneDomain'}})
-- table.insert(config.keys, {mods="ALT|SHIFT", key="j", action=act.DecreaseFontSize})
-- table.insert(config.keys, {mods="ALT|SHIFT", key="k", action=act.IncreaseFontSize})


-- Tab navigation (ALT+1-8)
for i = 0, 7 do table.insert(config.keys, {mods="ALT", key=tostring(i+1), action=act.ActivateTab(i)}) end

-- Tab movement and last tab (CTRL+ALT)
for _, v in ipairs({
  {"UpArrow", act.ActivateLastTab}, {"DownArrow", act.ActivateLastTab},
  {"LeftArrow", act.MoveTabRelative(-1)}, {"RightArrow", act.MoveTabRelative(1)}
}) do table.insert(config.keys, {mods="CTRL|ALT", key=v[1], action=v[2]}) end
for i = 0, 7 do table.insert(config.keys, {mods="CTRL|ALT", key=tostring(i+1), action=act.MoveTab(i)}) end

-- === Key Tables ===
config.key_tables = {
	resize = {
		{ key = "h", action = act.AdjustPaneSize({ "Left", 5 }) },
		{ key = "j", action = act.AdjustPaneSize({ "Down", 5 }) },
		{ key = "k", action = act.AdjustPaneSize({ "Up", 5 }) },
		{ key = "l", action = act.AdjustPaneSize({ "Right", 5 }) },
		{ key = "Escape", action = "PopKeyTable" },
		{ key = "Enter", action = "PopKeyTable" },
	},
}

-- Font configuration
config.font = wezterm.font_with_fallback({
  {family='Lilex Nerd Font Mono', weight='Regular'},  
  {family='SauceCodePro Nerd Font Mono', weight='Regular'},
  {family='FiraCode Nerd Font Mono', weight='Regular'},
  {family='Symbols Nerd Font Mono', weight='Regular'}
})
config.font_size = 10
config.line_height = 1.1
config.window_frame = {
  font = wezterm.font{family='Lilex Nerd Font Mono', weight='Regular', style='Italic'},
  font_size = 10.0,
  active_titlebar_bg = colors.bg
}

-- Performance settings
config.max_fps = 120
config.animation_fps = 1
config.window_background_opacity = 0.98
config.enable_scroll_bar = false
config.use_fancy_tab_bar = true
config.term = "xterm-256color"
config.warn_about_missing_glyphs = false
config.enable_wayland = false
config.front_end = "OpenGL"
config.webgpu_power_preference = "HighPerformance"
config.prefer_egl = true
config.freetype_load_target = "Light"
config.freetype_render_target = "HorizontalLcd"
config.hide_tab_bar_if_only_one_tab = false

-- Inactive pane look
config.inactive_pane_hsb = {
  saturation = 0.8,
  brightness = 0.6,
}

-- Color scheme
config.colors = {
  foreground=colors.fg, background=colors.bg,
  cursor_bg=colors.caret, cursor_fg=colors.bg, cursor_border=colors.caret,
  selection_fg=colors.fg, selection_bg=colors.selection,
  scrollbar_thumb=colors.invisibles, split=colors.invisibles,
  ansi = {colors.invisibles, colors.red, colors.green, colors.yellow,
          colors.blue, colors.magenta, colors.cyan, colors.fg},
  brights = {colors.comment, "#ff9790", "#6af28c", "#e3b341",
             "#79c0ff", "#d2a8ff", "#56d4dd", "#ffffff"},
  tab_bar = {
    background=colors.bg, inactive_tab_edge=colors.invisibles,
    active_tab={bg_color=colors.blue, fg_color=colors.bg, intensity="Bold"},
    inactive_tab={bg_color=colors.bg, fg_color=colors.comment},
    inactive_tab_hover={bg_color="#21262d", fg_color=colors.caret},
    new_tab={bg_color=colors.bg, fg_color=colors.caret, intensity="Bold"},
    new_tab_hover={bg_color="#21262d", fg_color=colors.red}
  }
}

-- Mouse bindings
config.mouse_bindings = {
  {event={Down={streak=1, button="Right"}}, mods="NONE", action=act.CopyTo("Clipboard")},
  {event={Down={streak=1, button="Middle"}}, mods="NONE", action=act.SplitHorizontal{domain="CurrentPaneDomain"}},
  {event={Down={streak=1, button="Middle"}}, mods="SHIFT", action=act.CloseCurrentPane{confirm=false}}
}

return config
