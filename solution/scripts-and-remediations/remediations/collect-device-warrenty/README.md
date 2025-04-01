---
Title: README
Date: September 3, 2024
Author: dotjesper
Status: In development
---

[![Built for Windows 11](https://img.shields.io/badge/Built%20for%20Windows%2011-Yes-blue?style=flat)](https://windows.com/ "Built for Windows 11")
[![Built for Windows 10](https://img.shields.io/badge/Built%20for%20Windows%2010-Yes-blue?style=flat)](https://windows.com/ "Built for Windows 10")
[![Built for Windows Autopilot](https://img.shields.io/badge/Built%20for%20Windows%20Autopilot-Yes-blue?style=flat)](https://docs.microsoft.com/en-us/mem/autopilot/windows-autopilot/ "Windows Autopilot")

[![PSScriptAnalyzer verified](https://img.shields.io/badge/PowerShell%20Script%20Analyzer%20verified-Yes-green?style=flat)](https://docs.microsoft.com/en-us/powershell/module/psscriptanalyzer/ "PowerShell Script Analyzer")
[![PowerShell Constrained Language mode verified](https://img.shields.io/badge/PowerShell%20Constrained%20Language%20mode%20verified-No-green?style=flat)](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_language_modes/ "PowerShell Language mode")

# Microsoft Intune remediation: Collect device warranty information

Collect device warranty information from the vendors website.

Currently supported vendors:

- Lenovo

The script will return either of the following:

* The warranty for the device with serial number [GR97ZT9W] is active [Start: 2021-06-01 | End: 2025-06-01 | Days Left: 345].
* The warranty for the device with serial number [YT07QT6R] is about to expire [Start: 2021-06-01 | End: 2024-10-01 | Days Left: 48].
* The warranty for the device with serial number [GRT09KL4] has expired [Start: 2021-06-01 | End: 2024-06-01 | Days Overdue: 123].

This remediation package is heavily inspired by the [Get Lenovo device warranty info (expired or active) with PowerShell](https://www.systanddeploy.com/2024/08/using-powershell-to-know-if-lenovo.html "Get Lenovo device warranty info (expired or active) with PowerShell") blogpost by @damienvanrobaeys, who did a fabulous job putting the code together.

## Script package information

Warranty Time Threshold (days): **60**

External logging: **No**

## Script package properties

### Basic

Name: **Collect device warranty information**

Description: **Collect device warranty information from the vendors website.**

Publisher: **Jesper Nielsen**

### Settings

Detection script: **Yes**

Remediation script: **No**

Run this script using the logged-on credentials: **No**

Enforce script signature check: **No**

Run script in 64-bit PowerShell: **No**

### Assignments

Schedule: **Daily** | every 22 days
