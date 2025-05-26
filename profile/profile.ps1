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
    $themeDir = Join-Path (Split-Path (Split-Path $ompPath)) 'themes'
    $themeFile = Join-Path $themeDir 'kali.omp.json'
    oh-my-posh init pwsh --config $themeFile | Invoke-Expression
} catch {
    Write-Warning 'Failed to initialize oh-my-posh prompt.'
}

# Try to get the display name from AD, fallback to username
function Get-FirstName {
    try {
        if ($env:USERNAME.ToLower() -in @("jjsmiley", "jsmiley", "jsmil")) {
    return "JJ"
    } else {
        return ($env:USERNAME -split '[\._]')[0]
    }
} catch {
        Write-Warning 'Failed to retrieve first name.'
        return 'Kiddo'
    }
}

# Function: Get-OSName
function Get-OSName {
    (Get-CimInstance Win32_OperatingSystem).Caption -replace '^Microsoft\s*', ''
}

# Function: Get PowerShell version
# Function: Get PowerShell version
function Get-PowerShellVersion {
    $psVersion = $PSVersionTable.PSVersion
    "PowerShell: $($psVersion.ToString())"
}

# Function: Get-Weather
function Get-Weather {
    try {
        (Invoke-RestMethod -Uri 'https://wttr.in/?format=1').Trim()
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

# Function: Get-LocalIP
function Get-LocalIP {
    try {
        $ip = Get-NetIPAddress -AddressFamily IPv4 `
            | Where-Object { $_.IPAddress -notlike '169.254*' -and $_.IPAddress -ne '127.0.0.1' -and $_.PrefixOrigin -ne 'WellKnown' } `
            | Where-Object { $_.InterfaceAlias -notmatch 'vEthernet|Loopback|Virtual' } `
            | Sort-Object -Property InterfaceIndex `
            | Select-Object -First 1 -ExpandProperty IPAddress
        if ($ip) {
            "IP: $ip"
        } else {
            "IP: Not found"
        }
    } catch {
        "IP: Unable to retrieve"
    }
}
Set-Alias whatsmylocalip Get-LocalIP

# Function: Start-Over
function Start-Over {
    Clear-Host
    . $PROFILE.CurrentUserAllHosts
    Write-Host 'Profile reloaded.' -ForegroundColor Green
}
Set-Alias startover Start-Over

# Display greeting banner
Clear-Host
Write-Host "=========================================" -ForegroundColor Green
Write-Host " Welcome back, $(Get-FirstName)!" -ForegroundColor Cyan
Write-Host " System: $(Get-OSName)" -ForegroundColor Cyan
Write-Host " Shell: $($PSVersionTable.PSEdition) $($PSVersionTable.PSVersion) | $(Get-LocalIP)" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Green
Write-Host "Current Weather: $(Get-Weather)" -ForegroundColor Cyan
Write-Host ""