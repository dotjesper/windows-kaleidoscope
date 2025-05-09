---
Title: README
Date: May 9, 2025
Author: dotjesper
Status: In development
---

[![Built for Windows 11](https://img.shields.io/badge/Built%20for%20Windows%2011-Yes-blue?style=flat)](https://windows.com/ "Built for Windows 11")
[![Built for Windows 10](https://img.shields.io/badge/Built%20for%20Windows%2010-No-blue?style=flat)](https://windows.com/ "Built for Windows 10")
[![Built for Windows Autopilot Device Preparation](https://img.shields.io/badge/Built%20for%20Windows%20Autopilot-Yes-blue?style=flat)](https://learn.microsoft.com/autopilot/device-preparation/overview/ "Windows Autopilot")

[![PSScriptAnalyzer verified](https://img.shields.io/badge/PowerShell%20Script%20Analyzer%20verified-Yes-green?style=flat)](https://learn.microsoft.com/powershell/module/psscriptanalyzer/ "PowerShell Script Analyzer")
[![PowerShell Constrained Language mode verified](https://img.shields.io/badge/PowerShell%20Constrained%20Language%20mode%20verified-Yes-green?style=flat)](https://docs.microsoft.com/powershell/module/microsoft.powershell.core/about/about_language_modes/ "PowerShell Language mode")

# Windows Autopilot device preparation script (PREVIEW).

Windows Autopilot device preparation automates the initial device setup by configuring the computer’s name, setting registry keys for a streamlined out-of-box experience, and optionally creating location markers before the device enters production.

## Description
- Renames the computer based on naming rules:
  - **%SERIAL%** uses the device's serial number.
  - **%RAND:x%** uses random digits (x defines the number of digits).
  - Defaults to a SHA256 hash of the serial number if no method is specified.
- Updates registry settings to streamline the out-of-box experience (OOBE).
- Marks the system for a pending reboot (without forcing it).
- Optionally sets a location marker in the registry.

## Parameters
- **-Prefix** - Custom prefix for the computer name (default: `WSR5`).
- **-Suffix** - Custom suffix for the computer name.
- **-NamingMethod**
  - `%SERIAL%`: uses the serial number.
  - `%RAND:x%`: uses random digits of length x.
- **-LocationMarker** - Adds a registry marker to identify location or organization.
- **-LocationMarkerPath** - Registry path for the location marker.
- **-logFile** - Custom log file path (default writes to `device-preparation.log`).

## Usage

```powershell
.\device-preparation.ps1 -Prefix "WIN-" -Suffix "-01" -NamingMethod "%SERIAL%"
.\device-preparation.ps1 -Prefix "PC-" -NamingMethod "%RAND:6%"
.\device-preparation.ps1 -LocationMarker "US" -LocationMarkerPath "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Custom\Location"
```

# Script properties

### Basic

PowerShell script: **Modern Workplace - Device preparation script v2**

Description: **Windows Autopilot device preparation script v2**

### Script settings

PowerShell script: **device-preparation.ps1**

Run this script using the logged on credentials: **No**

Enforce script signature check: **No**

Run script in 64 bit PowerShell Host: **Yes**

### Assignments

Ensure to assign this to a device group.
