$GitName = "J.J. Smiley"
$GitEmail = "jj@grandmasterj.com"
$LogFile = "$PSScriptRoot\install-dev-machine.log"

# install-dev-machine.ps1

# This script is designed to set up a development machine with essential tools and configurations.
# It installs Chocolatey, various applications, and configures system settings.
# It also sets up Windows Subsystem for Linux (WSL) and Ubuntu, and customizes the appearance of Windows.

# Some of the commands below only run if we're using boxstarter. If running from a normal PowerShell session,
# we need to ensure that Boxstarter is installed and available.

# If we're running from the Boxstarter "install direct from the web" we do not need to install Boxstarter.

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "$timestamp $Message"
    Add-Content -Path $LogFile -Value $entry
}

# Check if running as Administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Please run this script as Administrator."
    exit 1
}

# Install Chocolatey Packages
$packages = @(
    "git", "vscode", "firefox", "powertoys",
    "oh-my-posh", "1password", "powershell-core"
)

# Improved Chocolatey Package Check
foreach ($pkg in $packages) {
    try {
        Write-Log "Processing package: $pkg"
        # Use --exact for accurate matching
        if (choco list --local-only --exact $pkg | Select-String -Pattern "^$pkg ") {
            Write-Log "Upgrading $pkg..."
            choco upgrade $pkg -y --no-progress
        } else {
            Write-Log "Installing $pkg..."
            choco install $pkg -y --no-progress
        }
    } catch {
        Write-Warning "Failed to process ${pkg}: $($_.Exception.Message)"
        Write-Log "ERROR: Failed to process ${pkg}: $($_.Exception.Message)"
        Write-Log "DETAILS: Failed to process ${pkg}: $($_ | Out-String)"
    }
}

# Function: Tests to see if we're running in a VM.
function Test-IsVM {
    try {
        $manufacturer = (Get-WmiObject Win32_ComputerSystem).Manufacturer
        $model = (Get-WmiObject Win32_ComputerSystem).Model
        if ($manufacturer -match "VMware|Microsoft|Xen|VirtualBox|Parallels" -or $model -match "Virtual|VMware|VirtualBox|Parallels") {
            return $true
        }
        # Boxstarter sets this variable if running in a VM
        if ($env:BOXSTARTER_VM -eq "true") {
            return $true
        }
        return $false
    } catch {
        return $false
    }
}

# Here we check if we're running in a VM. If we are, we skip the WSL2 and Ubuntu installation.
if (-not (Test-IsVM)) {
    try {
        Write-Log "Not running on a VM. Installing WSL2 and Ubuntu."
        # Install WSL2
        wsl --install --no-distribution
        Write-Log "WSL2 installed successfully."
        # Install Ubuntu
        wsl --install -d Canonical.Ubuntu.2404
        wsl --set-default-version 2
        wsl --set-default Ubuntu
        Write-Log "WSL2 and Ubuntu installed and configured."
    } catch {
        Write-Warning "Failed to install WSL2/Ubuntu: $($_.Exception.Message)"
        Write-Log "ERROR: Failed to install WSL2/Ubuntu: $($_.Exception.Message)"
        Write-Log "DETAILS: Failed to install WSL2/Ubuntu: $($_ | Out-String)"
        exit 1
    }
} else {
    Write-Log "Running on a VM. Skipping WSL2 and Ubuntu installation."
}

try {
    # Enable .NET Framework 3.5 (some dev tools require it)
    Enable-WindowsOptionalFeature -Online -FeatureName NetFx3 -All -NoRestart
    Write-Log ".NET Framework 3.5 enabled."
}
catch {
    Write-Warning "Failed to enable .NET Framework 3.5: $($_.Exception.Message)"
    Write-Log "ERROR: Failed to enable .NET Framework 3.5: $($_.Exception.Message)"
    Write-Log "DETAILS: Failed to enable .NET Framework 3.5: $($_ | Out-String)"
}

# Pin Applications to Taskbar if Boxstarter is available.
try {
    if ($env:Boxstarter -eq "true") {
        Pin-App "Visual Studio Code"
        Pin-App "Windows Terminal"
        Pin-App "Microsoft Outlook"
        Pin-App "Microsoft Teams"
        Write-Log "Pinned apps to taskbar using Boxstarter."
    }
}
catch {
    Write-Warning "Failed to pin applications: $($_.Exception.Message)"
    Write-Log "ERROR: Failed to pin applications: $($_.Exception.Message)"
    Write-Log "DETAILS: Failed to pin applications: $($_ | Out-String)"
}

# Set Windows Appearance to Dark Mode
try {
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" `
        -Name "AppsUseLightTheme" -Value 0 -Force
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" `
        -Name "SystemUsesLightTheme" -Value 0 -Force
    Write-Log "Set Windows appearance to dark mode."
}
catch {
    Write-Warning "Failed to set Windows appearance to dark mode: $($_.Exception.Message)"
    Write-Log "ERROR: Failed to set Windows appearance to dark mode: $($_.Exception.Message)"
    Write-Log "DETAILS: Failed to set Windows appearance to dark mode: $($_ | Out-String)"
}

# Set Git Global Config (ensure git is in PATH)
try {
    $gitPath = (Get-Command git.exe -ErrorAction Stop).Source
    & "$gitPath" config --global user.name "$GitName"
    & "$gitPath" config --global user.email "$GitEmail"
    Write-Log "Configured global Git user.name and user.email."
}
catch {
    Write-Warning "Failed to configure Git: $($_.Exception.Message)"
    Write-Log "ERROR: Failed to configure Git: $($_.Exception.Message)"
    Write-Log "DETAILS: Failed to configure Git: $($_ | Out-String)"
}

