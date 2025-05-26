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

# Check for Controlled Folder Access

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "$timestamp $Message"
    Add-Content -Path $LogFile -Value $entry
}

try {
    $cfaStatus = Get-MpPreference | Select-Object -ExpandProperty EnableControlledFolderAccess
    if ($cfaStatus -eq 1) {
        Write-Warning "Controlled Folder Access is ENABLED. This may prevent the script from modifying your profile and other folders."
        Write-Host "To avoid errors, you can:"
        Write-Host "  1. Temporarily disable Controlled Folder Access during setup."
        Write-Host "  2. Or, add PowerShell to the list of allowed apps for Controlled Folder Access."
        Write-Host "     Example (run as admin):"
        Write-Host "     Add-MpPreference -ControlledFolderAccessAllowedApplications 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe'"
        Write-Host "     Add-MpPreference -ControlledFolderAccessAllowedApplications 'C:\Program Files\PowerShell\7\pwsh.exe'"
        Write-Log "Controlled Folder Access is enabled. User warned."

        Write-Host ""
        Write-Host "Press any key to exit, or wait 10 seconds to continue..." -NoNewline
        $timeout = 10
        for ($i = 0; $i -lt $timeout; $i++) {
            Start-Sleep -Seconds 1
            Write-Host "." -NoNewline
            if ($Host.UI.RawUI.KeyAvailable) {
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                Write-Host ""
                Write-Host "Exiting script due to Controlled Folder Access."
                exit 1
            }
        }
        Write-Host ""
        Write-Host "Continuing with script execution..."
    }
} catch {
    Write-Log "Could not check Controlled Folder Access status: $($_.Exception.Message)"
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

# Improved Chocolatey Package Check (fix for --local-only deprecation)
foreach ($pkg in $packages) {
    try {
        Write-Log "Processing package: $pkg"
        # Use -l for local, --exact for accurate matching
        if (choco list -l --exact $pkg | Select-String -Pattern "^$pkg ") {
            Write-Log "Upgrading $pkg..."
            choco upgrade $pkg -y --no-progress -r *> $null
        } else {
            Write-Log "Installing $pkg..."
            choco install $pkg -y --no-progress -r *> $null
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
        wsl --install --no-distribution *> $null
        Write-Log "WSL2 installed successfully."
        # Install Ubuntu (use correct distro name)
        wsl --install -d Ubuntu-24.04 *> $null
        wsl --set-default-version 2 *> $null
        wsl --set-default Ubuntu *> $null
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
    Enable-WindowsOptionalFeature -Online -FeatureName NetFx3 -All -NoRestart -ErrorAction Stop | Out-Null
    Write-Log ".NET Framework 3.5 enabled."
}
catch {
    Write-Warning "Failed to enable .NET Framework 3.5: $($_.Exception.Message)"
    Write-Log "ERROR: Failed to enable .NET Framework 3.5: $($_.Exception.Message)"
    Write-Log "DETAILS: Failed to enable .NET Framework 3.5: $($_ | Out-String)"
}

# Pin Applications to Taskbar if Boxstarter is available (silent except on error)
try {
    if ($env:Boxstarter -eq "true") {
        Pin-App "Visual Studio Code" *> $null
        Pin-App "Windows Terminal" *> $null
        Pin-App "Microsoft Outlook" *> $null
        Pin-App "Microsoft Teams" *> $null
        Write-Log "Pinned apps to taskbar using Boxstarter."
    }
}
catch {
    Write-Warning "Failed to pin applications: $($_.Exception.Message)"
    Write-Log "ERROR: Failed to pin applications: $($_.Exception.Message)"
    Write-Log "DETAILS: Failed to pin applications: $($_ | Out-String)"
}

# Set Windows Appearance to Dark Mode (silent except on error)
try {
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" `
        -Name "AppsUseLightTheme" -Value 0 -Force | Out-Null
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" `
        -Name "SystemUsesLightTheme" -Value 0 -Force | Out-Null
    Write-Log "Set Windows appearance to dark mode."
}
catch {
    Write-Warning "Failed to set Windows appearance to dark mode: $($_.Exception.Message)"
    Write-Log "ERROR: Failed to set Windows appearance to dark mode: $($_.Exception.Message)"
    Write-Log "DETAILS: Failed to set Windows appearance to dark mode: $($_ | Out-String)"
}

# Set Git Global Config (ensure git is in PATH, silent except on error)
try {
    $gitPath = (Get-Command git.exe -ErrorAction Stop).Source
    & "$gitPath" config --global user.name "$GitName" *> $null
    & "$gitPath" config --global user.email "$GitEmail" *> $null
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

function Test-HostOnline {
    param([string]$HostName)
    try {
        $ping = Test-Connection -ComputerName $HostName -Count 1 -Quiet -ErrorAction Stop
        return $ping
    } catch {
        return $false
    }
}

# Robust Documents path detection (handles OneDrive redirection)
$realUser = $env:SUDO_USER
if (-not $realUser) { $realUser = $env:USERNAME }
$realUserProfile = (Get-CimInstance Win32_UserProfile | Where-Object { $_.LocalPath -like "*\$realUser" -and $_.Loaded }).LocalPath

# Try to get Documents path from registry (handles OneDrive)
$docsPath = (Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "Personal" -ErrorAction SilentlyContinue)."Personal"
if ($docsPath -and $docsPath -notmatch "^%") {
    $docsPath = [Environment]::ExpandEnvironmentVariables($docsPath)
} else {
    $docsPath = Join-Path $realUserProfile "Documents"
}

# Profile paths for both Windows PowerShell and PowerShell Core
$pwshDirs = @(
    @{ Dir = Join-Path $docsPath "PowerShell";      Name = "PowerShell Core" },
    @{ Dir = Join-Path $docsPath "WindowsPowerShell"; Name = "Windows PowerShell" }
)
foreach ($pwsh in $pwshDirs) {
    $profileDir = $pwsh.Dir
    $profilePath = Join-Path $profileDir "Microsoft.PowerShell_profile.ps1"
    if ($profileDir -and $profilePath) {
        if (-not (Test-Path $profileDir)) {
            New-Item -Path $profileDir -ItemType Directory -Force | Out-Null
            Write-Log "Created profile directory: $profileDir"
        }
        if (Test-Path $profilePath) {
            Copy-Item -Path $profilePath -Destination "$profilePath.bak" -Force | Out-Null
            Write-Log "Backed up existing profile to $profilePath.bak"
        }
        if (Test-Path $unasProfile) {
            Copy-Item -Path $unasProfile -Destination $profilePath -Force | Out-Null
            Write-Log "Copied profile from $unasProfile to $profilePath ($($pwsh.Name))"
            Write-Host "Custom profile installed to $profilePath ($($pwsh.Name))"
            Write-Host "`n--- Profile Content ($($pwsh.Name)) ---"
            Get-Content $profilePath | Write-Host
            Write-Host "`n--- End Profile Content ($($pwsh.Name)) ---"
        } else {
            Write-Warning "Profile file not found on network share: $unasProfile"
            Write-Log "ERROR: Profile file not found on network share: $unasProfile"
        }
    } else {
        Write-Warning "Profile directory or path is null for $($pwsh.Name)"
        Write-Log "ERROR: Profile directory or path is null for $($pwsh.Name)"
    }
}

<#
Please note: I hate the "Gallery" module in the Windows 11
sidebar. When I'm running a dev/test machine, I have absolutely
no use for it. So the block below gets rid of this crap
for me.

Your mileage may vary; use at your own risk.
#>

# Remove "Gallery" from File Explorer Sidebar (silent except on error)
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
