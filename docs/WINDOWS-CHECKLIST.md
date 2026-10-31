# Windows acceptance checklist

Basic installation validated on Windows 11 Pro, build 26200, on 2026-10-29.
Both monitors displayed the themed bar and clock; workspace-button focus and
Alt+Shift+P pause/resume were verified. WezTerm launched with the themed config
and Cascadia Mono fallback. Unchecked items below still need manual validation.

- [x] Run installer as the intended user on Windows 11; review package failures or restart notices.
- [x] Run Doctor.ps1; verify three core executables and configuration files are found.
- [ ] Open three ordinary apps; verify automatic tiling and visible focused border.
- [x] Confirm one Fwog Pond bar per screen, clickable workspace buttons, and local clock.
- [x] Confirm the bar stays behind the active game and stops covering its menus; user verified after changing the bar to normal window priority on 2026-10-29.
- [ ] Check other fullscreen and borderless games, each monitor, and returning to desktop use after Alt+Tab.
- [x] Confirm Alt+F1 opens the centered shortcut menu; verify current binding parsing and search filtering.
- [ ] Confirm search-field focus, keyboard scrolling, repeated opening, and Esc dismissal on each monitor.
- [ ] If the bar is blank, verify internet access, Zebar v3, and WebView2; inspect Zebar logs.
- [ ] Confirm Win+Enter launches the themed terminal; test installed font/fallback.
- [x] Audit configured shortcuts against Windows defaults; record remaining overlaps in SHORTCUT-CONFLICTS.md.
- [ ] Check every shortcut in README. Record Windows-reserved conflicts; use Alt fallbacks.
- [ ] Check Win+L still locks and native Alt+Tab still works.
- [ ] Test moving/following windows across all ten workspaces; check each screen.
- [ ] Test floating, fullscreen, resize, dialogs, browser picture-in-picture, and PowerToys launcher.
- [x] Set the floating default to always on top; verify an open floating menu through raw GlazeWM IPC.
- [ ] Test Zoom join dialogs, meeting controls, and screen sharing after floating/tiling transitions.
- [ ] Check different monitor scaling, unplug/replug, sleep/resume, and games with tiling paused.
- [ ] Test elevated apps; do not automatically elevate the whole desktop to work around failures.
- [x] Confirm PowerToys Command Palette is enabled and running.
- [x] Configure Command Palette for Alt+Shift+Space; preserve and back up its original shortcut.
- [x] Confirm Alt+Shift+Space opens the launcher, searches for an application, and launches it; user verified on 2026-10-29.
- [ ] Confirm the launcher shortcut also works while GlazeWM is paused.
- [x] Enable this project's launcher-startup opt-in; launch the new desktop shortcut and verify both the bar and Alt+Shift+Space return (2026-10-30).
- [x] Start from stopped GlazeWM/Zebar processes through the native shortcut, then repeat startup and verify component process IDs remain unchanged with one instance each (2026-10-30).
- [ ] After a fresh sign-in, confirm the bar, tiling, and app launcher start automatically and startup.log reports completion.
- [ ] Open ShareX and select local capture destinations/hotkeys if desired.
- [ ] Sign out/in; confirm the single OmarchyWindows.lnk startup shortcut uses this project's managed configuration without duplicate bars.
- [x] Quit GlazeWM/Zebar; rerun install with -SkipPackages; verify baseline backups remain intact.
- [ ] Preview Restore.ps1 -WhatIf, then restore and confirm original settings/startup state.
- [ ] Reapply setup after the restore test.
- [ ] Optional: install/setup WSL and switch WezTerm's default domain.

## Taskbar experiment result

- [x] Apply OS26 Liquid Glass (Dark MacDock); user confirmed the dock on both monitors.
- [x] Restore the original Taskbar Styler settings after the user rejected the appearance; compare every restored registry value and type with the backup.

The liquid-glass preset is optional and is not applied by the main installer.
Taskbar Styler was no longer installed at the final repository sync; Windhawk
remained installed independently of this project's package list.
