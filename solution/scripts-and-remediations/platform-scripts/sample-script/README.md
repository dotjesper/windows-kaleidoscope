---
Title: README
Date: April 10, 2026
Author: dotjesper
Status: In development
---

[![Built for Windows 11](https://img.shields.io/badge/Built%20for%20Windows%2011-Yes-blue?style=flat)](https://windows.com/ "Built for Windows 11")
[![Built for Windows 10](https://img.shields.io/badge/Built%20for%20Windows%2010-Yes-blue?style=flat)](https://windows.com/ "Built for Windows 10")
[![Built for Windows Autopilot](https://img.shields.io/badge/Built%20for%20Windows%20Autopilot-Yes-blue?style=flat)](https://learn.microsoft.com/mem/autopilot/windows-autopilot/ "Windows Autopilot")

[![PSScriptAnalyzer verified](https://img.shields.io/badge/PowerShell%20Script%20Analyzer%20verified-Yes-green?style=flat)](https://learn.microsoft.com/powershell/module/psscriptanalyzer/ "PowerShell Script Analyzer")
[![PowerShell Constrained Language mode verified](https://img.shields.io/badge/PowerShell%20Constrained%20Language%20mode%20verified-Yes-green?style=flat)](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_language_modes/ "PowerShell Language mode")
[![Strict Mode verified](https://img.shields.io/badge/Strict%20Mode%20verified-Yes-green?style=flat)](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/set-strictmode/ "Set-StrictMode -Version latest")

# Microsoft Intune platform script: Hello Intune

Sample platform script demonstrating key patterns for Microsoft Intune platform scripts, including CMTrace-compatible logging, registry operations, CimInstance queries, file system checks, condition flags, and standardized error handling.

## Overview

This script serves as a reference implementation for building platform scripts in this repository. It demonstrates:

- Environment logging with CMTrace-compatible log format
- Registry read operations using the split root/path pattern
- Operating system information queries via `Get-CimInstance`
- File system checks with `Test-Path` and `Get-ChildItem`
- All three log severity levels (informational, warning, error)
- Elapsed time tracking for runtime measurement
- Condition flags for 64-bit PowerShell and user context validation

## Parameters

The script accepts the following optional parameters.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-doFail` | Bool | `$false` | If set to `$true`, the script exits with code 1 to simulate a failed execution |

## Usage examples

Run the script locally for testing before deploying via Microsoft Intune.

```powershell
# Default execution
.\helloIntune.ps1

# Simulate a failure
.\helloIntune.ps1 -doFail $true

# Run with verbose output
.\helloIntune.ps1 -Verbose
```

## Script package information

The following settings describe the script package configuration for Microsoft Intune.

External logging: **Yes**

## Script package properties

Configure the platform script in the Microsoft Intune admin center using the values below.

### Basic

Name: **Hello Intune**

Description: **Sample platform script demonstrating key patterns for Microsoft Intune platform scripts.**

Publisher: **Jesper Nielsen**

### Settings

Script file: **helloIntune.ps1**

Run this script using the logged-on credentials: **Yes**/**No**

Enforce script signature check: **Yes**/**No**

Run script in 64-bit PowerShell: **Yes**/**No**

### Assignments

Assign to: **Test device group**

## Logging

The script writes CMTrace-compatible log entries that can be viewed with CMTrace or any text editor. All log entries include UTC offset, process ID, component name, and severity level. Log file location:

```text
%ProgramData%\Microsoft\IntuneManagementExtension\Logs\helloIntune.log
```

The default log path writes to `%ProgramData%`, which requires administrative privileges. When running the script in user context, change the `$logFilePath` variable in the `begin` block to a user-writable location:

```powershell
[string]$logFilePath = "$($Env:TEMP)\helloIntune.log"
```

Microsoft Intune platform scripts do not support passing parameters at execution time. To change the log file path, edit the variable directly in the script before uploading it to Microsoft Intune.

## Deployment

Deploy this script as a Microsoft Intune platform script to run once on targeted devices. Platform scripts execute before Win32 apps during enrollment and do not re-run unless the script or policy changes.

To deploy this platform script:

1. Sign in to the [Microsoft Intune admin center](https://go.microsoft.com/fwlink/?linkid=2109431)
2. Navigate to **Devices** > **Scripts and remediations** > **Platform scripts**
3. Select **Add** > **Windows 10 and later**
4. In **Basics**, enter the name and description as documented above
5. In **Script settings**, upload the `.ps1` file and configure settings as documented above
6. In **Assignments**, assign to the target device or user group

> [!Important]
> Test this script in a non-production environment before deploying to production devices.

## Related documentation

For more information about platform scripts and the Microsoft Intune Management Extension, see the following resources.

- [Use PowerShell scripts on Windows 10/11 devices in Microsoft Intune](https://learn.microsoft.com/mem/intune/apps/intune-management-extension)
