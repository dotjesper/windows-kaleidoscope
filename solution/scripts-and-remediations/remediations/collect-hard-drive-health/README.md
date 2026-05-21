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

# Microsoft Intune remediation: Collect hard drive health

Actively collect hard drive health throughout Windows devices by checking physical disk health status, SMART failure prediction, wear level, read/write error counts, and temperature. Allows proactive hard drive replacement prior to having to remediate disk failures reactively.

## Script package information

Maximum wear value: **90%**

Maximum read/write errors: **100**

Maximum temperature: **60°C**

External logging: **No**

## Script package properties

### Basic

Name: **Collect hard drive health**

Description: **Collect hard drive health, fails if disk health status, SMART prediction, wear, read/write errors, or temperature exceed thresholds**

Publisher: **Jesper Nielsen**

### Settings

Detection script: **Yes**

Remediation script: **No**

Run this script using the logged-on credentials: **No**

Enforce script signature check: **No**

Run script in 64-bit PowerShell: **No**

### Assignments

Schedule: **Weekly**

## Expected output

### detect.ps1

| Exit code | Output |
|:---------:|:-------|
| `exit 0` | `[00.000] All hard drives healthy (Disks: 2, SMART: Healthy)` |
| `exit 0` | `[00.000] No physical disks found or unable to obtain disk information.` |
| `exit 1` | `[00.000] Hard drive health issue detected (Disks: 2, SMART: Warning)` |

## Known limitations

Hard drive health data availability depends on drive type and hardware capabilities.

- **SMART failure prediction** relies on the `MSStorageDriver_FailurePredictStatus` WMI class (`root\wmi`), which is primarily available on SATA drives. Many NVMe SSDs do not expose this class and SMART status will report as `n/a`.
- **Storage reliability counters** (`Get-StorageReliabilityCounter`) availability varies by hardware. Read/write error counts may report as `n/a` on drives that do not expose these counters.
- The script requires administrator privileges. In Microsoft Intune, this is handled automatically when running as SYSTEM.
