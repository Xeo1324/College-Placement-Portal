<#
auto-push-on-save.ps1

Watches the repository for file saves and automatically stages, commits,
and pushes changes to the configured remote/branch.

Usage:
  powershell -NoProfile -ExecutionPolicy Bypass -File .\auto-push-on-save.ps1

Options (edit variables below or pass as named params):
  -RepoPath : path to repository (default: script folder)
  -Remote   : git remote name (default: origin)
  -Branch   : branch to push (default: main)

Notes:
  - Ensure `git` is in PATH and you have push permissions (SSH key or cached credentials).
  - This script commits with message "Auto-save: <timestamp>". Modify if needed.
#>

param(
    [string] $RepoPath = $(Split-Path -Parent $MyInvocation.MyCommand.Definition),
    [string] $Remote = 'origin',
    [string] $Branch = 'main',
    [int] $DebounceMs = 800
)

Set-Location -Path $RepoPath

function Write-Log { param($m) Write-Host "[auto-push] $m" }

if (-not (Test-Path (Join-Path $RepoPath '.git'))) {
    Write-Log "No .git folder detected in $RepoPath. Exiting."; exit 1
}

$filterIgnore = '\.git\\|\\.vs\\|\\node_modules\\|\\.vscode\\|~$|\\.tmp$|\\.swp$'

$changed = [System.Collections.Concurrent.ConcurrentBag[string]]::new()

$timer = New-Object System.Timers.Timer
$timer.Interval = $DebounceMs
$timer.AutoReset = $false
$timer.Add_Elapsed({
    try {
        $files = $changed.ToArray() | Select-Object -Unique
        $changed = [System.Collections.Concurrent.ConcurrentBag[string]]::new()
        Write-Log "Detected changes: $($files -join ', ')"

        # Stage everything (you can change to smarter staging if desired)
        & git add -A

        $time = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        & git commit -m "Auto-save: $time" 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Committed changes. Pushing to $Remote/$Branch..."
            & git push $Remote $Branch
            if ($LASTEXITCODE -eq 0) { Write-Log "Push successful." } else { Write-Log "Push failed (exit $LASTEXITCODE)." }
        }
        else { Write-Log "No changes to commit." }
    } catch {
        Write-Log "Error during commit/push: $_"
    }
}) | Out-Null

$watcher = New-Object System.IO.FileSystemWatcher $RepoPath, '*.*'
$watcher.IncludeSubdirectories = $true
$watcher.NotifyFilter = [IO.NotifyFilters]'FileName, LastWrite'

$onChange = Register-ObjectEvent $watcher Changed -Action {
    $path = $Event.SourceEventArgs.FullPath
    if ($path -match $filterIgnore) { return }
    if ($path -match '\\\.gitignore$') { return }
    $null = $changed.Add($path)
    $timer.Stop()
    $timer.Start()
}

$onCreate = Register-ObjectEvent $watcher Created -Action {
    $path = $Event.SourceEventArgs.FullPath
    if ($path -match $filterIgnore) { return }
    $null = $changed.Add($path)
    $timer.Stop()
    $timer.Start()
}

$onRename = Register-ObjectEvent $watcher Renamed -Action {
    $path = $Event.SourceEventArgs.FullPath
    if ($path -match $filterIgnore) { return }
    $null = $changed.Add($path)
    $timer.Stop()
    $timer.Start()
}

Write-Log "Watching $RepoPath for changes. Press Ctrl+C to stop."
$watcher.EnableRaisingEvents = $true

try {
    while ($true) { Start-Sleep -Seconds 1 }
} finally {
    Unregister-Event -SourceIdentifier $onChange.Name -ErrorAction SilentlyContinue
    Unregister-Event -SourceIdentifier $onCreate.Name -ErrorAction SilentlyContinue
    Unregister-Event -SourceIdentifier $onRename.Name -ErrorAction SilentlyContinue
    $watcher.Dispose()
}
