#Requires -Version 5.1
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$SettingsPath = (Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.CommandPalette_8wekyb3d8bbwe\LocalState\settings.json'),
    [string]$StateDirectory = (Join-Path $env:LOCALAPPDATA 'OmarchyWindows'),
    [switch]$Restore
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$SettingsPath = [IO.Path]::GetFullPath($SettingsPath)
$backupPath = Join-Path $StateDirectory 'command-palette-hotkey-original.json'
$originalText = [IO.File]::ReadAllText($SettingsPath)
$settings = $originalText | ConvertFrom-Json
if (!$settings.PSObject.Properties['Hotkey']) { throw 'Command Palette has no Hotkey setting. Enable and open it once in PowerToys before configuring the launcher.' }
if ($Restore) {
    $backup = Get-Content -LiteralPath $backupPath -Raw | ConvertFrom-Json
    if ($backup.version -ne 1 -or $backup.settingsPath -ne $SettingsPath) { throw 'The launcher backup belongs to a different settings file or format.' }
    $hotkey = $backup.hotkey
} else {
    $hotkey = [pscustomobject]@{ win=$false; ctrl=$false; alt=$true; shift=$true; code=32; key='' }
}
foreach ($name in @('win','ctrl','alt','shift')) {
    if ($hotkey.$name -isnot [bool]) { throw "Invalid hotkey modifier: $name" }
}
if ($hotkey.code -isnot [ValueType] -or $hotkey.code -lt 1 -or $hotkey.code -gt 255 -or $hotkey.key -isnot [string]) { throw 'Invalid hotkey key.' }
$operation = if ($Restore) { 'Restore the original app launcher shortcut' } else { 'Set the app launcher shortcut to Alt+Shift+Space' }
if ($PSCmdlet.ShouldProcess($SettingsPath,$operation)) {
    [IO.Directory]::CreateDirectory($StateDirectory) | Out-Null
    if (!$Restore -and !(Test-Path -LiteralPath $backupPath)) {
        $backup = [pscustomobject]@{ version=1; settingsPath=$SettingsPath; hotkey=$settings.Hotkey; created=(Get-Date -Format o) }
        [IO.File]::WriteAllText($backupPath,($backup | ConvertTo-Json -Depth 10),[Text.UTF8Encoding]::new($false))
    } elseif (!$Restore) {
        $backup = Get-Content -LiteralPath $backupPath -Raw | ConvertFrom-Json
        if ($backup.version -ne 1 -or $backup.settingsPath -ne $SettingsPath) { throw 'An existing launcher backup belongs to a different settings file or format.' }
    }
    # Own only this shortcut; retain extensions, pins, theme, history preferences, and other settings.
    $settings.Hotkey = $hotkey
    $temporaryPath = Join-Path (Split-Path -Parent $SettingsPath) ('.omarchy-launcher-'+[guid]::NewGuid()+'.tmp')
    try {
        [IO.File]::WriteAllText($temporaryPath,($settings | ConvertTo-Json -Depth 100),[Text.UTF8Encoding]::new($false))
        if ([IO.File]::ReadAllText($SettingsPath) -cne $originalText) { throw 'Command Palette settings changed while preparing the shortcut. Run the helper again.' }
        # Windows PowerShell needs a typed null here; $null becomes an empty path.
        [IO.File]::Replace($temporaryPath,$SettingsPath,[NullString]::Value)
    } finally {
        if (Test-Path -LiteralPath $temporaryPath) { Remove-Item -LiteralPath $temporaryPath -Force }
    }
    Write-Host "$operation complete. Original shortcut: $backupPath"
}
