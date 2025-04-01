---
Title: README
Date: May 31, 2022
Author: dotjesper
Status: In development
---

[![Built for Windows 11](https://img.shields.io/badge/Built%20for%20Windows%2011-Yes-blue?style=flat)](https://windows.com/ "Built for Windows 11")
[![Built for Windows 10](https://img.shields.io/badge/Built%20for%20Windows%2010-Yes-blue?style=flat)](https://windows.com/ "Built for Windows 10")
[![Built for Windows Autopilot](https://img.shields.io/badge/Built%20for%20Windows%20Autopilot-Yes-blue?style=flat)](https://docs.microsoft.com/en-us/mem/autopilot/windows-autopilot/ "Windows Autopilot")

[![PSScriptAnalyzer verified](https://img.shields.io/badge/PowerShell%20Script%20Analyzer%20verified-No-green?style=flat)](https://docs.microsoft.com/en-us/powershell/module/psscriptanalyzer/ "PowerShell Script Analyzer")
[![PowerShell Constrained Language mode verified](https://img.shields.io/badge/PowerShell%20Constrained%20Language%20mode%20verified-No-green?style=flat)](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_language_modes/ "PowerShell Language mode")

# Microsoft Intune remediation script: Sample script [Hello World]

This repository contains the source code for the **Hello World demonstration** scripts. The script(s) are built for multiple purpose to explorer **Remediation** script packages and the script environment.

**doTest paramater**

1. Multiple Write-Output lines
2. Write-Output with carriage return and new line (\`r\`n)
3. Multiple Write-Host lines
4. Write-Host with carriage return and new line (\`r\`n)
5. Multiple Write-Host with carriage return and new line (\`r\`n)
6. Write-Error
7. Write-Verbose
8. Multiple Write-Verbose
9. Write-Output and Write-Error
10. Write-Output
11. Write-Output and add content to log file

**doFail paramater**

If set to $true, the script will exit with 1, equals the detection script will fail.

## Script package information

doTest paramater (n): **1** - **11**

doFail paramater: **$true** / **$false**.

External logging: **Yes** / **No**

## Script package properties

### Basic

Name: **Hello World M(n)**

Description: **Hello world sample script for exploring remediation functionality**

Publisher: **Jesper Nielsen**

### Settings

Detection script: **Yes**

Remediation script: **No**

Run this script using the logged-on credentials: **Yes** / **No**

Enforce script signature check:  **Yes** / **No**

Run script in 64-bit PowerShell: **Yes** / **No**

### Assignments

Schedule: **Daily**
