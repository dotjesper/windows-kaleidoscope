---
Title: README
Date: April 15, 2021
Author: dotjesper
Status: In development
---

[![Built for Windows 11](https://img.shields.io/badge/Built%20for%20Windows%2011-Yes-blue?style=flat)](https://windows.com/ "Built for Windows 11")
[![Built for Windows 10](https://img.shields.io/badge/Built%20for%20Windows%2010-Yes-blue?style=flat)](https://windows.com/ "Built for Windows 10")
[![Built for Windows Autopilot](https://img.shields.io/badge/Built%20for%20Windows%20Autopilot-Yes-blue?style=flat)](https://docs.microsoft.com/en-us/mem/autopilot/windows-autopilot/ "Windows Autopilot")

[![PSScriptAnalyzer verified](https://img.shields.io/badge/PowerShell%20Script%20Analyzer%20verified-Yes-green?style=flat)](https://docs.microsoft.com/en-us/powershell/module/psscriptanalyzer/ "PowerShell Script Analyzer")
[![PowerShell Constrained Language mode verified](https://img.shields.io/badge/PowerShell%20Constrained%20Language%20mode%20verified-Yes-green?style=flat)](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_language_modes/ "PowerShell Language mode")

# Microsoft Intune remediation: Monitor orphaned Windows Update (WSUS) settings

In certain scenarios, you may need to remove a WSUS server from your network or have a client computer stop pointing to a local WSUS server. To reset the Windows Update defaults and remove the WSUS redirect on the computer, you will need to remove some registry entries.

Windows Autopatch monitors conflicting configurations. You’re notified of the specific registry values that prevent Windows from updating properly. These registry keys should be removed to resolve the conflict. However, it’s possible that other services write back the registry keys.

The most common sources of conflicting configurations include:

- Active Directory Group Policy (GPO)
- Configuration Manager Device client settings
- Windows Update for Business (WUfB) policies
- Manual registry updates
- Local Group Policy settings applied during imaging (LGPO)

## Registry keys inspected by Windows Autopatch

- HKLM:SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\DoNotConnectToWindowsUpdateInternetLocations Value=Any
- HKLM:SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\DisableWindowsUpdateAccess Value=Any
- HKLM:SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\WUServer String=Any
- HKLM:SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU\UseWUServer Value=Any
- HKLM:SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU\NoAutoUpdate Value=Any

To remove conflicting configurations, follow these steps:

1. Stop the Windows Update service (<code>Stop-Service -Name wuauserv</code>)
2. Remove the registry key (<code>Remove-Item "HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate" -Recurse</code>)
3. Start the Windows Update service (<code>Start-Service -Name wuauserv</code>)

For logging and future troubleshooting, it is recomended to record the following registry values: <code>WUServer</code> and <code>WUStatusServer</code>.

More information [Windows Autopatch Conflicting configurations](https://learn.microsoft.com/en-us/windows/deployment/windows-autopatch/references/windows-autopatch-conflicting-configurations "Conflicting configurations").

### Possible outputs

Windows Update (WSUS) policy settings not found: Registry key not found.

Windows Update (WSUS) policy settings is empty: Registry key found, but is empty.

Windows Update (WSUS) policy settings | <code>TRVI</code> | <code>DNCTWUIL</code> | <code>DWUA</code> | <code>WUS</code> | <code>WUSS</code> | <code>UseWUS</code> | <code>NAU</code>:  Registry key and values if found.

- TRVI: <code>TargetReleaseVersionInfo</code>
- DNCTWUIL: <code>DoNotConnectToWindowsUpdateInternetLocations</code>
- DWUA: <code>DisableWindowsUpdateAccess</code>
- WUS: <code>WUServer</code>
- WUSS: <code>WUStatusServer</code>
- UseWUS: <code>UseWUServer</code>
- NAU: <code>NoAutoUpdate</code>

Base on the research and [Windows Update Settings Stuck](https://thedxt.ca/2024/08/windows-update-settings-stuck/ "Windows Update Settings Stuck") post by @thedxt, I have added the proposed fix to resolve the described issue.

## Script package information

External logging: **No**

## Script package properties

### Basic

Name: **Monitor orphaned Windows Update (WSUS) settings**

Description: **Monitor orphaned Windows Update (WSUS) settings.**

Publisher: **Jesper Nielsen**

### Settings

Detection script: **Yes**

Remediation script: **Yes**

Run this script using the logged-on credentials: **No**

Enforce script signature check: **No**

Run script in 64-bit PowerShell: **Yes**

### Assignments

Schedule: **Daily**

Interval: **Repeats every 5 days**

