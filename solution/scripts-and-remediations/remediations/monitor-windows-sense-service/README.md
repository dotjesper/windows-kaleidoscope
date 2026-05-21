---
Title: README
Date: April 11, 2026
Author: dotjesper
Status: In development
---

[![Built for Windows 11](https://img.shields.io/badge/Built%20for%20Windows%2011-Yes-blue?style=flat)](https://windows.com/ "Built for Windows 11")
[![Built for Windows 10](https://img.shields.io/badge/Built%20for%20Windows%2010-Yes-blue?style=flat)](https://windows.com/ "Built for Windows 10")
[![Built for Windows Autopilot](https://img.shields.io/badge/Built%20for%20Windows%20Autopilot-Yes-blue?style=flat)](https://learn.microsoft.com/mem/autopilot/windows-autopilot/ "Windows Autopilot")

[![PSScriptAnalyzer verified](https://img.shields.io/badge/PowerShell%20Script%20Analyzer%20verified-Yes-green?style=flat)](https://learn.microsoft.com/powershell/module/psscriptanalyzer/ "PowerShell Script Analyzer")
[![PowerShell Constrained Language mode verified](https://img.shields.io/badge/PowerShell%20Constrained%20Language%20mode%20verified-Yes-green?style=flat)](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_language_modes/ "PowerShell Language mode")
[![Strict Mode verified](https://img.shields.io/badge/Strict%20Mode%20verified-Yes-green?style=flat)](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/set-strictmode/ "Set-StrictMode -Version latest")

# Microsoft Intune remediation: Monitor Windows Sense Service

New Windows 11, version 24H2 devices that are intended to be onboarded to Microsoft Defender for Endpoint might require administrators to enable the prerequisite feature.

This affects all supported architectures.

The remediation package checks if the Windows Sense service exists on the device.

- If the service exists, the device is considered compliant.
- If the service does not exist but a pending reboot for the Sense Client capability is detected, the device is considered compliant.
- If the service does not exist, the remediation script will attempt to add the Windows Sense Client Capability feature.

Defender for Endpoint has been removed from the base image for Windows 11, version 24H2 and needs to be manually installed.
See https://support.microsoft.com/topic/kb5043950-windows-11-version-24h2-support-2fd719b6-8c26-469f-99fe-832eb1b702d7

## Script package information

External logging: **No**

## Script package properties

### Basic

Name: **Monitor Windows Sense Service**

Description: **Monitor Windows Sense Service, as Windows 11 24H2 devices that are intended to be onboarded to Microsoft Defender for Endpoint might require administrators to enable the prerequisite feature.**

Publisher: **Jesper Nielsen**

### Settings

Detection script: **Yes**

Remediation script: **Yes**

Run this script using the logged-on credentials: **No**

Enforce script signature check: **No**

Run script in 64-bit PowerShell: **Yes**

### Assignments

Schedule: **Daily | every 5 days**

## Expected output

### detect.ps1

| Exit code | Output |
|:---------:|:-------|
| `exit 0` | `[00.000] Windows Sense service is present [Running]` |
| `exit 0` | `[00.000] Windows Sense service not found - pending reboot` |
| `exit 1` | `[00.000] Windows Sense service not found` |
