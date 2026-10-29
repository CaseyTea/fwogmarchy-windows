#Requires -Version 5.1
#Requires -RunAsAdministrator
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$ThemePath = (Join-Path $PSScriptRoot '..\configs\windhawk\liquid-glass.json'),
    [string]$StateDirectory = (Join-Path $env:LOCALAPPDATA 'OmarchyWindows'),
    [switch]$Restore
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$backupPath = Join-Path $StateDirectory 'windhawk-taskbar-original.json'
$resultPath = Join-Path $StateDirectory 'taskbar-theme-result.json'
$registryPath = 'SOFTWARE\Windhawk\Engine\Mods\windows-11-taskbar-styler'
$machine = $null; $mod = $null; $settings = $null
try {
    [IO.Directory]::CreateDirectory($StateDirectory) | Out-Null
    $machine = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, [Microsoft.Win32.RegistryView]::Registry64)
    $mod = $machine.OpenSubKey($registryPath, $true)
    if (!$mod) { throw 'Install Windows 11 Taskbar Styler in Windhawk before applying this theme.' }
    if ($Restore) {
        $backup = Get-Content -LiteralPath $backupPath -Raw | ConvertFrom-Json
        if ($backup.version -ne 1) { throw 'Unknown taskbar backup format.' }
        $restoreValues = @(foreach ($entry in $backup.values) {
            $kind = [Microsoft.Win32.RegistryValueKind][Enum]::Parse([Microsoft.Win32.RegistryValueKind], [string]$entry.kind)
            $value = $entry.value
            switch ($entry.kind) {
                'Binary' { $value = [Convert]::FromBase64String($value) }
                'MultiString' { $value = [string[]]$value }
                'DWord' { $value = [int]$value }
                'QWord' { $value = [long]$value }
            }
            [pscustomobject]@{ name=[string]$entry.name; kind=$kind; value=$value }
        })
    } else {
        $theme = Get-Content -LiteralPath $ThemePath -Raw | ConvertFrom-Json
        if ($theme.theme -ne 'OS26_Liquid_Glass_variant_DarkMacDock') { throw 'Unexpected taskbar theme.' }
        foreach ($property in $theme.PSObject.Properties) {
            if ($property.Name -notmatch '^(theme|styleConstants\[\d+\]|controlStyles\[\d+\]\.(target|styles\[\d+\]))$' -or $property.Value -isnot [string]) {
                throw "Unexpected taskbar setting: $($property.Name)"
            }
        }
    }
    $operation = if ($Restore) { 'Restore original taskbar styling settings' } else { 'Apply Liquid Glass dock and translucent icons' }
    if ($PSCmdlet.ShouldProcess('Windhawk Windows 11 Taskbar Styler', $operation)) {
        $settings = $mod.OpenSubKey('Settings', $true)
        if (!$Restore -and !(Test-Path -LiteralPath $backupPath)) {
            $originalValues = @()
            if ($settings) {
                $originalValues = @(foreach ($name in $settings.GetValueNames()) {
                    $kind = $settings.GetValueKind($name).ToString()
                    $value = $settings.GetValue($name, $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
                    if ($kind -eq 'Binary') { $value = [Convert]::ToBase64String($value) }
                    [pscustomobject]@{ name=$name; kind=$kind; value=$value }
                })
            }
            $backup = [pscustomobject]@{ version=1; existed=($null -ne $settings); values=$originalValues; created=(Get-Date -Format o) }
            [IO.File]::WriteAllText($backupPath, ($backup | ConvertTo-Json -Depth 10), [Text.UTF8Encoding]::new($false))
        }
        if (!$settings) { $settings = $mod.CreateSubKey('Settings') }
        # Keep unrelated mod preferences when applying the preset.
        foreach ($name in $settings.GetValueNames()) {
            if ($Restore -or $name -match '^(theme|styleConstants\[\d+\]|controlStyles\[\d+\]\.(target|styles\[\d+\])|themeResourceVariables\[\d+\])$') {
                $settings.DeleteValue($name)
            }
        }
        if ($Restore) {
            foreach ($entry in $restoreValues) { $settings.SetValue($entry.name,$entry.value,$entry.kind) }
            if (!$backup.existed) {
                $settings.Dispose(); $settings=$null
                $mod.DeleteSubKey('Settings')
            }
        } else {
            foreach ($property in $theme.PSObject.Properties) { $settings.SetValue($property.Name,$property.Value,[Microsoft.Win32.RegistryValueKind]::String) }
        }
        # Windhawk's documented notification mechanism reloads settings live.
        $changeTime = [int][DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
        if ($mod.GetValue('SettingsChangeTime') -eq $changeTime) { $changeTime++ }
        $mod.SetValue('SettingsChangeTime',$changeTime,[Microsoft.Win32.RegistryValueKind]::DWord)
        [IO.File]::WriteAllText($resultPath, (@{ success=$true; restored=[bool]$Restore; completed=(Get-Date -Format o) } | ConvertTo-Json), [Text.UTF8Encoding]::new($false))
        Write-Host "$operation complete. Original settings: $backupPath"
    }
} catch {
    try { [IO.File]::WriteAllText($resultPath, (@{ success=$false; error=$_.Exception.Message } | ConvertTo-Json), [Text.UTF8Encoding]::new($false)) } catch { }
    throw
} finally {
    if ($settings) { $settings.Dispose() }
    if ($mod) { $mod.Dispose() }
    if ($machine) { $machine.Dispose() }
}
