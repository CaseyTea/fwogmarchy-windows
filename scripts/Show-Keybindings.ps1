#Requires -Version 5.1
[CmdletBinding()]
param([string]$ConfigPath = (Join-Path $env:USERPROFILE '.glzr\glazewm\config.yaml'))
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\Keybindings.ps1"
Add-Type -AssemblyName PresentationFramework

# Repeating the shortcut brings the existing menu to the front.
$created = $false
$instance = [Threading.Mutex]::new($true, 'Local\OmarchyWindows.ShortcutMenu', [ref]$created)
if (!$created) {
    try {
        $existingSignal = [Threading.EventWaitHandle]::OpenExisting('Local\OmarchyWindows.ShortcutMenu.Activate')
        try { $existingSignal.Set() | Out-Null } finally { $existingSignal.Dispose() }
    } catch { }
    $instance.Dispose()
    return
}
$activationSignal = [Threading.EventWaitHandle]::new($false, [Threading.EventResetMode]::AutoReset, 'Local\OmarchyWindows.ShortcutMenu.Activate')
$timer = $null
try {
    $shortcuts = @(Get-DesktopKeybindings $ConfigPath)
    $colors = @{ background='#172823'; dark_background='#11201c'; lighter_background='#2b4339'; foreground='#dce8ce'; dark_foreground='#9eb39d'; accent='#b5d96b'; muted='#466257' }
    $themePath = Join-Path $PSScriptRoot 'theme.json'
    if (Test-Path -LiteralPath $themePath) {
        $theme = Get-Content -LiteralPath $themePath -Raw | ConvertFrom-Json
        foreach ($key in @($colors.Keys)) {
            $property = $theme.PSObject.Properties[$key]
            if ($property -and $property.Value -match '^#[0-9a-fA-F]{6}$') { $colors[$key] = $property.Value }
        }
    }
    $markup = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Omarchy Shortcuts" Width="940" Height="680" MinWidth="720" MinHeight="420"
        WindowStartupLocation="CenterScreen" Topmost="True" ResizeMode="CanResizeWithGrip"
        Background="@background@" Foreground="@foreground@" FontFamily="Segoe UI" FontSize="14">
  <Window.Resources>
    <Style TargetType="ListBoxItem">
      <Setter Property="HorizontalContentAlignment" Value="Stretch"/>
      <Setter Property="Padding" Value="14,11"/>
      <Setter Property="Margin" Value="0,0,0,6"/>
      <Setter Property="Background" Value="@dark_background@"/>
      <Setter Property="Foreground" Value="@foreground@"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="ListBoxItem">
            <Border x:Name="Row" Background="{TemplateBinding Background}" CornerRadius="5" Padding="{TemplateBinding Padding}"><ContentPresenter/></Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Row" Property="Background" Value="@lighter_background@"/></Trigger>
              <Trigger Property="IsSelected" Value="True"><Setter TargetName="Row" Property="Background" Value="@lighter_background@"/></Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
  </Window.Resources>
  <Grid Margin="26,22">
    <Grid.RowDefinitions>
      <RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/>
      <RowDefinition Height="*"/><RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>
    <TextBlock Grid.Row="0" Text="OMARCHY WINDOWS" Foreground="@accent@" FontSize="11" FontWeight="SemiBold" Margin="0,0,0,5"/>
    <StackPanel Grid.Row="1" Margin="0,0,0,18">
      <TextBlock Text="Keyboard shortcuts" FontSize="28" FontWeight="SemiBold"/>
      <TextBlock Text="Find an action or key combination. These are your current desktop bindings." TextWrapping="Wrap" Foreground="@dark_foreground@" Margin="0,7,0,0"/>
    </StackPanel>
    <StackPanel Grid.Row="2" Margin="0,0,0,16">
      <TextBlock Text="Search shortcuts" Foreground="@dark_foreground@" FontSize="12" Margin="0,0,0,6"/>
      <TextBox x:Name="Search" AutomationProperties.Name="Search shortcuts" Padding="12,9" FontSize="16"
               Background="@dark_background@" Foreground="@foreground@" CaretBrush="@accent@"
               SelectionBrush="@muted@" BorderBrush="@muted@" BorderThickness="1"/>
    </StackPanel>
    <Grid Grid.Row="3">
      <ListBox x:Name="ShortcutList" AutomationProperties.Name="Keyboard shortcuts" Background="Transparent" BorderThickness="0"
               ScrollViewer.HorizontalScrollBarVisibility="Disabled" ScrollViewer.VerticalScrollBarVisibility="Auto">
        <ListBox.ItemTemplate>
          <DataTemplate>
            <Grid>
              <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
              <StackPanel Grid.Column="0" Margin="0,0,16,0">
                <TextBlock Text="{Binding Action}" TextWrapping="Wrap"/>
                <TextBlock Text="{Binding Category}" Foreground="@dark_foreground@" FontSize="11" Margin="0,4,0,0"/>
              </StackPanel>
              <TextBlock Grid.Column="1" Text="{Binding Shortcuts}" Foreground="@accent@" FontFamily="Cascadia Mono, Consolas" FontSize="13" VerticalAlignment="Center"/>
            </Grid>
          </DataTemplate>
        </ListBox.ItemTemplate>
      </ListBox>
      <TextBlock x:Name="Empty" Text="No matching shortcuts. Try another word or key." Visibility="Collapsed"
                 Foreground="@dark_foreground@" HorizontalAlignment="Center" VerticalAlignment="Center"/>
    </Grid>
    <Grid Grid.Row="4" Margin="0,16,0,0">
      <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
      <StackPanel>
        <TextBlock x:Name="Count" Foreground="@dark_foreground@" FontSize="12"/>
        <TextBlock Text="Esc to close  |  Alt+F1 to open  |  Windows may reserve some Win shortcuts" Foreground="@dark_foreground@" FontSize="11" Margin="0,5,0,0"/>
      </StackPanel>
      <Button x:Name="CloseMenu" Grid.Column="1" Content="Close" Padding="18,7" Background="@lighter_background@" Foreground="@foreground@" BorderBrush="@muted@"/>
    </Grid>
  </Grid>
</Window>
'@
    foreach ($key in $colors.Keys) { $markup = $markup.Replace('@'+$key+'@', $colors[$key]) }
    $reader = [Xml.XmlReader]::Create([IO.StringReader]::new($markup))
    try { $window = [Windows.Markup.XamlReader]::Load($reader) } finally { $reader.Dispose() }
    $search = $window.FindName('Search')
    $list = $window.FindName('ShortcutList')
    $count = $window.FindName('Count')
    $empty = $window.FindName('Empty')
    $list.ItemsSource = $shortcuts
    $count.Text = "$($shortcuts.Count) shortcuts"
    $search.Add_TextChanged({
        $filtered = @(Find-DesktopKeybindings $shortcuts $search.Text)
        $list.ItemsSource = $filtered
        $count.Text = "$($filtered.Count) of $($shortcuts.Count) shortcuts"
        $empty.Visibility = if ($filtered.Count) { [Windows.Visibility]::Collapsed } else { [Windows.Visibility]::Visible }
    })
    $window.FindName('CloseMenu').Add_Click({ $window.Close() })
    $window.Add_PreviewKeyDown({
        param($sender, $eventArgs)
        if ($eventArgs.Key -eq [Windows.Input.Key]::Escape) { $eventArgs.Handled=$true; $window.Close() }
    })
    $window.Add_ContentRendered({ $window.Activate() | Out-Null; $search.Focus() | Out-Null })
    $timer = [Windows.Threading.DispatcherTimer]::new()
    $timer.Interval = [timespan]::FromMilliseconds(250)
    $timer.Add_Tick({
        if ($activationSignal.WaitOne(0)) { $window.Activate() | Out-Null; $search.Focus() | Out-Null }
    })
    $timer.Start()
    $window.ShowDialog() | Out-Null
} catch {
    try { [IO.File]::WriteAllText((Join-Path $PSScriptRoot 'shortcut-menu-error.log'), ($_ | Out-String), [Text.UTF8Encoding]::new($false)) } catch { }
    [Windows.MessageBox]::Show('The shortcut menu could not open. Check the desktop configuration and try again.', 'Omarchy Shortcuts') | Out-Null
} finally {
    if ($timer) { $timer.Stop() }
    $activationSignal.Dispose()
    $instance.ReleaseMutex()
    $instance.Dispose()
}
