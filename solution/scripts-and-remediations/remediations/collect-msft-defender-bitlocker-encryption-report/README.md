---
Title: README
Date: Juni 28, 2022
Author: dotjesper
Status: In development
---

[![Built for Windows 11](https://img.shields.io/badge/Built%20for%20Windows%2011-Yes-blue?style=flat)](https://windows.com/ "Built for Windows 11")
[![Built for Windows 10](https://img.shields.io/badge/Built%20for%20Windows%2010-Yes-blue?style=flat)](https://windows.com/ "Built for Windows 10")
[![Built for Windows Autopilot](https://img.shields.io/badge/Built%20for%20Windows%20Autopilot-Yes-blue?style=flat)](https://docs.microsoft.com/en-us/mem/autopilot/windows-autopilot/ "Windows Autopilot")

[![PSScriptAnalyzer verified](https://img.shields.io/badge/PowerShell%20Script%20Analyzer%20verified-Yes-green?style=flat)](https://docs.microsoft.com/en-us/powershell/module/psscriptanalyzer/ "PowerShell Script Analyzer")
[![PowerShell Constrained Language mode verified](https://img.shields.io/badge/PowerShell%20Constrained%20Language%20mode%20verified-No-green?style=flat)](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_language_modes/ "PowerShell Language mode")

# Microsoft Intune remediation: Collect browser extensions

The detection script will collect and upload browser extension installed, to Log Analytics in Azure Monitor.

Collecting browser extensions for the follwoig browsers;

- Microsoft Edge
- Google Chrome

Extensions are collected for all user profiles in the above browsers, and can result in extensions is reported multiple times, due to the nature of how browsers handle extensions.

> Script tested on Microsoft Edge and Google Chrome version 102+ only.

## Script package information

External logging: **No**

## Script package properties

### Basic

Name: **Collect browser extensions**

Description: **Collect browser extensions installed in Microsoft Edge and/or Google Chrome, collected extensions are uploaded to Log Analytics in Azure Monitor.**

Publisher: **Jesper Nielsen**

### Settings

Detection script: **Yes**

Remediation script: **No**

Run this script using the logged-on credentials: **Yes**

Enforce script signature check: **No**

Run script in 64-bit PowerShell: **Yes**

### Assignments

Schedule: **Weekly**
