# Windows Setup

A Boxstarter-based script for provisioning Windows 10/11 workstations with my preferred configuration, apps, and developer tools.

## Features

- Installs Chocolatey apps: Git, VS Code, Firefox, PowerToys, Windows Terminal, 1Password, AdGuard, Microsoft Teams, Office365, PowerShell Core, WSL/Ubuntu
- Applies system tweaks: dark mode, dev mode, disables sleep
- Configures Git global credentials
- Installs oh-my-posh with kali.omp.json theme
- Sets up PowerShell profile

## Usage

Clone this repo to a fresh Windows machine and run:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
Install-BoxstarterPackage -PackageName install-dev-machine.ps1 -Force