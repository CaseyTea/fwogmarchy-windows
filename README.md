# Omarchy Windows

A personal Windows 11 desktop setup inspired by your Omarchy environment. Installs GlazeWM, Zebar, WezTerm, PowerToys, ShareX, and Git; applies automatic tiling, ten workspaces, familiar shortcuts, and your Fwog Pond colors to the window borders, bar, and terminal.

Installed and exercised on Windows 11 Pro, build 26200, with two monitors on
2026-10-29. The bar, shortcut menu, terminal, and floating defaults have been
checked; broader application and startup checks remain in [the acceptance
checklist](docs/WINDOWS-CHECKLIST.md). See [the change log](CHANGELOG.md) for the
latest desktop updates.

## Install on your Windows computer

Use your normal Windows user account. WinGet may show an administrator prompt for individual packages. Don't run the entire setup as a different administrator account.

1. Install Git if needed: `winget install --id Git.Git --exact`.
2. Clone the private repository using Git Credential Manager/browser sign-in or an authenticated GitHub CLI:

   ```powershell
   git clone https://github.com/CaseyTea/fwogmarchy-windows.git
   cd fwogmarchy-windows
   .\install.cmd
   ```

   Alternatively, after `gh auth login`, use `gh repo clone CaseyTea/fwogmarchy-windows`.

Setup installs missing packages, backs up settings, applies the configurations, adds a login startup entry, and starts GlazeWM. It fails before writing configs if required executables cannot be found. If an installer requests a restart, reboot and rerun setup. Internet is required for installation and the bar's initial API load.

Review the scripts before running. `install.cmd` uses a process-only execution policy for this script; it does not change the machine's saved execution policy. Organization-managed restrictions can still prevent execution.

## Everyday controls

| Shortcut | Action |
| --- | --- |
| **Alt+F1** | Search current desktop shortcuts; Esc closes the menu |
| **Alt+Shift+Space** | Search and open applications with Command Palette (after launcher setup below) |
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
| Alt+Shift+Q | Close focused window |
| Win+T / Win+O | Toggle centered floating window (always on top) |
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

Win+L remains Windows lock. Windows may intercept other Win combinations, including Win+H, Win+V, Win+F, and Win+numbers. Test them before relying on them. Alt navigation/workspace fallbacks are provided. See [the shortcut conflict audit](docs/SHORTCUT-CONFLICTS.md) for the overlaps that remain. Native Alt+Tab is preserved. Pause tiling for games or applications that need their own Alt shortcuts. If you cannot exit using a shortcut, use GlazeWM's tray icon or Task Manager.

PowerToys Command Palette provides application search; its launcher setup is
described below. ShareX keeps its own defaults and capture hotkeys. The main
installer does not replace PowerToys or ShareX settings. Print Screen uses
Windows capture, not ShareX. Zebar shows current-monitor workspaces and a local
clock. The Windows taskbar remains available.

The Fwog Pond bar uses normal window priority so fullscreen games and videos
can cover it. GlazeWM reserves space above tiled desktop windows for the bar.
Floating windows keep their always-on-top behavior.

## Application launcher

