---
Title: README
Date: May 30, 2022
Author: dotjesper
Status: In development
---

[![Built for Windows 11](https://img.shields.io/badge/Built%20for%20Windows%2011-Yes-blue?style=flat)](https://windows.com/ "Built for Windows 11")
[![Built for Windows 10](https://img.shields.io/badge/Built%20for%20Windows%2010-Yes-blue?style=flat)](https://windows.com/ "Built for Windows 10")
[![Built for Windows Autopilot](https://img.shields.io/badge/Built%20for%20Windows%20Autopilot-Yes-blue?style=flat)](https://learn.microsoft.com/mem/autopilot/windows-autopilot/ "Windows Autopilot")

[![PSScriptAnalyzer verified](https://img.shields.io/badge/PowerShell%20Script%20Analyzer%20verified-Yes-green?style=flat)](https://learn.microsoft.com/powershell/module/psscriptanalyzer/ "PowerShell Script Analyzer")
[![PowerShell Constrained Language mode verified](https://img.shields.io/badge/PowerShell%20Constrained%20Language%20mode%20verified-No-orange?style=flat)](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_language_modes/ "PowerShell Language mode")
[![Strict Mode verified](https://img.shields.io/badge/Strict%20Mode%20verified-No-orange?style=flat)](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/set-strictmode/ "Set-StrictMode -Version latest")

# Microsoft Intune remediation: Monitor unquoted service paths

This package contains scripts to detect and remediate the "Microsoft Windows Unquoted Service Path Enumeration" vulnerability.

Unquoted service paths occur when a Windows service executable path contains spaces but is not enclosed in quotation marks. When Windows starts a service with an unquoted path such as `C:\Program Files\Some Folder\service.exe`, it attempts to resolve the path by trying each possible interpretation in order - for example, `C:\Program.exe`, then `C:\Program Files\Some.exe`, before reaching the intended executable. An attacker with write access to one of these intermediate directories can place a malicious executable at a location Windows tries first, resulting in privilege escalation when the service starts.

The detection script identifies services and uninstall strings with unquoted paths that contain spaces. The remediation script corrects the affected paths by wrapping them in quotation marks.

Microsoft Defender for Endpoint flags unquoted service paths as a security recommendation through [Vulnerability Management](https://learn.microsoft.com/defender-vulnerability-management/tvm-security-recommendation). The vulnerability is classified as [CWE-428: Unquoted Search Path or Element](https://cwe.mitre.org/data/definitions/428.html). This remediation package provides an automated fix for the findings reported by Microsoft Defender for Endpoint.

> [!WARNING]
> This package modifies Windows service registry entries. Incorrect service paths can prevent services from starting. Always test in a non-production environment before deploying broadly. All detected unquoted paths and all remediation changes are written to the local log file for auditing and troubleshooting. **Use this package at your own risk**.

## Script package information

External logging: **Yes**

External log: **"%ProgramData%\Microsoft\IntuneManagementExtension\Logs\UnquotedServicePaths.log"**

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

## Expected output

### detect.ps1

| Exit code | Output |
|:---------:|:-------|
| `exit 0` | `[00.000] No vulnerabilities found, see [DESKTOP-ABC123] C:\ProgramData\kaleidoscope\unquotedServicePaths.log for further information.` |
| `exit 1` | `[00.000] Found 3 vulnerabilities, see [DESKTOP-ABC123] C:\ProgramData\kaleidoscope\unquotedServicePaths.log for further information.` |

### remediate.ps1

| Exit code | Output |
|:---------:|:-------|
| `exit 0` | `[00.000] No vulnerabilities found, see [DESKTOP-ABC123] C:\ProgramData\kaleidoscope\unquotedServicePaths.log for further information.` |
| `exit 0` | `[00.000] 3 of 3 vulnerable strings remediated, see [DESKTOP-ABC123] C:\ProgramData\kaleidoscope\unquotedServicePaths.log for further information.` |
| `exit 1` | `[00.000] 2 of 3 vulnerable strings remediated, see [DESKTOP-ABC123] C:\ProgramData\kaleidoscope\unquotedServicePaths.log for further information.` |

## References

The following resources provide additional context on the unquoted service path vulnerability:

[https://pentestlab.blog/2017/03/09/unquoted-service-path/](https://pentestlab.blog/2017/03/09/unquoted-service-path/)

[https://github.com/VectorBCO/windows-path-enumerate](https://github.com/VectorBCO/windows-path-enumerate)

[https://www.commonexploits.com/unquoted-service-paths/](https://www.commonexploits.com/unquoted-service-paths/)
