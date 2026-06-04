param(
    [switch]$User,
    [Alias("Global")]
    [switch]$GlobalInstall,
    [string]$Project
)

$ErrorActionPreference = "Stop"

function Show-Usage {
    @"
Usage:
  .\scripts\install-claude-shy-commands.ps1 -Project X:\path\to\project
  .\scripts\install-claude-shy-commands.ps1 -User

Options:
  -Project DIR  Install Claude Code /shy:* commands into a project
  -User         Install Claude Code /shy:* commands globally for the current user
"@ | Write-Host
}

$userMode = $User -or $GlobalInstall
$projectMode = -not [string]::IsNullOrWhiteSpace($Project)

if ($userMode -and $projectMode) {
    Show-Usage
    throw "Choose only one install target: -Project or -User."
}

if (-not $userMode -and -not $projectMode) {
    Show-Usage
    throw "Choose either -Project <project-dir> or -User."
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoDir = Split-Path -Parent $ScriptDir
$CommandSrc = Join-Path $RepoDir "extras\claude-commands\shy"

if (-not (Test-Path $CommandSrc)) {
    throw "Cannot find Claude command templates at $CommandSrc"
}

if ($projectMode) {
    $ProjectDir = (Resolve-Path -Path $Project).Path
    $Destination = Join-Path $ProjectDir ".claude\commands\shy"
} else {
    $HomeDir = [Environment]::GetFolderPath("UserProfile")
    $Destination = Join-Path $HomeDir ".claude\commands\shy"
}

New-Item -ItemType Directory -Force -Path $Destination | Out-Null
Copy-Item -Path (Join-Path $CommandSrc "*.md") -Destination $Destination -Force

Write-Host "Installed Claude Code Shy commands: $Destination"
Write-Host "Try in Claude Code: /shy:resolve"
