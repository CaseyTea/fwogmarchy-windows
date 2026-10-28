# Windows acceptance checklist

Not yet executed on a physical Windows desktop. Record results here as you test.

- [ ] Run installer as the intended user on Windows 11; review package failures or restart notices.
- [ ] Run Doctor.ps1; verify three core executables and configuration files are found.
- [ ] Open three ordinary apps; verify automatic tiling and visible focused border.
- [ ] Confirm one Fwog Pond bar per screen, clickable workspace buttons, and local clock.
- [ ] If the bar is blank, verify internet access, Zebar v3, and WebView2; inspect Zebar logs.
- [ ] Confirm Win+Enter launches the themed terminal; test installed font/fallback.
- [ ] Check every shortcut in README. Record Windows-reserved conflicts; use Alt fallbacks.
- [ ] Check Win+L still locks and native Alt+Tab still works.
- [ ] Test moving/following windows across all ten workspaces; check each screen.
- [ ] Test floating, fullscreen, resize, dialogs, browser picture-in-picture, and PowerToys launcher.
- [ ] Check different monitor scaling, unplug/replug, sleep/resume, and games with tiling paused.
- [ ] Test elevated apps; do not automatically elevate the whole desktop to work around failures.
- [ ] Open PowerToys and enable Command Palette with your preferred launcher shortcut.
- [ ] Open ShareX and select local capture destinations/hotkeys if desired.
- [ ] Sign out/in; confirm startup is singular and uses this project's managed configuration.
- [ ] Quit GlazeWM/Zebar; rerun install with -SkipPackages; verify baseline backups remain intact.
- [ ] Preview Restore.ps1 -WhatIf, then restore and confirm original settings/startup state.
- [ ] Reapply setup after the restore test.
- [ ] Optional: install/setup WSL and switch WezTerm's default domain.
