#Requires -Version 5.1
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$root = Split-Path -Parent $PSScriptRoot
Get-ChildItem -LiteralPath $root -Recurse -Filter '*.ps1' | ForEach-Object {
    $tokens = $null; $parseErrors = $null
    [Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$tokens, [ref]$parseErrors) | Out-Null
    if ($parseErrors.Count) { throw ($parseErrors | Out-String) }
}
function Assert([bool]$Condition, [string]$Message) { if (!$Condition) { throw $Message } }
& "$PSScriptRoot\Keybindings.ps1"
& "$PSScriptRoot\AppLauncher.ps1"
& "$PSScriptRoot\Startup.ps1"
# No packages, registry, startup entries, app launches, or real profile files are touched.
$temp = Join-Path ([IO.Path]::GetTempPath()) ('omarchy-test-'+[guid]::NewGuid())
$originalOS = $env:OS
try {
    $env:OS = 'Windows_NT'
    $profilePath = Join-Path $temp 'profile'
    [IO.Directory]::CreateDirectory($profilePath) | Out-Null
    $terminal = Join-Path $profilePath '.wezterm.lua'
    $original = [byte[]]@(239,187,191,45,45,32,111,114,105,103,105,110,97,108,13,10)
    [IO.File]::WriteAllBytes($terminal,$original)
    & "$root\Install.ps1" -SandboxRoot $temp
    $statePath = Join-Path $temp 'state\state.json'
    $first = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
    $terminalEntry = $first.files | Where-Object { $_.path -eq $terminal }
    Assert ($null -ne $terminalEntry) 'Existing terminal config was not tracked.'
    Assert $terminalEntry.existed 'Existing terminal config was not backed up.'
    Assert ((Get-Content -LiteralPath $terminal -Raw) -match '#172823') 'Theme was not applied.'
    Get-ChildItem -LiteralPath $profilePath -Recurse -File | ForEach-Object {
        Assert (!((Get-Content -LiteralPath $_.FullName -Raw) -match '\{\{\w+\}\}')) "Unresolved token: $($_.FullName)"
    }
    & "$root\Install.ps1" -SandboxRoot $temp
    $second = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
    Assert ($first.files.Count -eq $second.files.Count) 'Rerun duplicated backup entries.'
    Assert (($second.files | Where-Object { $_.path -eq $terminal }).backup -eq $terminalEntry.backup) 'Rerun changed original backup.'
    & "$root\scripts\Restore.ps1" -StateDirectory (Join-Path $temp 'state') -WhatIf
    Assert ((Get-Content -LiteralPath $terminal -Raw) -match '#172823') 'WhatIf modified files.'
    & "$root\scripts\Restore.ps1" -StateDirectory (Join-Path $temp 'state') -Confirm:$false
    Assert ([Convert]::ToBase64String([IO.File]::ReadAllBytes($terminal)) -eq [Convert]::ToBase64String($original)) 'Restore changed original file bytes.'
    Assert (!(Test-Path -LiteralPath (Join-Path $profilePath '.glzr\glazewm\config.yaml'))) 'Restore left a newly created config.'
    Assert (!(Test-Path -LiteralPath (Join-Path $temp 'state\Show-Keybindings.ps1'))) 'Restore left the installed shortcut menu.'
    # Applying after restore must remain possible and retain the original baseline.
    & "$root\Install.ps1" -SandboxRoot $temp
    & "$root\scripts\Restore.ps1" -StateDirectory (Join-Path $temp 'state') -Confirm:$false
    Assert ([Convert]::ToBase64String([IO.File]::ReadAllBytes($terminal)) -eq [Convert]::ToBase64String($original)) 'Reapply/restore lost original.'
    Write-Host 'PASS: parsing, theme rendering, first install, safe rerun, WhatIf, restore, reapply.'
} finally {
    $env:OS = $originalOS
    $resolvedTestPath = [IO.Path]::GetFullPath($temp)
    $expectedTestParent = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\')
    if ((Split-Path -Parent $resolvedTestPath) -ne $expectedTestParent -or (Split-Path -Leaf $resolvedTestPath) -notlike 'omarchy-test-*') {
        throw 'Refusing cleanup outside the installer test directory.'
    }
    if (Test-Path -LiteralPath $resolvedTestPath) { Remove-Item -LiteralPath $resolvedTestPath -Recurse -Force }
}
