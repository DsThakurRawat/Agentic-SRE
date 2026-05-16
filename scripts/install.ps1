# Agentic SRE Bootstrap Installer for Windows (PowerShell)
# Usage: irm https://raw.githubusercontent.com/DsThakurRawat/Agentic-SRE/main/scripts/install.ps1 | iex

$ErrorActionPreference = "Stop"

function Step($msg) {
    Write-Host "`n[ ] $msg" -ForegroundColor Cyan
}

function Success($msg) {
    Write-Host "✓ $msg" -ForegroundColor Green
}

function Fail($msg) {
    Write-Host "✗ $msg" -ForegroundColor Red
    exit 1
}

Write-Host "`nAgentic SRE Installer" -ForegroundColor Cyan -Style Bold
Write-Host "The flagship orchestration engine for Autonomous SRE."

# -- [1/3] Checking environment -----------------------------------------------
Step "[1/3] Checking environment..."

$python = $null
foreach ($cmd in @("python3.13", "python", "py")) {
    $path = Get-Command $cmd -ErrorAction SilentlyContinue
    if ($path) {
        $ver = & $cmd --version 2>&1
        if ($ver -match "3\.13") {
            $python = $cmd
            Success "Found Python $ver"
            break
        }
    }
}

if (-not $python) {
    Fail "Python 3.13 is required. Please install it from python.org or via 'winget install Python.Python.3.13'"
}

# -- [2/3] Ensuring pipx ------------------------------------------------------
if (-not (Get-Command pipx -ErrorAction SilentlyContinue)) {
    Step "Installing pipx..."
    & $python -m pip install --user pipx
    & $python -m pipx ensurepath
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "User") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "Machine")
}

# -- [3/3] Installing Agentic SRE ---------------------------------------------
Step "[3/3] Installing Agentic SRE..."
# Default to main branch for now
$target = "git+https://github.com/DsThakurRawat/Agentic-SRE.git"

if (& pipx install $target --python $python --force) {
    Success "Agentic SRE successfully installed!"
    Write-Host "`nNext steps:"
    Write-Host "  1. Run 'agentic-sre' to start the configuration wizard."
    Write-Host "  2. Visit https://github.com/DsThakurRawat/Agentic-SRE for more info.`n"
} else {
    Fail "Installation failed. Please check your network and Python setup."
}
