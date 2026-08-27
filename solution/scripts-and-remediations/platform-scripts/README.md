---
Title: README
Date: April 10, 2026
Author: dotjesper
Status: In development
---

# Platform scripts

Platform scripts are PowerShell scripts deployed via Microsoft Intune that run once on targeted devices. They can be used to perform custom actions during enrollment or device setup, such as configuring settings, collecting information, or preparing devices for specific scenarios.

## Overview

PowerShell platform scripts on Windows 10/11 devices are used sparingly in this repository. For most scenarios, packaging PowerShell scripts as Win32 apps is the preferred approach, because platform scripts have limitations in scope and reporting:

- The maximum script size is 200 KB (ASCII), which can be insufficient for complex or lengthy scripts.
- Scripts are restricted to a single PowerShell file with no support for multi-file packages.
- Error handling and reporting are limited compared to Win32 apps.
- Scripts execute once and do not re-run unless the script or policy changes.
- If a script fails, the Microsoft Intune Management Extension retries the script three times for the next three consecutive check-ins.
- Scripts time out after 30 minutes.

## Available scripts

This folder contains the following platform script packages:

| Folder | Description |
|--------|-------------|
| `device-preparation` | Windows Autopilot device preparation scripts for automated device configuration and Microsoft Defender Antivirus updates during enrollment |
| `sample-script` | Sample platform script demonstrating key patterns including logging, registry operations, and error handling |

## Execution behavior

Platform scripts follow a specific execution sequence within Microsoft Intune:

- PowerShell scripts execute before Win32 apps during enrollment.
- End users are not required to sign in to the device for scripts to execute.
- Scripts assigned to device groups run for every new user that signs in (except multi-session SKUs).
- After successful execution, the script does not run again unless the script or policy changes.
- Microsoft Intune platform scripts do not support passing parameters at execution time.

## Script conventions

All platform scripts in this repository follow a consistent structure and set of conventions:

- Scripts must work in PowerShell 5.1.
- Scripts use `begin`/`process`/`end` blocks with `[CmdletBinding()]`.
- Condition flags are declared in the `begin` block under `# variables :: Conditions`.
- Exit codes follow the Microsoft Intune convention: `exit 0` for success, `exit 1` for failure.
- All variables use explicit type declarations.
- Complex scripts include CMTrace-compatible logging to `%ProgramData%\Microsoft\IntuneManagementExtension\Logs\`.

## Related documentation

For more information about platform scripts and the Microsoft Intune Management Extension, see the following resources.

- [Use PowerShell scripts on Windows 10/11 devices in Microsoft Intune](https://learn.microsoft.com/mem/intune/apps/intune-management-extension)
- [Create a script policy and assign it](https://learn.microsoft.com/mem/intune/apps/intune-management-extension#create-a-script-policy-and-assign-it)
- [Microsoft Intune Management Extension prerequisites](https://learn.microsoft.com/mem/intune/apps/intune-management-extension#prerequisites)