# Install custom PowerShell profile from network share if available
$unasShare = "\\unas.wabash\Personal-Drive"
$unasProfile = "$unasShare\Development\GitHub\windows-setup\profile\profile.ps1"
# $driveLetter = "Z:"   # Currently, this variable is not used.

function Test-HostOnline {
    param([string]$HostName)
    try {
        $ping = Test-Connection -ComputerName $HostName -Count 1 -Quiet -ErrorAction Stop
        return $ping
    } catch {
        return $false
    }
}

try {
    $profilePath = $PROFILE.CurrentUserCurrentHost
    $profileDir = Split-Path -Path $profilePath
    # Ensure the profile directory exists
    if (-not (Test-Path $profileDir)) {
        New-Item -Path $profileDir -ItemType Directory -Force | Out-Null
        Write-Log "Created profile directory: $profileDir"
    }
    # Back up existing profile if it exists
    if (Test-Path $profilePath) {
        Copy-Item -Path $profilePath -Destination "$profilePath.bak" -Force
        Write-Log "Backed up existing profile to $profilePath.bak"
    }
    # Copy the profile from the network share
    if (Test-Path $unasProfile) {
        Copy-Item -Path $unasProfile -Destination $profilePath -Force
        Write-Log "Copied profile from $unasProfile to $profilePath"
        Write-Host "Custom profile installed to $profilePath"
        Write-Host "`n--- Profile Content ---"
        Get-Content $profilePath | Write-Host
        Write-Host "`n--- End Profile Content ---"
    } else {
        Write-Warning "Profile file not found on network share: $unasProfile"
        Write-Log "ERROR: Profile file not found on network share: $unasProfile"
    }
} catch {
    Write-Warning "Failed during profile copy: $($_.Exception.Message)"
    Write-Log "ERROR: Failed during profile copy: $($_.Exception.Message)"
    Write-Log "DETAILS: Failed during profile copy: $($_ | Out-String)"
}

# Determine the real user's profile directory (not the admin's)
$realUser = $env:SUDO_USER
if (-not $realUser) { $realUser = $env:USERNAME }
$realUserProfile = (Get-CimInstance Win32_UserProfile | Where-Object { $_.LocalPath -like "*\$realUser" -and $_.Loaded }).LocalPath

# Profile paths for both Windows PowerShell and PowerShell Core
$pwshDirs = @(
    @{ Dir = Join-Path $realUserProfile "Documents\PowerShell";      Name = "PowerShell Core" },
    @{ Dir = Join-Path $realUserProfile "Documents\WindowsPowerShell"; Name = "Windows PowerShell" }
)
foreach ($pwsh in $pwshDirs) {
    $profileDir = $pwsh.Dir
    $profilePath = Join-Path $profileDir "Microsoft.PowerShell_profile.ps1"
    # Ensure the profile directory exists
    if (-not (Test-Path $profileDir)) {
        New-Item -Path $profileDir -ItemType Directory -Force | Out-Null
        Write-Log "Created profile directory: $profileDir"
    }
    # Back up existing profile if it exists
    if (Test-Path $profilePath) {
        Copy-Item -Path $profilePath -Destination "$profilePath.bak" -Force
        Write-Log "Backed up existing profile to $profilePath.bak"
    }
    # Copy the profile from the network share
    if (Test-Path $unasProfile) {
        Copy-Item -Path $unasProfile -Destination $profilePath -Force
        Write-Log "Copied profile from $unasProfile to $profilePath ($($pwsh.Name))"
        Write-Host "Custom profile installed to $profilePath ($($pwsh.Name))"
        Write-Host "`n--- Profile Content ($($pwsh.Name)) ---"
        Get-Content $profilePath | Write-Host
        Write-Host "`n--- End Profile Content ($($pwsh.Name)) ---"
    } else {
        Write-Warning "Profile file not found on network share: $unasProfile"
        Write-Log "ERROR: Profile file not found on network share: $unasProfile"
    }
}

<#
Please note: I hate the "Gallery" module in the Windows 11
sidebar. When I'm running a dev/test machine, I have absolutely
no use for it. So the block below gets rid of this crap
for me.

Your mileage may vary; use at your own risk.
#>

# Remove "Gallery" from File Explorer Sidebar
try {
    $galleryCLSID = "{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}"
    $galleryRegPath = "HKCU:\Software\Classes\CLSID\$galleryCLSID"

    # Create the key if it doesn't exist
    if (-not (Test-Path $galleryRegPath)) {
        New-Item -Path $galleryRegPath -Force | Out-Null
        Write-Log "Created registry key for Gallery: $galleryRegPath"
    }

    # Set the property to hide it from navigation pane
    New-ItemProperty -Path $galleryRegPath -Name "System.IsPinnedToNameSpaceTree" -Value 0 -PropertyType DWORD -Force | Out-Null

    Write-Log "Successfully removed 'Gallery' from File Explorer sidebar."
} catch {
    Write-Warning "Failed to remove 'Gallery' from File Explorer sidebar: $($_.Exception.Message)"
    Write-Log "ERROR: Failed to remove 'Gallery' from sidebar: $($_.Exception.Message)"
    Write-Log "DETAILS: Failed to remove 'Gallery' from sidebar: $($_ | Out-String)"
}

Write-Host ""
Write-Host "`nSetup complete. You may need to restart your computer to apply all changes." -ForegroundColor Green
exit 0
