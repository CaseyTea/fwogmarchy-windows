# Windows shortcut conflict audit

Reviewed on 2026-10-29 against the project GlazeWM config and Microsoft's
[Windows shortcut reference](https://support.microsoft.com/en-gb/accessibility/windows/keyboard-shortcuts-in-windows).
These are overlaps with documented defaults, not a claim that every combination
is intercepted on every PC. Windows build, hardware, enabled features, and the
focused app affect which handler wins. The audit did not remap these bindings.

| Project binding | Windows default overlap | Existing project fallback |
| --- | --- | --- |
| Win+1 through Win+0 | Taskbar app slots | Alt+1 through Alt+0 |
| Win+Shift+1 through Win+Shift+0 | New taskbar app instances | Alt+Shift+1 through Alt+Shift+0 |
| Win+arrows | Snap, maximize, minimize | Alt+H/J/K/L |
| Win+Shift+arrows | Monitor moves or vertical sizing | Alt+Shift+H/J/K/L |
| Win+H / Win+J / Win+K | Dictation / Recall on supported PCs / Cast | Alt+H/J/K |
| Win+T / Win+O | Taskbar cycling / orientation lock | None for floating |
| Win+F | Feedback Hub | None for fullscreen |
| Win+V | Clipboard history | None for split direction |
| Win+minus / Win+equals | Magnifier zoom keys, depending on modifier handling | None for width resize |
| Win+Shift+Enter | UWP fullscreen | Win+Shift+B for browser |
| Win+Shift+A | Windows-tip focus | None for ChatGPT launcher |

Win+Q was removed after it opened Windows search instead of closing the focused
app. Alt+Shift+Q now closes that window. Alt+F4 remains the native Windows close
shortcut. Alt+F1 opens the shortcut menu. Native Win+L and Alt+Tab are retained.

Alt fallbacks can overlap application commands, and Alt+Shift can switch input
languages when that shortcut is enabled. Alt+Shift+P also overlaps Explorer's
details-pane toggle. Pause GlazeWM with Alt+Shift+P when an app needs these keys;
resume with the same combination. GlazeWM's tray menu is the recovery path if
a shortcut is intercepted. Check Alt+Shift+Escape on the target build as well;
it shares Alt+Escape's window-cycling chord family.

The menu reports configured GlazeWM shortcuts. It does not detect which keys
Windows or another app will intercept, and it does not include independent
PowerToys or ShareX shortcuts.
