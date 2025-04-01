---
Title: README
Date: May 30, 2022
Author: dotjesper
Status: In development
---

[![Built for Windows 11](https://img.shields.io/badge/Built%20for%20Windows%2011-Yes-blue?style=flat)](https://windows.com/ "Built for Windows 11")
[![Built for Windows 10](https://img.shields.io/badge/Built%20for%20Windows%2010-Yes-blue?style=flat)](https://windows.com/ "Built for Windows 10")
[![Built for Windows Autopilot](https://img.shields.io/badge/Built%20for%20Windows%20Autopilot-Yes-blue?style=flat)](https://docs.microsoft.com/en-us/mem/autopilot/windows-autopilot/ "Windows Autopilot")

[![PSScriptAnalyzer verified](https://img.shields.io/badge/PowerShell%20Script%20Analyzer%20verified-No-green?style=flat)](https://docs.microsoft.com/en-us/powershell/module/psscriptanalyzer/ "PowerShell Script Analyzer")
[![PowerShell Constrained Language mode verified](https://img.shields.io/badge/PowerShell%20Constrained%20Language%20mode%20verified-No-green?style=flat)](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_language_modes/ "PowerShell Language mode")

# Microsoft Intune remediation: Monitor Unquoted Service Paths

This repository contains script for remediate the "Microsoft Windows Unquoted Service Path Enumeration" vulnerability.

## Script package information

External logging: **Yes**

External log: **"%ProgramData%\Microsoft\IntuneManagementExtension\Logs\prUnquotedServicePaths.log"**

## Script package properties

### Basic

Name: **Monitor Unquoted Service Paths**

Description: **Monitor and remediate the "Microsoft Windows Unquoted Service Path Enumeration" vulnerability.**

Publisher: **Jesper Nielsen**

### Settings

Detection script: **Yes**

Remediation script: **Yes**

Run this script using the logged-on credentials: **No**

Enforce script signature check: **No**

Run script in 64-bit PowerShell: **Yes**

### Assignments

Schedule: **Daily**

## References

[https://pentestlab.blog/2017/03/09/unquoted-service-path/](https://pentestlab.blog/2017/03/09/unquoted-service-path/)

[https://github.com/VectorBCO/windows-path-enumerate](https://github.com/VectorBCO/windows-path-enumerate)

[https://www.commonexploits.com/unquoted-service-paths/](https://www.commonexploits.com/unquoted-service-paths/)

[https://gallery.technet.microsoft.com/scriptcenter/Windows-Unquoted-Service-190f0341](https://gallery.technet.microsoft.com/scriptcenter/Windows-Unquoted-Service-190f0341)

[https://social.technet.microsoft.com/Forums/en-US/a34855ae-47e5-4567-bb1e-17bf6a97ab75/microsoft-windows-unquoted-service-path-enumeration](https://social.technet.microsoft.com/Forums/en-US/a34855ae-47e5-4567-bb1e-17bf6a97ab75/microsoft-windows-unquoted-service-path-enumeration)

[http://www.ryanandjeffshow.com/blog/2013/04/11/powershell-fixing-unquoted-service-paths-complete/](https://social.technet.microsoft.com/Forums/en-US/a34855ae-47e5-4567-bb1e-17bf6a97ab75/microsoft-windows-unquoted-service-path-enumeration)