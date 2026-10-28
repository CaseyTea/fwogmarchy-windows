#Requires -Version 5.1
[CmdletBinding(SupportsShouldProcess, ConfirmImpact='Medium')]
param([string]$StateDirectory)
. "$PSScriptRoot\Common.ps1"
Assert-Windows
if (!$StateDirectory) { $StateDirectory = Get-DesktopStateRoot }
$statePath = Join-Path $StateDirectory 'state.json'
if (!(Test-Path -LiteralPath $statePath)) { throw "No backup manifest found: $statePath" }
$state = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
if ($state.version -ne 1) { throw 'Unknown backup format.' }
# Require apps to be closed, keeping recovery independent of their CLI versions.
if (Get-Process glazewm,zebar -ErrorAction SilentlyContinue) {
    throw 'Quit GlazeWM and Zebar from their tray icons before restoring.'
}
# Validate all originals before restoring any file.
foreach ($file in $state.files) {
    if ($file.existed -and !(Test-Path -LiteralPath $file.backup -PathType Leaf)) { throw "Missing original backup: $($file.backup)" }
}
$archive = Join-Path $StateDirectory ('before-restore\'+(Get-Date -Format 'yyyyMMdd-HHmmss-fff'))
$index = 0
foreach ($file in $state.files) {
    if ($PSCmdlet.ShouldProcess($file.path, 'Save current file and restore pre-install state')) {
        $index++
        if (Test-Path -LiteralPath $file.path -PathType Leaf) {
            [IO.Directory]::CreateDirectory($archive) | Out-Null
            Copy-Item -LiteralPath $file.path -Destination (Join-Path $archive "$index.bak")
            Add-Content -LiteralPath (Join-Path $archive 'paths.txt') -Value "$index.bak`t$($file.path)"
        }
        if ($file.existed) {
            [IO.Directory]::CreateDirectory((Split-Path -Parent $file.path)) | Out-Null
            Copy-Item -LiteralPath $file.backup -Destination $file.path -Force
        } elseif (Test-Path -LiteralPath $file.path -PathType Leaf) {
            Remove-Item -LiteralPath $file.path -Force
        }
    }
}
# Retain the manifest and original backups for recovery; packages remain installed.
if (!$WhatIfPreference) { Write-Host "Original settings restored. Saved pre-restore files: $archive" }
