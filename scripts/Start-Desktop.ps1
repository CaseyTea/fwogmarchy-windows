#Requires -Version 5.1
[CmdletBinding()]
param([string]$StateDirectory)
. "$PSScriptRoot\Common.ps1"
Assert-Windows
if (!$StateDirectory) { $StateDirectory = Get-DesktopStateRoot }
[IO.Directory]::CreateDirectory($StateDirectory) | Out-Null
$logPath = Join-Path $StateDirectory 'startup.log'
function Write-StartupLog([string]$Message) {
    [IO.File]::AppendAllText($logPath,((Get-Date -Format o)+' '+$Message+[Environment]::NewLine),[Text.UTF8Encoding]::new($false))
}
function Wait-StartupProcess([string]$Name,[int]$Seconds = 15) {
    $deadline = [DateTime]::UtcNow.AddSeconds($Seconds)
    do {
        if (Get-Process -Name $Name -ErrorAction SilentlyContinue) { return $true }
        Start-Sleep -Milliseconds 500
    } while ([DateTime]::UtcNow -lt $deadline)
    return $false
}
$mutex = [Threading.Mutex]::new($false,'Local\OmarchyWindows.StartDesktop')
$acquired = $false
$failures = @()
try {
    $acquired = $mutex.WaitOne(0)
    if (!$acquired) { Write-StartupLog 'Another desktop startup is already running.'; return }
    Write-StartupLog 'Starting desktop.'
    Refresh-ExecutablePath
    $wm = Find-DesktopExecutable 'glazewm.exe'
    $bar = Find-DesktopExecutable 'zebar.exe'
    foreach ($path in @($wm,$bar,(Find-DesktopExecutable 'wezterm-gui.exe'))) {
        if ($path) { $env:Path += ';'+(Split-Path -Parent $path) }
    }
    try {
        if (!$wm) { throw 'GlazeWM is not installed or could not be found.' }
        if (!(Get-Process -Name glazewm -ErrorAction SilentlyContinue)) {
            $config = Join-Path $env:USERPROFILE '.glzr\glazewm\config.yaml'
            Start-Process -FilePath $wm -WindowStyle Hidden -ArgumentList @('start','--config',('"'+$config+'"'))
            Write-StartupLog 'Requested GlazeWM launch.'
        }
        # The CLI starts the UIAccess app asynchronously. Wait for its IPC listener
        # before letting the sign-in launcher exit or requesting the bar.
        $ready = $false
        $deadline = [DateTime]::UtcNow.AddSeconds(20)
        do {
            $client = [Net.WebSockets.ClientWebSocket]::new()
            $timeout = [Threading.CancellationTokenSource]::new(800)
            try {
                $client.ConnectAsync([uri]'ws://127.0.0.1:6123',$timeout.Token).GetAwaiter().GetResult()
                if ($client.State -eq [Net.WebSockets.WebSocketState]::Open) {
                    $client.CloseOutputAsync([Net.WebSockets.WebSocketCloseStatus]::NormalClosure,'Startup check',$timeout.Token).GetAwaiter().GetResult()
                    $ready=$true; break
                }
            } catch { } finally { $client.Dispose(); $timeout.Dispose() }
            Start-Sleep -Milliseconds 500
        } while ([DateTime]::UtcNow -lt $deadline)
        if (!$ready) { throw 'GlazeWM did not become ready within 20 seconds. Check its errors.log.' }
        Write-StartupLog 'GlazeWM IPC is ready.'
    } catch { $failures += 'GlazeWM'; Write-StartupLog ('ERROR GlazeWM: '+$_.Exception.Message) }
    try {
        if (!$bar) { throw 'Zebar is not installed or could not be found.' }
        # Zebar treats an already-open preset as a no-op. This also repairs a
        # missing bar when the window manager is already running.
        Start-Process -FilePath $bar -WindowStyle Hidden -ArgumentList @('start-widget-preset','--pack','omarchy-windows','--widget-name','bar','--preset','top')
        if (!(Wait-StartupProcess 'zebar')) { throw 'Zebar did not start within 15 seconds.' }
        Write-StartupLog 'Zebar is running; Fwog Pond preset requested.'
    } catch { $failures += 'Zebar'; Write-StartupLog ('ERROR Zebar: '+$_.Exception.Message) }
    try {
        $launcherStartup = Join-Path $StateDirectory 'app-launcher-startup.json'
        if ((Test-Path -LiteralPath $launcherStartup) -and (Get-Content -LiteralPath $launcherStartup -Raw | ConvertFrom-Json).enabled) {
            $powerToys = Find-DesktopExecutable 'PowerToys.exe'
            if (!$powerToys) { throw 'PowerToys was not found. Repair it to restore the app launcher.' }
            if (!(Get-Process -Name PowerToys -ErrorAction SilentlyContinue)) {
                Start-Process -FilePath $powerToys -WindowStyle Hidden -ArgumentList @('--dont-elevate')
                Write-StartupLog 'Requested PowerToys launch at normal user privileges.'
            }
            if (!(Wait-StartupProcess 'Microsoft.CmdPal.UI' 30)) { throw 'Command Palette did not start. Confirm it is enabled in PowerToys.' }
            Write-StartupLog 'Command Palette is running.'
        } else { Write-StartupLog 'App launcher startup is not configured.' }
    } catch { $failures += 'Command Palette'; Write-StartupLog ('ERROR Command Palette: '+$_.Exception.Message) }
    if ($failures.Count) { throw ('Desktop startup incomplete: '+($failures -join ', ')+'. See '+$logPath) }
    Write-StartupLog 'Desktop startup completed.'
} catch {
    Write-StartupLog ('ERROR '+$_.Exception.Message)
    throw
} finally {
    if ($acquired) { $mutex.ReleaseMutex() }
    $mutex.Dispose()
}
