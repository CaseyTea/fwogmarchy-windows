#Requires -Version 5.1
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. "$PSScriptRoot\..\scripts\Keybindings.ps1"
function Assert-Shortcut([bool]$Condition, [string]$Message) { if (!$Condition) { throw $Message } }
$fixturePath = Join-Path ([IO.Path]::GetTempPath()) ('omarchy-shortcuts-'+[guid]::NewGuid()+'.yaml')
try {
    $fixture = @'
general:
  startup_commands: ['not a keybinding']
keybindings:
  - commands: ['close']
    bindings: ['alt+shift+q']
  - commands:
      - "focus --workspace 10"
    bindings:
      - "alt+0"
  - bindings: [lwin+f2]
    commands: ['shell-exec explorer.exe "C:\Folder, with spaces\file.txt"']
binding_modes: []
'@
    [IO.File]::WriteAllText($fixturePath,$fixture)
    $entries = @(Get-DesktopKeybindings $fixturePath)
    Assert-Shortcut ($entries.Count -eq 3) 'Parser included unrelated config or dropped a binding.'
    $close = @(Find-DesktopKeybindings $entries 'CLOSE')
    Assert-Shortcut ($close.Count -eq 1 -and $close[0].Shortcuts -eq 'Alt+Shift+Q') 'Close shortcut is missing or search is case-sensitive.'
    Assert-Shortcut (@(Find-DesktopKeybindings $entries 'workspace 10').Count -eq 1) 'Block lists or multi-word search failed.'
    Assert-Shortcut (@(Find-DesktopKeybindings $entries 'workspace q').Count -eq 0) 'Search did not require every term.'
    Assert-Shortcut (@(Find-DesktopKeybindings $entries '').Count -eq 3) 'Empty search did not show all shortcuts.'
    Assert-Shortcut (@($entries | Where-Object { $_.Commands.Contains('C:\Folder, with spaces\file.txt') }).Count -eq 1) 'Quoted commas or backslashes were changed.'
    [IO.File]::WriteAllText($fixturePath,$fixture.Replace('alt+shift+q','alt+control+q'))
    $changed = @(Find-DesktopKeybindings @(Get-DesktopKeybindings $fixturePath) 'close')
    Assert-Shortcut ($changed[0].Shortcuts -eq 'Alt+Ctrl+Q') 'Reopening did not read changed bindings.'
    [IO.File]::WriteAllText($fixturePath,"keybindings:`n  - commands: ['close']`n    bindings: [unclosed")
    $rejected = $false
    try { Get-DesktopKeybindings $fixturePath | Out-Null } catch { $rejected=$true }
    Assert-Shortcut $rejected 'Malformed config silently produced an incomplete menu.'
    $projectEntries = @(Get-DesktopKeybindings "$PSScriptRoot\..\configs\glazewm\config.yaml")
    $help = @(Find-DesktopKeybindings $projectEntries 'shortcut menu')
    Assert-Shortcut ($help.Count -eq 1 -and $help[0].Shortcuts -eq 'Alt+F1') 'The menu cannot discover its own shortcut.'
    Write-Host 'PASS: current bindings, inline/block lists, quoting, live changes, search, malformed config.'
} finally {
    if (Test-Path -LiteralPath $fixturePath) { Remove-Item -LiteralPath $fixturePath }
}
