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

# Microsoft Intune remediation: Monitor Interactive Logon Message

Interactive Logon Message is a Windows security feature that displays a legal notice or informational message before users sign in. The configuration is managed through Local Policies: Security Options, using the following two settings:

- Interactive Logon Message Title For Users Attempting To Log On
- Interactive Logon Message Text For Users Attempting To Log On

When managed through Group Policy, removing the policy might fail to remove the tattooed registry settings. This remediation package monitors whether Interactive Logon Message values are configured and clears them if present.

For more information, see [Interactive logon: Message title for users attempting to log on](https://learn.microsoft.com/windows/security/threat-protection/security-policy-settings/interactive-logon-message-title-for-users-attempting-to-log-on "Interactive logon: Message title for users attempting to log on").

The scripts monitor and remediate the following registry values:

- HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\LegalNoticeCaption, to the following REG_SZ value: (empty)
- HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\LegalNoticeText, to the following REG_SZ value: (empty)

## Script package information

External logging: **No**

## Script package properties

### Basic

Name: **Monitor Interactive Logon Message**

Description: **Monitor and clear Interactive Logon Message configurations for Windows devices**

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
| `exit 0` | `[00.000] Interactive Logon Message values not configured.` |
| `exit 0` | `[00.000] Interactive Logon Message configurations not found.` |
| `exit 1` | `[00.000] Interactive Logon Message found: LegalNoticeCaption='Warning', LegalNoticeText='Unauthorized access prohibited.'` |
