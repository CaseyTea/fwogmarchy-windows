# Omarchy Windows

A personal Windows 11 desktop setup inspired by your Omarchy environment. Installs GlazeWM, Zebar, WezTerm, PowerToys, ShareX, and Git; applies automatic tiling, ten workspaces, familiar shortcuts, and your Fwog Pond colors to the window borders, bar, and terminal.

This is an initial implementation. Installer recovery is tested in a temporary directory; real window behavior and shortcut conflicts must be checked on Windows 11. See [the acceptance checklist](docs/WINDOWS-CHECKLIST.md).

## Install on your Windows computer

Use your normal Windows user account. WinGet may show an administrator prompt for individual packages. Don't run the entire setup as a different administrator account.

1. Install Git if needed: `winget install --id Git.Git --exact`.
2. Clone the private repository using Git Credential Manager/browser sign-in or an authenticated GitHub CLI:

   ```powershell
   git clone https://github.com/CaseyTea/omarchy-windows.git
   cd omarchy-windows
   .\install.cmd
   ```

   Alternatively, after `gh auth login`, use `gh repo clone CaseyTea/omarchy-windows`.

Setup installs missing packages, backs up settings, applies the configurations, adds a login startup entry, and starts GlazeWM. It fails before writing configs if required executables cannot be found. If an installer requests a restart, reboot and rerun setup. Internet is required for installation and the bar's initial API load.

Review the scripts before running. `install.cmd` uses a process-only execution policy for this script; it does not change the machine's saved execution policy. Organization-managed restrictions can still prevent execution.

## Everyday controls

| Shortcut | Action |
| --- | --- |
| Win+Enter | Terminal |
| Win+Shift+Enter / Win+Shift+B | Default browser (opens Google) |
| Win+Shift+F | Explorer |
| Win+1 through Win+0 | Workspaces 1 through 10 |
| Win+Shift+1 through Win+Shift+0 | Move window and follow it |
| Win+arrows | Directional focus |
| Win+H/J/K | Vim focus left/down/up, where Windows permits |
| **Alt+H/J/K/L** | Full Vim directional focus, including right |
| Win+Shift+arrows / Alt+Shift+H/J/K/L | Move window directionally |
| Alt+1 through Alt+0 | Workspace fallback if Windows intercepts Win+number |
| Alt+Shift+1 through Alt+Shift+0 | Move-and-follow workspace fallback |
| Win+Q | Close focused window |
| Win+T / Win+O | Toggle centered floating window |
| Win+F | Toggle fullscreen |
| Win+V | Change tiling split direction |
| Win+minus / Win+equals | Decrease/increase width |
| Win+Shift+minus / Win+Shift+equals | Decrease/increase height |
| Win+Ctrl+R | Reload GlazeWM config |
| Alt+backtick | Previous workspace |
| **Alt+Shift+P** | Pause/resume tiling and other GlazeWM bindings |
| **Alt+Shift+Escape** | Exit GlazeWM |
| Print Screen | Windows region screenshot |
| Win+Shift+A | ChatGPT in default browser |

Win+L remains Windows lock. Windows may intercept other Win combinations, including Win+H, Win+V, Win+F, and Win+numbers. Test them before relying on them. Alt navigation/workspace fallbacks are provided. Native Alt+Tab is preserved. Pause tiling for games or applications that need their own Alt shortcuts. If you cannot exit using a shortcut, use GlazeWM's tray icon or Task Manager.

PowerToys Command Palette and ShareX are installed with their own defaults. Configure their launch/capture hotkeys through their UIs if desired; the installer does not replace their settings. Print Screen uses Windows capture, not ShareX. Zebar shows current-monitor workspaces and a local clock. The Windows taskbar remains available.

## Reapply after pulling changes

Quit GlazeWM and Zebar from their tray icons, then:

```powershell
git pull
.\install.cmd -SkipPackages
```

Reapplication replaces this project's managed configuration files. Put lasting changes in the repository templates or `theme.json`, then reapply. Existing packages are not automatically upgraded. The original pre-install backup is retained across reruns.

Options: `-NoStart` applies without launching; `-NoStartup` does not create a login startup entry (it does not remove a previously created entry); `-SkipPackages` requires the core apps to already be installed. `-SandboxRoot <path>` is for isolated installer tests and disables packages, startup, and launching.

## Restore original settings

Close GlazeWM and Zebar. Run from the clone:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Restore.ps1 -WhatIf
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Restore.ps1
```

Or, if you moved/deleted the clone:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$env:LOCALAPPDATA\OmarchyWindows\Restore.ps1"
```

Restore returns managed files and the login entry to their pre-install state. Current files are archived first. Packages remain installed; uninstall them separately through Windows Settings if desired. Original backups and recovery manifest live in `%LOCALAPPDATA%\OmarchyWindows`. Never delete that folder before restoring. If setup stops midway, this same restore command recovers files already changed.

## Linux tools and future work

WSL is optional and deliberately separate because it can require elevation, a reboot, and initial user setup:

```powershell
# Elevated PowerShell, then follow Windows' restart/setup instructions:
wsl --install -d Ubuntu
```

Once WSL works, set `config.default_domain = 'WSL:Ubuntu'` in `configs/wezterm/wezterm.lua` and reapply. Compatible shell/editor dotfiles can be moved individually. No SSH keys, credentials, shell history, or whole-home backups are included in this repository.

Your Omarchy uses a 60% centered master layout, custom pop-out behavior, and independent numbered workspaces per monitor. This version uses GlazeWM's split tiling, centered floating toggle, and globally named workspaces. It does not reproduce those behaviors exactly. A centered-master backend, theme switching UI, local bundled bar dependencies, WSL tool provisioning, launcher menus, wallpaper sync, and application-specific rules are future work.

## Project structure

- `Install.ps1`, `install.cmd`: Windows bootstrap and configuration application.
- `packages.json`: exact WinGet package IDs; installs currently available versions.
- `theme.json`: personal Fwog Pond palette, translated from the current Omarchy theme.
- `configs/`: GlazeWM, WezTerm, and custom Zebar bar templates.
- `scripts/`: stable startup, diagnostics, and restore helpers.
- `tests/`: parser checks and isolated install/rerun/restore checks.
- `docs/PROJECT.md`: scope, source references, and implementation decisions.

Run diagnostics with `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Doctor.ps1`.
