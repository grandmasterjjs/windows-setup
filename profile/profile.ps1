<#
.SYNOPSIS
    Custom PowerShell profile loaded at startup.

.DESCRIPTION
    Defines functions, aliases, and configures oh-my-posh prompt.
    Displays welcome banner with OS version and current weather.

.EXAMPLE
    To reload profile manually:
    . $PROFILE.CurrentUserAllHosts

.NOTES
    Dependencies: winget, oh-my-posh.

.AUTHOR
    JJ Smiley

.DATE
    Last updated: 2025-05-22

.COMPANY
    GrandMasterJ.com

.CONTACT
    jj@grandmasterj.com

.LINK
    https://github.com/grandmasterjjs/powershell-profile

.TODO
    - Externalize configuration (e.g., weather API endpoint).
#>

# Ensure oh-my-posh is installed
if (-not (Get-Command 'oh-my-posh' -ErrorAction SilentlyContinue)) {
    Write-Host 'Installing oh-my-posh via winget...' -ForegroundColor Yellow
    winget install --id JanDeDobbeleer.OhMyPosh -e --accept-source-agreements --accept-package-agreements
}

# Initialize oh-my-posh prompt
try {
    $ompPath = (Get-Command 'oh-my-posh').Source
    $themeDir = Join-Path (Split-Path $ompPath) 'themes'
    $themeFile = Join-Path $themeDir 'kali.omp.json'
    oh-my-posh init pwsh --config $themeFile | Invoke-Expression
} catch {
    Write-Warning 'Failed to initialize oh-my-posh prompt.'
}

# Function: Get-OSName
function Get-OSName {
    $os = Get-CimInstance Win32_OperatingSystem
    "$($os.Caption) [Version $($os.Version)]"
}

# Function: Get-Weather
function Get-Weather {
    try {
        Invoke-RestMethod -Uri 'https://wttr.in/?format=3'
    } catch {
        'Weather: Unable to retrieve data.'
    }
}

# Function: Get-MyIP
function Get-MyIP {
    try {
        $ip = (Invoke-RestMethod -Uri 'https://api.ipify.org').Trim()
        "Public IP: $ip"
    } catch {
        'Unable to retrieve public IP.'
    }
}
Set-Alias whatsmyip Get-MyIP

# Function: Start-Over
function Start-Over {
    Clear-Host
    . $PROFILE.CurrentUserAllHosts
    Write-Host 'Profile reloaded.' -ForegroundColor Green
}
Set-Alias startover Start-Over

# Display greeting banner
Clear-Host
Write-Host "Welcome, $env:USERNAME!" -ForegroundColor Cyan
Write-Host (Get-OSName) -ForegroundColor Cyan
Write-Host (Get-Weather) -ForegroundColor Cyan
