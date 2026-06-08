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
  Write-Host "提醒  $Message" -ForegroundColor Yellow
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

Write-Host "青契公开安装器" -ForegroundColor Cyan
Write-Host "说明：这个公开安装器不包含密钥。它会先登录 GitHub，再从私有青契仓库读取真正的安装脚本。"
Write-Host "可以在任意盘、任意文件夹运行；不需要先创建或进入青契项目目录。"

Update-PathFromRegistry

Write-Step "检查 GitHub CLI"
if (-not (Test-Command "gh")) {
  if (-not (Test-Command "winget")) {
    throw "没有找到 GitHub CLI，也没有找到 winget。请先从 https://cli.github.com/ 安装 GitHub CLI，然后重新运行本命令。"
  }
  winget install --id GitHub.cli -e --accept-package-agreements --accept-source-agreements
  Update-PathFromRegistry
}

if (-not (Test-Command "gh")) {
  throw "GitHub CLI 已安装，但当前 PowerShell 还找不到它。请关闭 PowerShell，重新打开后再运行本命令。"
}

Write-Step "登录 GitHub，用来访问青契私有仓库"
gh auth status -h github.com *> $null
if ($LASTEXITCODE -ne 0) {
  Write-Host "接下来会打开浏览器。请用有青契仓库权限的 GitHub 账号登录：$PrivateRepo"
  gh auth login -h github.com -p https -w
}

Write-Step "读取私有青契仓库里的安装脚本"
$content = gh api "repos/$PrivateRepo/contents/$BootstrapPath`?ref=$Branch" --jq .content
if ([string]::IsNullOrWhiteSpace($content)) {
  throw "无法从 $PrivateRepo@$Branch 读取 $BootstrapPath。请确认这个 GitHub 账号已经被加入青契私有仓库。"
}

$script = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String(($content -replace '\s','')))
$script = $script.TrimStart([char]0xFEFF)
if ($script -notmatch "青契 Claude Code 一键安装脚本") {
  Write-WarnLine "读取到的脚本没有预期标识。会继续执行；如果后续看起来不对，请检查私有仓库路径。"
}

Write-Step "运行青契真正的一键安装脚本"
$tempScript = Join-Path $env:TEMP "qingqi-claude-code-bootstrap.ps1"
$utf8Bom = New-Object System.Text.UTF8Encoding($true)
[System.IO.File]::WriteAllText($tempScript, $script, $utf8Bom)
& powershell -NoProfile -ExecutionPolicy Bypass -File $tempScript