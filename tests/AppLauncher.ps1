#Requires -Version 5.1
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. "$PSScriptRoot\..\scripts\Keybindings.ps1"
function Assert-Launcher([bool]$Condition,[string]$Message) { if (!$Condition) { throw $Message } }
$testRoot = Join-Path ([IO.Path]::GetTempPath()) ('omarchy-launcher-test-'+[guid]::NewGuid())
try {
    [IO.Directory]::CreateDirectory($testRoot) | Out-Null
    $settingsPath = Join-Path $testRoot 'settings.json'
    $stateDirectory = Join-Path $testRoot 'state'
    $fixture = '{"Hotkey":{"win":true,"ctrl":false,"alt":true,"shift":false,"code":32,"key":""},"Theme":"Keep this","ProviderSettings":{"custom":{"value":42}}}'
    [IO.File]::WriteAllText($settingsPath,$fixture)
    $helper = "$PSScriptRoot\..\scripts\Set-AppLauncher.ps1"
    & $helper -SettingsPath $settingsPath -StateDirectory $stateDirectory -WhatIf
    Assert-Launcher ([IO.File]::ReadAllText($settingsPath) -ceq $fixture) 'WhatIf changed launcher settings.'
    Assert-Launcher (!(Test-Path -LiteralPath $stateDirectory)) 'WhatIf created launcher backup state.'
    & $helper -SettingsPath $settingsPath -StateDirectory $stateDirectory -Confirm:$false
    $backupPath = Join-Path $stateDirectory 'command-palette-hotkey-original.json'
    $firstBackup = [IO.File]::ReadAllText($backupPath)
    $configured = Get-Content -LiteralPath $settingsPath -Raw | ConvertFrom-Json
    $startupPath = Join-Path $stateDirectory 'app-launcher-startup.json'
    Assert-Launcher ((Get-Content -LiteralPath $startupPath -Raw | ConvertFrom-Json).enabled) 'Launcher setup did not enable desktop-managed startup.'
    Assert-Launcher ($configured.Theme -eq 'Keep this' -and $configured.ProviderSettings.custom.value -eq 42) 'Setting the hotkey changed unrelated preferences.'
    $entry = @(Get-AppLauncherKeybinding $settingsPath)
    Assert-Launcher ($entry.Count -eq 1 -and $entry[0].Shortcuts -eq 'Alt+Shift+Space') 'Shortcut help did not read the actual launcher hotkey.'
    Assert-Launcher (@(Find-DesktopKeybindings $entry 'launcher').Count -eq 1) 'Searching shortcut help for launcher did not find app search.'
    $configured.Theme = 'Changed later'
    [IO.File]::WriteAllText($settingsPath,($configured | ConvertTo-Json -Depth 10))
    & $helper -SettingsPath $settingsPath -StateDirectory $stateDirectory -Confirm:$false
    Assert-Launcher ([IO.File]::ReadAllText($backupPath) -ceq $firstBackup) 'Reapplying replaced the original shortcut backup.'
    & $helper -SettingsPath $settingsPath -StateDirectory $stateDirectory -Restore -Confirm:$false
    $restored = Get-Content -LiteralPath $settingsPath -Raw | ConvertFrom-Json
    Assert-Launcher (!(Test-Path -LiteralPath $startupPath)) 'Launcher restore left desktop-managed launcher startup enabled.'
    Assert-Launcher ($restored.Hotkey.win -and $restored.Hotkey.alt -and !$restored.Hotkey.shift -and $restored.Hotkey.code -eq 32) 'Restore lost the original launcher shortcut.'
    Assert-Launcher ($restored.Theme -eq 'Changed later' -and $restored.ProviderSettings.custom.value -eq 42) 'Restore overwrote newer unrelated preferences.'
    [IO.File]::WriteAllText($settingsPath,'{incomplete')
    Assert-Launcher (@(Get-AppLauncherKeybinding $settingsPath).Count -eq 0) 'A broken external config broke shortcut help.'
    Write-Host 'PASS: launcher WhatIf, unrelated preferences, original backup, shortcut help, property-only restore.'
} finally {
    $resolvedTestPath = [IO.Path]::GetFullPath($testRoot)
    $expectedTestParent = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\')
    if ((Split-Path -Parent $resolvedTestPath) -ne $expectedTestParent -or (Split-Path -Leaf $resolvedTestPath) -notlike 'omarchy-launcher-test-*') {
        throw 'Refusing cleanup outside the launcher test directory.'
    }
    if (Test-Path -LiteralPath $resolvedTestPath) { Remove-Item -LiteralPath $resolvedTestPath -Recurse -Force }
}
