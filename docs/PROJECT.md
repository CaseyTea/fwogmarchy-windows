# Project handoff

## Objective

Clone a private repository on Windows 11, run one installer, and get a familiar Omarchy-style desktop with recoverable configuration changes. The setup was installed and exercised on the user's Windows 11 Pro machine, build 26200, with two monitors on 2026-10-29. See `WINDOWS-CHECKLIST.md` for verified behavior and remaining manual checks.

## Source observations

Read locally on 2026-10-28:

- Personal Hyprland bindings: Super+H/J/K/L directional focus, Super+O custom pop-out, centered-master helpers.
- Personal layout: centered master, 60% width, retained center position.
- Terminal: JetBrainsMono Nerd Font, 14px padding, minimal decorations.
- Active theme: Fwog Pond; green accent `#b5d96b`, background `#172823`.

Only the color palette and translated behaviors are included. No raw user configuration, machine monitor identifiers, credentials, private paths, or unrelated settings are copied.

## Implementation

GlazeWM owns window/workspace shortcuts. Zebar provides a custom bar with clickable workspaces on each monitor and a local clock. WezTerm uses the shared palette and font fallback. Windows retains lock, taskbar, notifications, and its default screenshot UI. PowerToys and ShareX are available for later customization.

Alt+F1 opens a searchable WPF shortcut menu using the active GlazeWM config.
The parser reads the project's inline and block YAML string lists without
evaluating commands. The menu and parser are installed in LocalAppData with a
copy of the palette, so they keep working if the clone moves. A named mutex
and activation signal bring an existing menu forward instead of opening copies.
The menu floats, and floating windows default to always on top. Closing a
focused window uses Alt+Shift+Q after Windows intercepted Win+Q.

PowerToys Command Palette provides application search on Alt+Shift+Space after
running `Set-AppLauncher.ps1`. PowerToys owns activation independently of
GlazeWM. The helper backs up and changes only the shortcut, with a separate
`-Restore` action that preserves newer unrelated preferences. The main installer
copies the helper but does not replace PowerToys settings or enable its startup.
The shortcut menu reads Command Palette's actual hotkey from its local settings
when available; a missing or malformed external config does not break the menu.

Zebar's pack name is `omarchy-windows`, matching the startup command. The bar's
HTML, CSS, and JavaScript are explicitly listed in `includeFiles`; omitting
those assets caused the original blank/error bar. GlazeWM starts with a hidden
console window.

Each managed destination is recorded in an installation manifest before writing it. Existing file contents are saved once; reruns retain this baseline. Restore archives current managed files and restores originals, or removes files the project created. Settings backups stay outside the repository. Packages are installed before config changes; a required package failure stops application. Files already written during a later failure can be recovered using the manifest. There is no claim of a system-wide transaction or rollback of package installs.

Login startup uses a per-user `.cmd` file calling a stable PowerShell script in LocalAppData. The clone can move after installation. Use only this login entry; disable any app-created duplicate autostart entries if the installed versions add them. Desktop apps run at the normal user privilege level. Tiling elevated applications still needs Windows testing.

The default font is requested but font files are not redistributed. Install JetBrainsMono Nerd Font yourself for an exact match; otherwise the terminal falls back to installed Windows fonts. WezTerm starts native PowerShell until WSL is configured.

## Known limitations

- Hyprland animations, compositor effects, scratchpads, grouping, centered master, and independent per-monitor workspace numbering are not implemented.
- Windows reserves Win+L and may intercept other Windows-key shortcuts. Alt navigation/workspaces provide fallbacks. `SHORTCUT-CONFLICTS.md` records the remaining overlaps; the audit did not remap them.
- Package IDs are exact, but versions follow current WinGet availability; this is repeatable configuration, not a frozen binary distribution.
- Zebar uses its v3 widget-pack format and a pinned `zebar@3.0.0` API module loaded from esm.sh. It needs network access on first load. Offline vendoring is a follow-up.
- PowerToys/ShareX settings, wallpaper, Windows global theme, editor config, and WSL dotfiles are not automatically applied.
- Physical desktop validation covers the bar on both monitors, menu opening, themed terminal, workspace-button focus, pause/resume, and the floating default. It does not cover every shortcut, login startup, all dialogs, sleep/resume, or elevated apps. GitHub Actions tests scripts/state handling, not window behavior.

## Taskbar experiment

Windhawk 1.7.3 and Windows 11 Taskbar Styler 1.10 were used to try OS26 Liquid
Glass (Dark MacDock), including translucent Fwog Pond icon backgrounds and
82% icon opacity. The user confirmed it appeared on both monitors, then asked
to roll it back. The original mod settings were restored and verified against
the saved baseline. Taskbar Styler was absent when the repository was synced;
Windhawk itself remained installed separately.

This experiment is retained in `configs/windhawk/liquid-glass.json` and
`scripts/Set-TaskbarTheme.ps1`, outside the default installer and package list.
It requires administrator permission, saves its own original registry settings,
and has a separate `-Restore` action. The core file restore does not manage
Windhawk. Machine-specific backups and review downloads stay in LocalAppData.

The installed mod source matched upstream commit
`162bca0d6b4fe4da2c63c21f17921a165d5870fa`. Static inspection found no evidence
of malicious behavior in the paths reviewed, but is not a security guarantee.
The source includes roughly daily theme-usage requests to GitHub. Windhawk's
privileged service and process injection remain a separate trust decision.

## Next Windows session

Follow `WINDOWS-CHECKLIST.md`. Resolve intercepted shortcuts and application process rules based on observed behavior. No Zoom-specific rule was added after the meeting-window issue recovered when floating was toggled off. If the exact 60% centered master is essential, evaluate komorebi as a replacement backend before further tiling customizations. Do not run competing window managers simultaneously.

## Upstream references

- [GlazeWM configuration and installation](https://github.com/glzr-io/glazewm)
- [GlazeWM configuration schema example](https://github.com/glzr-io/glazewm/blob/main/resources/assets/sample-config.yaml)
- [Zebar widget packs and providers](https://github.com/glzr-io/zebar)
- [Zebar pack schema](https://github.com/glzr-io/zebar/blob/main/resources/zpack-schema.json)
- [WezTerm configuration](https://wezterm.org/config/files.html)
- [PowerToys Command Palette](https://learn.microsoft.com/en-us/windows/powertoys/command-palette/overview)
- [WSL installation](https://learn.microsoft.com/en-us/windows/wsl/install)
- [ShareX](https://getsharex.com/)
- [Reviewed Taskbar Styler source](https://github.com/ramensoftware/windhawk-mods/blob/162bca0d6b4fe4da2c63c21f17921a165d5870fa/mods/windows-11-taskbar-styler.wh.cpp)
- [Windhawk injection behavior](https://github.com/ramensoftware/windhawk/wiki/Injection-targets-and-critical-system-processes)

This project is an independent configuration bundle, not an official Omarchy Windows release. Dependencies are installed from their publishers through WinGet and retain their respective licenses.
