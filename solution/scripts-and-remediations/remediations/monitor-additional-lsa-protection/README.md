---
Title: README
Date: April 10, 2026
Author: dotjesper
Status: In development
---

[![Built for Windows 11](https://img.shields.io/badge/Built%20for%20Windows%2011-Yes-blue?style=flat)](https://windows.com/ "Built for Windows 11")
[![Built for Windows 10](https://img.shields.io/badge/Built%20for%20Windows%2010-Yes-blue?style=flat)](https://windows.com/ "Built for Windows 10")

[![PSScriptAnalyzer verified](https://img.shields.io/badge/PowerShell%20Script%20Analyzer%20verified-Yes-green?style=flat)](https://learn.microsoft.com/powershell/module/psscriptanalyzer/ "PowerShell Script Analyzer")
[![PowerShell Constrained Language mode verified](https://img.shields.io/badge/PowerShell%20Constrained%20Language%20mode%20verified-Yes-green?style=flat)](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_language_modes/ "PowerShell Language mode")
[![Strict Mode verified](https://img.shields.io/badge/Strict%20Mode%20verified-Yes-green?style=flat)](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/set-strictmode/ "Set-StrictMode -Version latest")

# Microsoft Intune remediation: Monitor Additional LSA Protection

The LSA, which includes the Local Security Authority Server Service (LSASS) process, validates users for local and remote sign-ins and enforces local security policies. The Windows operating system provides additional protection for the LSA to prevent reading memory and code injection by non-protected processes.

This provides added security for the credentials that the LSA stores and manages. When this setting is used in conjunction with Secure Boot, additional protection is achieved as disabling the HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Lsa registry post configuration key has no effect.

For more information, see [Configuring Additional LSA Protection](https://learn.microsoft.com/windows-server/security/credentials-protection-and-management/configuring-additional-lsa-protection "Configuring Additional LSA Protection").

The scripts will monitor and remediate the following registry values:

- HKLM\SYSTEM\CurrentControlSet\Control\Lsa\RunAsPPL, to the following REG_DWORD value: 1
- HKLM\SYSTEM\CurrentControlSet\Control\Lsa\DisableDomainCreds, to the following REG_DWORD value: 1

## Script package information

External logging: **No**

## Script package properties

### Basic

Name: **Monitor Additional LSA Protection settings**

Description: **Configuring Additional LSA Protection for Windows devices**

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
| `exit 0` | `[00.000] Additional LSA Protection properly configured (10)` |
| `exit 0` | `[00.000] Additional LSA Protection not available (32-bit)` |
| `exit 1` | `[00.000] Additional LSA Protection misconfigured (00)` |

### remediate.ps1

| Exit code | Output |
|:---------:|:-------|
| `exit 0` | `[00.000] Additional LSA Protection properly configured (10)` |
| `exit 1` | `[00.000] Configuring Additional LSA Protection settings (00)` |
