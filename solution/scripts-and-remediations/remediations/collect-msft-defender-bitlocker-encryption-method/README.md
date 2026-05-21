---
Title: README
Date: June 3, 2021
Author: dotjesper
Status: In development
---

[![Built for Windows 11](https://img.shields.io/badge/Built%20for%20Windows%2011-Yes-blue?style=flat)](https://windows.com/ "Built for Windows 11")
[![Built for Windows 10](https://img.shields.io/badge/Built%20for%20Windows%2010-Yes-blue?style=flat)](https://windows.com/ "Built for Windows 10")
[![Built for Windows Autopilot](https://img.shields.io/badge/Built%20for%20Windows%20Autopilot-Yes-blue?style=flat)](https://learn.microsoft.com/mem/autopilot/windows-autopilot/ "Windows Autopilot")

[![PSScriptAnalyzer verified](https://img.shields.io/badge/PowerShell%20Script%20Analyzer%20verified-Yes-green?style=flat)](https://learn.microsoft.com/powershell/module/psscriptanalyzer/ "PowerShell Script Analyzer")
[![PowerShell Constrained Language mode verified](https://img.shields.io/badge/PowerShell%20Constrained%20Language%20mode%20verified-Yes-green?style=flat)](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_language_modes/ "PowerShell Language mode")
[![Strict Mode verified](https://img.shields.io/badge/Strict%20Mode%20verified-Yes-green?style=flat)](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/set-strictmode/ "Set-StrictMode -Version latest")

# Microsoft Intune remediation: Collect Microsoft Defender BitLocker encryption method

Collect Microsoft Defender BitLocker encryption method for System drive, fails if encryption differs from requirements.

Encryption Method values:

```text
3: AES-CBC 128-bit
4: AES-CBC 256-bit
6: XTS-AES 128-bit (default)
7: XTS-AES 256-bit
```

## Script package information

Required Encryption Method: **6**

External logging: **No**

## Script package properties

### Basic

Name: **Collect Microsoft Defender BitLocker encryption method**

Description: **Collect Microsoft Defender BitLocker encryption method for System drive, fails if encryption differs from XTS-AES 128-bit.**

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
| `exit 0` | `[00.000] Microsoft Defender BitLocker Drive encryption method for System drive compliant (6)` |
| `exit 1` | `[00.000] Microsoft Defender BitLocker Drive encryption method for System drive non-compliant (3)` |