Press **Alt+Shift+Space**, type an application name, and press **Enter** to open
it. This uses [PowerToys Command Palette](https://learn.microsoft.com/en-us/windows/powertoys/command-palette/overview).
PowerToys owns this shortcut, so it works independently of GlazeWM's pause state.
Windows' Win+Space keyboard-language switcher is kept available.

On a new machine, open PowerToys, enable Command Palette, and open it once using
its default **Win+Alt+Space** shortcut. Then run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Set-AppLauncher.ps1
```

The helper changes only the activation shortcut and saves the original under
`%LOCALAPPDATA%\OmarchyWindows\command-palette-hotkey-original.json`. It preserves
your extensions, pinned items, appearance, and other preferences. If the new
shortcut is not picked up immediately, restart Command Palette. Enable
PowerToys' **Run at startup** option to keep the launcher available after login.

To restore just the previous launcher shortcut, run the same helper with
`-Restore`. The core desktop file restore does not change this PowerToys setting.
Run the launcher restore first if you want both undone.
Alt+F1 shows the actual launcher shortcut read from Command Palette's settings,
including changes made later in its UI.

## Shortcut menu

Press **Alt+F1** to open the searchable Fwog Pond shortcut menu. Type an action
such as `close`, `terminal`, or `workspace 10`, or a key combination such as
`Alt+Shift+Q`. Press **Esc** or click **Close** to dismiss it. Repeating Alt+F1
brings the existing menu to the front.

The menu reads desktop bindings from your active GlazeWM config each time it
opens, including local shortcut changes, plus Command Palette's activation
shortcut when its settings are available. It supports the inline and block
string lists used by this project. Other PowerToys utilities and individual
applications have their own shortcut settings. Alt+F1 follows GlazeWM's pause state; use
Alt+Shift+P to resume desktop shortcuts when paused.

## Floating windows

Floating windows are centered and stay above tiled windows by default.
Minimize a floating window when you want it out of view. Fullscreen windows
keep their separate default and are not made always on top.

No Zoom-specific window rule is installed. A small meeting window recovered
during testing after floating was toggled off; joining calls and sharing screens
still need broader application testing. If a call dialog becomes unusably small,
try toggling floating off or pausing GlazeWM with Alt+Shift+P.

## Liquid Glass taskbar experiment (optional, rolled back)

The Liquid Glass appearance was tried on both monitors and rolled back on
2026-10-29. The default setup keeps the existing Windows taskbar appearance.
Windhawk is not in `packages.json`, and `Install.ps1` never applies its settings.
The preset and recovery helper below are retained as an optional experiment.

The taskbar preset in `configs/windhawk/liquid-glass.json` uses Windhawk's
**Windows 11 Taskbar Styler** mod with the **OS26 Liquid Glass (Dark MacDock)**
theme by WasiXGamer. App icons use 82% opacity and return to full opacity on
hover; their backgrounds use translucent Fwog Pond gradients.

Install Windhawk (`winget install --id RamenSoftware.Windhawk --exact`) and
install **Windows 11 Taskbar Styler** by m417z from its catalog. Then run from
an administrator PowerShell in this repository:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Set-TaskbarTheme.ps1
```

The helper requires administrator permission and backs up the mod's original settings once in
`%LOCALAPPDATA%\OmarchyWindows\windhawk-taskbar-original.json`, applies the
preset, and asks Windhawk to reload it without restarting Explorer. To undo,
run the same helper with `-Restore`, or disable the mod in Windhawk. These
Windhawk settings have their own restore step, separate from the desktop
configuration-file restore below. Restoring settings does not uninstall Windhawk
or the mod; remove them separately if no longer wanted.

Do not combine this preset with the **Taskbar height and icon size** mod;
the theme controls its own dock height. Upstream theme and customization
reference: [OS26 Liquid Glass](https://github.com/ramensoftware/windows-11-taskbar-styling-guide/tree/main/Themes/OS26%20Liquid%20Glass).

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
- `configs/`: GlazeWM, WezTerm, and custom Zebar bar templates, plus the optional taskbar experiment.
- `scripts/`: stable startup, diagnostics, and restore helpers.
- `tests/`: parser checks and isolated install/rerun/restore checks.
- `docs/PROJECT.md`: scope, source references, and implementation decisions.

Run diagnostics with `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Doctor.ps1`.
Run automated checks with `.\tests\Verify.ps1` in Windows PowerShell 5.1 or
PowerShell 7. The lifecycle checks require GlazeWM and Zebar to be closed,
including when their file targets are temporary; GitHub Actions runs both shells
on a clean Windows runner. To check shortcut parsing and search while using the
desktop, run `.\tests\Keybindings.ps1` and `.\tests\AppLauncher.ps1`.
