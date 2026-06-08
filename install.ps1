param(
  [string]$PrivateRepo = "hhh-dahah/qingqi",
  [string]$Branch = "dev",
  [string]$BootstrapPath = "scripts/claude-code-bootstrap.ps1"
)

$ErrorActionPreference = "Stop"

function Write-Step {
  param([string]$Message)
  Write-Host ""
  Write-Host "==> $Message" -ForegroundColor Cyan
}

function Write-WarnLine {
  param([string]$Message)
  Write-Host "WARN $Message" -ForegroundColor Yellow
}

function Test-Command {
  param([string]$Name)
  return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

function Update-PathFromRegistry {
  $machine = [Environment]::GetEnvironmentVariable("Path", "Machine")
  $user = [Environment]::GetEnvironmentVariable("Path", "User")
  $env:Path = "$machine;$user;$env:Path"

  $ghPath = "C:\Program Files\GitHub CLI"
  if (Test-Path -LiteralPath $ghPath -PathType Container) {
    $env:Path = "$env:Path;$ghPath"
  }

  $npmGlobal = Join-Path $env:APPDATA "npm"
  if (Test-Path -LiteralPath $npmGlobal -PathType Container) {
    $env:Path = "$env:Path;$npmGlobal"
  }

  $desktopName = -join ([char]0x684C, [char]0x9762)
  $dNpmGlobal = Join-Path (Join-Path "D:\" $desktopName) "nodejs\npm_global"
  if (Test-Path -LiteralPath $dNpmGlobal -PathType Container) {
    $env:Path = "$env:Path;$dNpmGlobal"
  }
}

Write-Host "Qingqi public Claude Code bootstrap launcher" -ForegroundColor Cyan
Write-Host "This public launcher does not contain secrets. It signs in to GitHub, then fetches the private qingqi bootstrap script."
Write-Host "You can run it from any folder or drive. It does not need the qingqi repo to exist first."

Update-PathFromRegistry

Write-Step "Check GitHub CLI"
if (-not (Test-Command "gh")) {
  if (-not (Test-Command "winget")) {
    throw "GitHub CLI is missing and winget is not available. Please install GitHub CLI from https://cli.github.com/ and rerun this command."
  }
  winget install --id GitHub.cli -e --accept-package-agreements --accept-source-agreements
  Update-PathFromRegistry
}

if (-not (Test-Command "gh")) {
  throw "GitHub CLI was installed but current PowerShell cannot find it. Close PowerShell, open it again, then rerun this command."
}

Write-Step "GitHub sign-in for private qingqi repo"
gh auth status -h github.com *> $null
if ($LASTEXITCODE -ne 0) {
  Write-Host "A browser window will open. Sign in with a GitHub account that has access to $PrivateRepo."
  gh auth login -h github.com -p https -w
}

Write-Step "Fetch private qingqi bootstrap script"
$content = gh api "repos/$PrivateRepo/contents/$BootstrapPath`?ref=$Branch" --jq .content
if ([string]::IsNullOrWhiteSpace($content)) {
  throw "Cannot fetch $BootstrapPath from $PrivateRepo@$Branch. Check GitHub access permission."
}

$script = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String(($content -replace '\s','')))
if ($script -notmatch "Qingqi Claude Code one-command bootstrap") {
  Write-WarnLine "Fetched script does not contain the expected banner. Continuing, but verify the private repo path if this looks wrong."
}

Write-Step "Run private bootstrap script"
$block = [ScriptBlock]::Create($script)
& $block