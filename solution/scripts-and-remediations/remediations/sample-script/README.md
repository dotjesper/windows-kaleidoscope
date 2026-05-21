---
Title: README
Date: April 7, 2026
Author: dotjesper
Status: In development
---

[![Built for Windows 11](https://img.shields.io/badge/Built%20for%20Windows%2011-Yes-blue?style=flat)](https://windows.com/ "Built for Windows 11")
[![Built for Windows 10](https://img.shields.io/badge/Built%20for%20Windows%2010-Yes-blue?style=flat)](https://windows.com/ "Built for Windows 10")
[![Built for Windows Autopilot](https://img.shields.io/badge/Built%20for%20Windows%20Autopilot-Yes-blue?style=flat)](https://learn.microsoft.com/mem/autopilot/windows-autopilot/ "Windows Autopilot")

[![PSScriptAnalyzer verified](https://img.shields.io/badge/PowerShell%20Script%20Analyzer%20verified-Yes-green?style=flat)](https://learn.microsoft.com/powershell/module/psscriptanalyzer/ "PowerShell Script Analyzer")
[![PowerShell Constrained Language mode verified](https://img.shields.io/badge/PowerShell%20Constrained%20Language%20mode%20verified-No-green?style=flat)](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_language_modes/ "PowerShell Language mode")
[![Strict Mode verified](https://img.shields.io/badge/Strict%20Mode%20verified-Yes-green?style=flat)](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/set-strictmode/ "Set-StrictMode -Version latest")

# Microsoft Intune remediation: Sample script (Hello World)

Hello world sample script for exploring remediation functionality. The script demonstrates different output methods and logging patterns used in Microsoft Intune remediation scripts.

Microsoft Intune remediation scripts do not support passing parameters at runtime. To change the test or enable DoFail, edit the default values in the `param()` block before uploading to Microsoft Intune.

## DoTest parameter

Select the test to run (1-12):

| Test | Description |
|-----:|-------------|
| 1 | Multiple Write-Output lines |
| 2 | Write-Output with carriage return and new line |
| 3 | Multiple Write-Information lines |
| 4 | Write-Information with carriage return and new line |
| 5 | Multiple Write-Information with carriage return and new line |
| 6 | Write-Error |
| 7 | Write-Verbose |
| 8 | Multiple Write-Verbose |
| 9 | Write-Output and Write-Error |
| 10 | Write-Output with environment details |
| 11 | Write-Output with Write-Log to log file |
| 12 | Read protected CIM class (Win32_Tpm, requires elevation) |

## DoFail parameter

If set to `$true`, the script will exit with code 1, causing the detection script to fail and trigger remediation.

## Script package information

DoTest parameter: **1** - **12**

DoFail parameter: **$true** / **$false**

External logging: **Yes** (test 11)

## Script package properties

### Basic

Name: **Hello World**

Description: **Hello world sample script for exploring remediation functionality**

Publisher: **Jesper Nielsen**

### Settings

Detection script: **Yes**

Remediation script: **No**

Run this script using the logged-on credentials: **Yes** / **No**

Enforce script signature check: **Yes** / **No**

Run script in 64-bit PowerShell: **Yes** / **No**

### Assignments

Schedule: **Daily**
