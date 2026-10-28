local wezterm = require 'wezterm'
local config = wezterm.config_builder()
config.font = wezterm.font_with_fallback { 'JetBrainsMono Nerd Font', 'Cascadia Mono', 'Consolas' }
config.font_size = 11
config.window_padding = { left = 14, right = 14, top = 14, bottom = 14 }
config.window_decorations = 'RESIZE'
config.hide_tab_bar_if_only_one_tab = true
config.default_prog = { 'powershell.exe', '-NoLogo' }
-- After setting up WSL, use: config.default_domain = 'WSL:Ubuntu'
config.colors = {
  foreground = '{{foreground}}', background = '{{background}}',
  cursor_bg = '{{accent}}', cursor_fg = '{{background}}',
  selection_bg = '{{selection}}', selection_fg = '{{selection_foreground}}',
  ansi = { '{{darker_background}}', '{{red}}', '{{green}}', '{{yellow}}', '{{blue}}', '{{magenta}}', '{{cyan}}', '{{foreground}}' },
  brights = { '{{muted}}', '{{bright_red}}', '{{bright_green}}', '{{bright_yellow}}', '{{bright_blue}}', '{{bright_magenta}}', '{{bright_cyan}}', '{{bright_foreground}}' },
}
return config
