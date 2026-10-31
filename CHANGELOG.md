# Change log

## 2026-10-30

- Replaced the legacy project startup batch file with a standard Windows startup shortcut targeting the stable helper and working directory. The installer migrates the old matching entry and retains both files' original restore baselines.
- Added startup logging, a single-instance guard, bounded GlazeWM readiness checks, and explicit bar recovery when the WM is already running. A missing terminal no longer blocks the desktop.
- Made the desktop helper the single owner of bar startup; GlazeWM's startup command list is now empty.
- Added PowerToys/Command Palette startup after launcher setup, preserving its shortcut backup and other module preferences. Launcher restore removes this startup opt-in.
- Added native startup-shortcut and launcher opt-in checks. Direct shortcut launch restored both desktop and launcher; a stopped-state desktop launch and repeated-startup instance check passed. A fresh sign-in remains to be verified.

## 2026-10-29

- Changed the Fwog Pond bar to normal window priority so it can be covered by fullscreen games and videos. Desktop tiling keeps its existing top gap.
- Added an opt-in Alt+Shift+Space app launcher using PowerToys Command Palette, with a property-only shortcut backup/restore helper. Alt+F1 reads and displays the actual configured launcher shortcut.
- Updated clone instructions for the renamed `CaseyTea/fwogmarchy-windows` repository.
- Installed and exercised the desktop on Windows 11 Pro, build 26200, with two monitors.
- Added an Alt+F1 shortcut menu with action/key search, live config parsing on opening, Fwog Pond colors, and single-window activation.
- Installed the menu helpers and palette alongside the startup/recovery scripts so they survive moving the clone.
- Changed close-focused-window from Win+Q to Alt+Shift+Q.
- Made centered floating windows always on top by default; fullscreen keeps its separate default.
- Fixed the blank Zebar bar by matching its pack name to the startup command and including the HTML, CSS, and JavaScript assets.
- Hid the GlazeWM startup console window.
- Added shortcut-parser/search checks and included menu cleanup in the isolated installer lifecycle checks.
- Recorded Windows shortcut overlaps and the manual checks still outstanding. Existing overlapping bindings were retained.
- Reviewed and tried a Liquid Glass taskbar with translucent icons, then restored the original taskbar settings at the user's request. The preset and restore helper remain optional; the main installer never installs or configures Windhawk.
- Recorded that the Zoom meeting-window issue recovered after floating was toggled off; no Zoom-specific rule was added.
