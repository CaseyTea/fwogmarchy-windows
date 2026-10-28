# Project handoff

## Objective

Clone a private repository on Windows 11, run one installer, and get a familiar Omarchy-style desktop with recoverable configuration changes. Initial target: the user's personal machine; no Windows device has been used for visual/runtime validation yet.

## Source observations

Read locally on 2026-10-28:

- Personal Hyprland bindings: Super+H/J/K/L directional focus, Super+O custom pop-out, centered-master helpers.
- Personal layout: centered master, 60% width, retained center position.
- Terminal: JetBrainsMono Nerd Font, 14px padding, minimal decorations.
- Active theme: Fwog Pond; green accent `#b5d96b`, background `#172823`.

Only the color palette and translated behaviors are included. No raw user configuration, machine monitor identifiers, credentials, private paths, or unrelated settings are copied.

## Implementation

GlazeWM owns window/workspace shortcuts. Zebar provides a custom bar with clickable workspaces on each monitor and a local clock. WezTerm uses the shared palette and font fallback. Windows retains lock, taskbar, notifications, and its default screenshot UI. PowerToys and ShareX are available for later customization.

Each managed destination is recorded in an installation manifest before writing it. Existing file contents are saved once; reruns retain this baseline. Restore archives current managed files and restores originals, or removes files the project created. Settings backups stay outside the repository. Packages are installed before config changes; a required package failure stops application. Files already written during a later failure can be recovered using the manifest. There is no claim of a system-wide transaction or rollback of package installs.

Login startup uses a per-user `.cmd` file calling a stable PowerShell script in LocalAppData. The clone can move after installation. Use only this login entry; disable any app-created duplicate autostart entries if the installed versions add them. Desktop apps run at the normal user privilege level. Elevated app management needs Windows testing.

The default font is requested but font files are not redistributed. Install JetBrainsMono Nerd Font yourself for an exact match; otherwise the terminal falls back to installed Windows fonts. WezTerm starts native PowerShell until WSL is configured.

## Known limitations

- Hyprland animations, compositor effects, scratchpads, grouping, centered master, and independent per-monitor workspace numbering are not implemented.
- Windows reserves Win+L and may intercept other Windows-key shortcuts. Alt navigation/workspaces provide fallbacks. Windows build-specific testing is required.
- Package IDs are exact, but versions follow current WinGet availability; this is repeatable configuration, not a frozen binary distribution.
- Zebar uses its v3 widget-pack format and a pinned `zebar@3.0.0` API module loaded from esm.sh. It needs network access on first load. Offline vendoring is a follow-up.
- PowerToys/ShareX settings, wallpaper, Windows global theme, editor config, and WSL dotfiles are not automatically applied.
- No physical Windows desktop validation has occurred. GitHub Actions tests scripts/state handling, not window behavior.

## Next Windows session

Follow `WINDOWS-CHECKLIST.md`. Resolve intercepted shortcuts and application process rules based on observed behavior. If the exact 60% centered master is essential, evaluate komorebi as a replacement backend before further tiling customizations. Do not run competing window managers simultaneously.

## Upstream references

- [GlazeWM configuration and installation](https://github.com/glzr-io/glazewm)
- [GlazeWM configuration schema example](https://github.com/glzr-io/glazewm/blob/main/resources/assets/sample-config.yaml)
- [Zebar widget packs and providers](https://github.com/glzr-io/zebar)
- [Zebar pack schema](https://github.com/glzr-io/zebar/blob/main/resources/zpack-schema.json)
- [WezTerm configuration](https://wezterm.org/config/files.html)
- [PowerToys Command Palette](https://learn.microsoft.com/en-us/windows/powertoys/command-palette/overview)
- [WSL installation](https://learn.microsoft.com/en-us/windows/wsl/install)
- [ShareX](https://getsharex.com/)

This project is an independent configuration bundle, not an official Omarchy Windows release. Dependencies are installed from their publishers through WinGet and retain their respective licenses.
