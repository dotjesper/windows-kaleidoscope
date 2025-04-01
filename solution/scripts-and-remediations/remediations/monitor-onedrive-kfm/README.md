---
Title: README
Date: May 28, 2022
Author: dotjesper
Status: In development
---

[![Built for Windows 11](https://img.shields.io/badge/Built%20for%20Windows%2011-Yes-blue?style=flat)](https://windows.com/ "Built for Windows 11")
[![Built for Windows 10](https://img.shields.io/badge/Built%20for%20Windows%2010-Yes-blue?style=flat)](https://windows.com/ "Built for Windows 10")
[![Built for Windows Autopilot](https://img.shields.io/badge/Built%20for%20Windows%20Autopilot-Yes-blue?style=flat)](https://docs.microsoft.com/en-us/mem/autopilot/windows-autopilot/ "Windows Autopilot")

[![PSScriptAnalyzer verified](https://img.shields.io/badge/PowerShell%20Script%20Analyzer%20verified-Yes-green?style=flat)](https://docs.microsoft.com/en-us/powershell/module/psscriptanalyzer/ "PowerShell Script Analyzer")
[![PowerShell Constrained Language mode verified](https://img.shields.io/badge/PowerShell%20Constrained%20Language%20mode%20verified-Yes-green?style=flat)](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_language_modes/ "PowerShell Language mode")

# Microsoft Intune remediation: Monitor Microsoft OneDrive for Business Known Folder Move (KFM)

Today, organizations, can benefit from monitoring the use of Microsoft OneDrive for Business, and in particular the status of Known Folder Move (KFM), enabling OneDrive Health monitoring using https://config.office.com/officeSettings/onedrive/.

However; in the case where a devices have issues, moving one or more folder to Microsoft OneDrive for Business, this script will monitor and remidiate (re-initilize) the Known Folder Move (KFM) process.

## Script package information

External logging: **No**

## Script package properties

### Basic

Name: **Monitor Microsoft OneDrive for Business Known Folder Move (KFM)**

Description: **Monitor Microsoft OneDrive for Business Known Folder Move (KFM) status, re-initilize Known Folder Move (KFM) process if settings does not align.**

Publisher: **Jesper Nielsen**

### Settings

Detection script: **Yes**

Remediation script: **Yes**

Run this script using the logged-on credentials: **Yes**

Enforce script signature check: **No**

Run script in 64-bit PowerShell: **Yes**

### Assignments

Schedule: **Weekly**
