---
Title: README
Date: May 21, 2022
Author: dotjesper
Status: In development
---

[![Built for Windows 11](https://img.shields.io/badge/Built%20for%20Windows%2011-Yes-blue?style=flat)](https://windows.com/ "Built for Windows 11")
[![Built for Windows 10](https://img.shields.io/badge/Built%20for%20Windows%2010-Yes-blue?style=flat)](https://windows.com/ "Built for Windows 10")
[![Built for Windows Autopilot](https://img.shields.io/badge/Built%20for%20Windows%20Autopilot-Yes-blue?style=flat)](https://docs.microsoft.com/en-us/mem/autopilot/windows-autopilot/ "Windows Autopilot")

[![PSScriptAnalyzer verified](https://img.shields.io/badge/PowerShell%20Script%20Analyzer%20verified-Yes-green?style=flat)](https://docs.microsoft.com/en-us/powershell/module/psscriptanalyzer/ "PowerShell Script Analyzer")
[![PowerShell Constrained Language mode verified](https://img.shields.io/badge/PowerShell%20Constrained%20Language%20mode%20verified-Yes-green?style=flat)](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_language_modes/ "PowerShell Language mode")

# Microsoft Intune remediation: Monitor Windows default action for list of potentially Malicious file types

Monitor Windows default action for list of potentially Malicious file types.

When looking at file names in Explorer, be aware Windows might hide the file extension for known file types. Please notice, changing default bahaviour to EDIT will cause scripts to open on e.g. Notepad if not properly prefixed with target executable.

Potentially dangerous extensions: JSE, JS, reg, VBE, VBS, WSF, bat, cmd, hta.

## Script package information

File types: **JSEFile**, **JSFile**, **regfile**, **VBEFile**, **VBSFile**, **WSFFile**, **batfile**, **cmdfile**, **htafile**

File Action: **edit**

External logging: **No**

## Script package properties

### Basic

Name: **Monitor Windows default action for list of potentially Malicious file types**.

Description: **Monitor Windows default action for list of potentially Malicious file types.**

Publisher: **Jesper Nielsen**

### Settings

Detection script: **Yes**

Remediation script: **Yes**

Run this script using the logged-on credentials: **No**

Enforce script signature check: **No**

Run script in 64-bit PowerShell: **No**

### Assignments

Schedule: **Weekly**
