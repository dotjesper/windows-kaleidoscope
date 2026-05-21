---
Title: README
Date: April 10, 2026
Author: dotjesper
Status: In development
---

[![Built for Windows 11](https://img.shields.io/badge/Built%20for%20Windows%2011-Yes-blue?style=flat)](https://windows.com/ "Built for Windows 11")
[![Built for Windows 10](https://img.shields.io/badge/Built%20for%20Windows%2010-Yes-blue?style=flat)](https://windows.com/ "Built for Windows 10")
[![Built for Windows Autopilot](https://img.shields.io/badge/Built%20for%20Windows%20Autopilot-Yes-blue?style=flat)](https://learn.microsoft.com/mem/autopilot/windows-autopilot/ "Windows Autopilot")

[![PSScriptAnalyzer verified](https://img.shields.io/badge/PowerShell%20Script%20Analyzer%20verified-Yes-green?style=flat)](https://learn.microsoft.com/powershell/module/psscriptanalyzer/ "PowerShell Script Analyzer")
[![PowerShell Constrained Language mode verified](https://img.shields.io/badge/PowerShell%20Constrained%20Language%20mode%20verified-Yes-green?style=flat)](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_language_modes/ "PowerShell Language mode")
[![Strict Mode verified](https://img.shields.io/badge/Strict%20Mode%20verified-Yes-green?style=flat)](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/set-strictmode/ "Set-StrictMode -Version latest")

# Microsoft Intune remediation: Monitor orphaned Windows Update (WSUS) settings

## Why this script is needed

Organizations transitioning from on-premises WSUS to cloud-native update management through Windows Autopatch or Windows Update for Business often encounter orphaned registry settings left behind by previous configurations. These leftover WSUS registry entries typically originate from co-management scenarios where Configuration Manager previously controlled Windows Update policies, Active Directory Group Policy objects that targeted WSUS servers, or local Group Policy settings applied during imaging (LGPO).

When these orphaned settings remain on a device, they redirect Windows Update traffic to a WSUS server that may no longer exist or that the device can no longer reach. This prevents Windows Autopatch and Windows Update for Business from functioning correctly, causing devices to stop receiving updates entirely.

This remediation package detects and removes orphaned WSUS registry entries so that Windows Update can communicate directly with the Windows Update for Business or Windows Autopatch service.

## How it works

Windows Autopatch monitors conflicting configurations and notifies administrators of specific registry values that prevent Windows from updating properly. These registry keys should be removed to resolve the conflict. However, it is possible that other services write back the registry keys.

The most common sources of conflicting configurations include:

- Active Directory Group Policy
- Configuration Manager device client settings
- Windows Update for Business policies
- Manual registry updates
- Local Group Policy settings applied during imaging (LGPO)

## Registry keys inspected by Windows Autopatch

- HKLM:SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\DoNotConnectToWindowsUpdateInternetLocations Value=Any
- HKLM:SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\DisableWindowsUpdateAccess Value=Any
- HKLM:SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\WUServer String=Any
- HKLM:SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU\UseWUServer Value=Any
- HKLM:SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU\NoAutoUpdate Value=Any

To remove conflicting configurations, follow these steps:

1. Stop the Windows Update service (`Stop-Service -Name wuauserv`)
2. Remove the registry key (`Remove-Item "HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate" -Recurse`)
3. Start the Windows Update service (`Start-Service -Name wuauserv`)

For logging and future troubleshooting, it is recommended to record the following registry values: `WUServer` and `WUStatusServer`.

More information: [Windows Autopatch conflicting configurations](https://learn.microsoft.com/windows/deployment/windows-autopatch/references/windows-autopatch-conflicting-configurations "Conflicting configurations").

### Possible outputs

Windows Update (WSUS) policy settings not found: Registry key not found.

Windows Update (WSUS) policy settings is empty: Registry key found, but is empty.

Windows Update (WSUS) policy settings | `TRVI` | `DNCTWUIL` | `DWUA` | `WUS` | `WUSS` | `UseWUS` | `NAU`:  Registry key and values if found.

- TRVI: `TargetReleaseVersionInfo`
- DNCTWUIL: `DoNotConnectToWindowsUpdateInternetLocations`
- DWUA: `DisableWindowsUpdateAccess`
- WUS: `WUServer`
- WUSS: `WUStatusServer`
- UseWUS: `UseWUServer`
- NAU: `NoAutoUpdate`

Based on the research and [Windows Update Settings Stuck](https://thedxt.ca/2024/08/windows-update-settings-stuck/ "Windows Update Settings Stuck") post by @thedxt, the proposed fix has been added to resolve the described issue.

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

## Expected output

### detect.ps1

| Exit code | Output |
|:---------:|:-------|
| `exit 0` | `[00.000] Windows Update (WSUS) policy settings is empty.` |
| `exit 0` | `[00.000] Windows Update (WSUS) policy settings not found.` |
| `exit 1` | `[00.000] Windows Update (WSUS) policy settings: WUServer=https://wsus.contoso.com:8531 WUStatusServer=https://wsus.contoso.com:8531` |

### remediate.ps1

| Exit code | Output |
|:---------:|:-------|
| `exit 0` | `[00.000] Windows Update (WSUS) policy settings reset successful.` |
| `exit 0` | `[00.000] Windows Update (WSUS) policy settings is empty.` |
| `exit 0` | `[00.000] Windows Update (WSUS) policy settings not found.` |
