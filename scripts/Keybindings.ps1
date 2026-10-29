# Read the inline or block string lists used by this project's GlazeWM config.
# YAML values are never evaluated as PowerShell expressions.
function ConvertFrom-ShortcutList([string]$Value) {
    if ($Value -notmatch '^\s*\[(?<items>.*)\]\s*(?:#.*)?$') { throw 'Expected a list of shortcut strings.' }
    $items = $Matches.items
    $position = 0
    $values = [Collections.Generic.List[string]]::new()
    $pattern = '\G\s*(?:"(?<quoted>(?:\\.|[^"\\])*)"|''(?<single>(?:''''|[^''])*)''|(?<bare>[^,\[\]#]+?))\s*(?:,|$)'
    $matcher = [regex]::new($pattern, [Text.RegularExpressions.RegexOptions]::None, [timespan]::FromSeconds(1))
    while ($position -lt $items.Length -and $items.Substring($position).Trim()) {
        $item = $matcher.Match($items, $position)
        if (!$item.Success -or $item.Length -eq 0) { throw 'Could not read a shortcut list.' }
        if ($item.Groups['quoted'].Success) {
            $values.Add([string](ConvertFrom-Json ('"' + $item.Groups['quoted'].Value + '"')))
        } elseif ($item.Groups['single'].Success) {
            $values.Add($item.Groups['single'].Value.Replace("''", "'"))
        } else { $values.Add($item.Groups['bare'].Value.Trim()) }
        $position = $item.Index + $item.Length
    }
    return $values.ToArray()
}

function Format-DesktopShortcut([string]$Binding) {
    $names = @{
        lwin='Win'; rwin='Win'; win='Win'; alt='Alt'; lalt='Alt'; ralt='Alt'
        shift='Shift'; lshift='Shift'; rshift='Shift'; control='Ctrl'; lctrl='Ctrl'; rctrl='Ctrl'
        oem_minus='-'; oem_plus='='; oem_tilde='`'; print_screen='Print Screen'
        left='Left'; right='Right'; up='Up'; down='Down'; enter='Enter'; escape='Esc'; space='Space'; tab='Tab'
    }
    $parts = foreach ($key in ($Binding -split '\+')) {
        $key = $key.Trim().ToLowerInvariant()
        if ($names.ContainsKey($key)) { $names[$key] } else { $key.ToUpperInvariant() }
    }
    return ($parts -join '+')
}

function New-DesktopShortcut($Entry, [int]$Order) {
    if (!$Entry.commands.Count -or !$Entry.bindings.Count) { throw 'A shortcut is missing commands or bindings.' }
    $command = $Entry.commands[0]
    $category = 'Other'
    $action = $Entry.commands -join '; '
    switch -Regex ($command) {
        '^focus --direction (left|right|up|down)$' { $category='Windows'; $action='Focus window ' + $Matches[1]; break }
        '^move --direction (left|right|up|down)$' { $category='Windows'; $action='Move window ' + $Matches[1]; break }
        '^focus --workspace (.+)$' { $category='Workspaces'; $action='Switch to workspace ' + $Matches[1]; break }
        '^move --workspace (.+)$' {
            $category='Workspaces'; $action='Move window to workspace ' + $Matches[1]
            if (@($Entry.commands | Where-Object { $_ -match '^focus --workspace ' }).Count) { $action += ' and follow' }
            break
        }
        '^focus --recent-workspace$' { $category='Workspaces'; $action='Return to previous workspace'; break }
        '^close$' { $category='Windows'; $action='Close focused window'; break }
        '^toggle-floating' { $category='Windows'; $action='Toggle centered floating window'; break }
        '^toggle-fullscreen$' { $category='Windows'; $action='Toggle fullscreen'; break }
        '^toggle-tiling-direction$' { $category='Windows'; $action='Switch horizontal / vertical split'; break }
        '^resize --(width|height) ([+-])' {
            $category='Windows'; $dimension=$Matches[1]; $verb=if ($Matches[2] -eq '+') { 'Increase' } else { 'Decrease' }
            $action="$verb window $dimension"; break
        }
        '^wm-toggle-pause$' { $category='Desktop'; $action='Pause / resume tiling and shortcuts'; break }
        '^wm-exit$' { $category='Desktop'; $action='Exit window manager'; break }
        '^wm-reload-config$' { $category='Desktop'; $action='Reload desktop configuration'; break }
        '^shell-exec .*Show-Keybindings\.ps1' { $category='Desktop'; $action='Open shortcut menu'; break }
        '^shell-exec wezterm-gui\.exe$' { $category='Apps'; $action='Open terminal'; break }
        '^shell-exec explorer\.exe https://www\.google\.com$' { $category='Apps'; $action='Open default browser'; break }
        '^shell-exec explorer\.exe https://chatgpt\.com$' { $category='Apps'; $action='Open ChatGPT in browser'; break }
        '^shell-exec explorer\.exe$' { $category='Apps'; $action='Open File Explorer'; break }
        '^shell-exec ms-screenclip:$' { $category='Apps'; $action='Capture a screen region'; break }
    }
    return [pscustomobject]@{
        Order=$Order
        Category=$category
        Action=$action
        Shortcuts=(@($Entry.bindings | ForEach-Object { Format-DesktopShortcut $_ }) -join '  /  ')
        Commands=($Entry.commands -join '; ')
    }
}

function Get-DesktopKeybindings([string]$Path) {
    $inside = $false
    $entry = $null
    $field = $null
    $entries = [Collections.Generic.List[object]]::new()
    foreach ($line in (Get-Content -LiteralPath $Path)) {
        if ($line -match '^keybindings:\s*(?:#.*)?$') { $inside=$true; continue }
        if (!$inside -or $line -match '^\s*(#.*)?$') { continue }
        if ($line -match '^\S') { break }
        if ($line -match '^\s+-\s+(?<field>commands|bindings):\s*(?<value>.*)$') {
            if ($null -ne $entry) { $entries.Add((New-DesktopShortcut $entry $entries.Count)) }
            $entry = @{ commands=@(); bindings=@() }
        } elseif ($line -match '^\s+(?<field>commands|bindings):\s*(?<value>.*)$') {
            if ($null -eq $entry) { throw 'A shortcut property has no parent entry.' }
        } elseif ($field -and $line -match '^\s+-\s+(?<value>.+)$') {
            $entry[$field] += @(ConvertFrom-ShortcutList ('[' + $Matches.value + ']'))
            continue
        } else { throw "Unsupported keybinding syntax: $($line.Trim())" }
        $field = $Matches.field
        $value = $Matches.value
        if ($value -and $value -notmatch '^#') { $entry[$field] = @(ConvertFrom-ShortcutList $value); $field=$null }
    }
    if ($null -ne $entry) { $entries.Add((New-DesktopShortcut $entry $entries.Count)) }
    if (!$entries.Count) { throw 'No shortcuts were found in the active configuration.' }
    return $entries.ToArray() | Sort-Object Category,Order
}

function Find-DesktopKeybindings($Entries, [string]$Query) {
    $terms = @($Query.Trim() -split '\s+' | Where-Object { $_ })
    foreach ($entry in $Entries) {
        $text = $entry.Category + ' ' + $entry.Action + ' ' + $entry.Shortcuts
        $matchesAll = $true
        foreach ($term in $terms) {
            if ($text.IndexOf($term, [StringComparison]::OrdinalIgnoreCase) -lt 0) { $matchesAll=$false; break }
        }
        if ($matchesAll) { $entry }
    }
}
