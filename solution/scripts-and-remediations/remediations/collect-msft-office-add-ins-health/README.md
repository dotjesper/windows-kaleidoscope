---
Title: README
Date: April 13, 2026
Author: dotjesper
Status: In development
---

[![Built for Windows 11](https://img.shields.io/badge/Built%20for%20Windows%2011-Yes-blue?style=flat)](https://windows.com/ "Built for Windows 11")
[![Built for Windows 10](https://img.shields.io/badge/Built%20for%20Windows%2010-Yes-blue?style=flat)](https://windows.com/ "Built for Windows 10")
[![Built for Windows Autopilot](https://img.shields.io/badge/Built%20for%20Windows%20Autopilot-Yes-blue?style=flat)](https://learn.microsoft.com/mem/autopilot/windows-autopilot/ "Windows Autopilot")

[![PSScriptAnalyzer verified](https://img.shields.io/badge/PowerShell%20Script%20Analyzer%20verified-Yes-green?style=flat)](https://learn.microsoft.com/powershell/module/psscriptanalyzer/ "PowerShell Script Analyzer")
[![PowerShell Constrained Language mode verified](https://img.shields.io/badge/PowerShell%20Constrained%20Language%20mode%20verified-Yes-green?style=flat)](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_language_modes/ "PowerShell Language mode")
[![Strict Mode verified](https://img.shields.io/badge/Strict%20Mode%20verified-Yes-green?style=flat)](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/set-strictmode/ "Set-StrictMode -Version latest")

# Microsoft Intune remediation: Collect Microsoft Office add-in health

Collect Microsoft Office add-in health information by reading resiliency data from the registry. The script identifies add-ins that have been disabled by Office due to performance or stability issues, add-ins flagged for slow load times, and add-ins that users have manually re-enabled after being disabled.

## Script package information

External logging: **No**

## Script package properties

### Basic

Name: **Collect Microsoft Office add-in health**

Description: **Collect Office add-in resiliency data, fails if add-ins have been disabled by Office**

Publisher: **Jesper Nielsen**

### Settings

Detection script: **Yes**

Remediation script: **No**

Run this script using the logged-on credentials: **Yes**

Enforce script signature check: **No**

Run script in 64-bit PowerShell: **No**

### Assignments

Schedule: **Weekly**

## Expected output

### detect.ps1

| Exit code | Output |
|:---------:|:-------|
| `exit 0` | `[00.000] No disabled add-ins found. Excel: 2 add-ins, Outlook: 5 add-ins.` |
| `exit 0` | `[00.000] No disabled add-ins found. No resiliency data detected.` |
| `exit 1` | `[00.000] Add-ins disabled by Office (3). Excel: 2 add-ins (1 disabled), Outlook: 5 add-ins (2 disabled).` |
