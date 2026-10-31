#Requires -Version 5.1
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. "$PSScriptRoot\..\scripts\Common.ps1"
$testRoot = Join-Path ([IO.Path]::GetTempPath()) ('omarchy-startup-test-'+[guid]::NewGuid())
$shell = $null; $shortcut = $null
try {
    $runner = Join-Path $testRoot 'state with spaces\Start-Desktop.ps1'
    Write-Utf8File $runner '# Test fixture only; never launched.'
    $linkPath = Join-Path $testRoot 'Startup\OmarchyWindows.lnk'
    New-DesktopStartupShortcut $linkPath $runner
    # Inspect the saved native shortcut without running an app or touching Startup.
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($linkPath)
    $expectedTarget = Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe'
    if ($shortcut.TargetPath -ne $expectedTarget) { throw 'Startup shortcut does not use the installed Windows PowerShell.' }
    if ($shortcut.Arguments -notlike '*-NoProfile*' -or $shortcut.Arguments -notlike '*-WindowStyle Hidden*' -or !$shortcut.Arguments.EndsWith('-File "'+$runner+'"')) { throw 'Startup shortcut lost hidden startup or its quoted script path.' }
    if ($shortcut.WorkingDirectory -ne (Split-Path -Parent $runner)) { throw 'Startup working directory is not the stable state directory.' }
    if ($shortcut.WindowStyle -ne 7) { throw 'Startup shortcut would steal focus.' }
    Write-Host 'PASS: native login shortcut, stable working directory, hidden launch, quoted paths.'
} finally {
    if ($shortcut) { [Runtime.InteropServices.Marshal]::FinalReleaseComObject($shortcut) | Out-Null }
    if ($shell) { [Runtime.InteropServices.Marshal]::FinalReleaseComObject($shell) | Out-Null }
    $resolvedTestPath = [IO.Path]::GetFullPath($testRoot)
    $expectedTestParent = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\')
    if ((Split-Path -Parent $resolvedTestPath) -ne $expectedTestParent -or (Split-Path -Leaf $resolvedTestPath) -notlike 'omarchy-startup-test-*') { throw 'Refusing cleanup outside the startup test directory.' }
    if (Test-Path -LiteralPath $resolvedTestPath) { Remove-Item -LiteralPath $resolvedTestPath -Recurse -Force }
}
