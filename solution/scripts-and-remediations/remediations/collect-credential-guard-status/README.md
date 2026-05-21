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

# Microsoft Intune remediation: Detect Credential Guard status

Detect the Credential Guard configuration and runtime status by querying the Win32_DeviceGuard WMI class. Reports whether Virtualization Based Security is enabled, whether Credential Guard is configured, and whether Credential Guard is actively running.

Starting in Windows 11, 22H2 and Windows Server 2025, Credential Guard is enabled by default on devices that meet the requirements. However, if Credential Guard was explicitly disabled before upgrading to a newer version of Windows, it remains disabled even after the update. This package helps identify devices where Credential Guard is not running, whether due to an explicit opt-out, missing hardware prerequisites, or a configuration that did not carry forward after an OS upgrade.

Monitoring Credential Guard status across your fleet provides visibility into Virtualization Based Security adoption and helps validate that credential isolation is active before relying on it as part of a broader Zero Trust strategy.

## Script package information

External logging: **No**

## Script package properties

### Basic

Name: **Detect Credential Guard status**

Description: **Detect Credential Guard configuration and runtime status, reporting Virtualization Based Security state and whether Credential Guard is configured and running.**

Publisher: **Jesper Nielsen**

### Settings

Detection script: **Yes**

Remediation script: **No**

Run this script using the logged-on credentials: **No**

Enforce script signature check: **No**

Run script in 64-bit PowerShell: **Yes**

### Assignments

Schedule: **Weekly**

## Expected output

### detect.ps1

| Exit code | Output |
|:---------:|:-------|
| `exit 0` | `[00.000] Credential Guard running [VBS: Running \| Configured: 1 \| Running: 1].` |
| `exit 1` | `[00.000] Credential Guard not running [VBS: Not enabled \| Configured: 0 \| Running: 0].` |
