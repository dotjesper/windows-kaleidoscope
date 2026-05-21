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

# Microsoft Intune remediation: Monitor PowerShell Execution Policy

Monitor the PowerShell Execution Policy for both 64-bit and 32-bit PowerShell environments, and reset to the default value (Restricted) if misconfigured. The execution policy is read and written directly via the registry at the machine scope.

## Script package information

External logging: **No**

## Script package properties

### Basic

Name: **Monitor PowerShell Execution Policy**

Description: **Monitor PowerShell Execution Policy and reset to default (Restricted)**

Publisher: **Jesper Nielsen**

### Settings

Detection script: **Yes**

Remediation script: **Yes**

Run this script using the logged-on credentials: **No**

Enforce script signature check: **No**

Run script in 64-bit PowerShell: **No**

### Assignments

Schedule: **Daily**

## Expected output

### detect.ps1

| Exit code | Output |
|:---------:|:-------|
| `exit 0` | `[00.000] PowerShell Execution Policy compliant (64-bit: RemoteSigned, 32-bit: RemoteSigned)` |
| `exit 1` | `[00.000] PowerShell Execution Policy non-compliant (64-bit: Unrestricted, 32-bit: Bypass)` |
