---
Title: README
Date: April 10, 2026
Author: dotjesper
Status: In development
---

[![Built for Windows 11](https://img.shields.io/badge/Built%20for%20Windows%2011-Yes-blue?style=flat)](https://windows.com/ "Built for Windows 11")

[![PSScriptAnalyzer verified](https://img.shields.io/badge/PowerShell%20Script%20Analyzer%20verified-Yes-green?style=flat)](https://learn.microsoft.com/powershell/module/psscriptanalyzer/ "PowerShell Script Analyzer")
[![PowerShell Constrained Language mode verified](https://img.shields.io/badge/PowerShell%20Constrained%20Language%20mode%20verified-Yes-green?style=flat)](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_language_modes/ "PowerShell Language mode")
[![Strict Mode verified](https://img.shields.io/badge/Strict%20Mode%20verified-Yes-green?style=flat)](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/set-strictmode/ "Set-StrictMode -Version latest")

# Custom compliance: Windows Config Refresh status

This custom compliance script package validates the Windows Config Refresh feature status on managed devices. Config Refresh is a security feature that periodically reapplies MDM policy settings to ensure device configuration drift is corrected automatically.

## Overview

The discovery script checks the following properties and returns them as a JSON object for compliance evaluation:

| Setting | Description |
|---------|-------------|
| **ConfigRefreshEnabled** | Whether Config Refresh is enabled in the device enrollment registry |
| **ConfigRefreshPaused** | Whether Config Refresh has been temporarily paused |
| **ScheduledTaskReady** | Whether the Config Refresh scheduled task is in a ready state |

## How it works

The script validates Config Refresh status through registry checks and scheduled task inspection:

1. The discovery script enumerates enrollment subkeys under `HKLM:\SOFTWARE\Microsoft\Enrollments\` and looks for a `ConfigRefresh` subkey
2. If Config Refresh is enabled (`Enabled = 1`), the script reports `ConfigRefreshEnabled = true`
3. If Config Refresh is paused (`PausePeriod > 0`), the script reports `ConfigRefreshPaused = true`
4. Unless paused, the script validates that the scheduled task under `\Microsoft\Windows\EnterpriseMgmtNonCritical\` is in a `Ready` state
5. The JSON output is evaluated against the compliance rules defined in `settings.json`

## Script package information

This package contains:

- **discovery.ps1** — The discovery script that evaluates Config Refresh status
- **settings.json** — The compliance rules definition for Microsoft Intune

External logging: **No**

## Script package properties

Configure the custom compliance script in the Microsoft Intune admin center using the values below.

### Basic

Name: **Custom Compliance - Config Refresh Status**

Description: **Validates Windows Config Refresh is enabled and the scheduled task is running properly.**

Publisher: **Jesper Nielsen**

### Settings

Run this script using the logged-on credentials: **No**

Enforce script signature check: **No**

Run script in 64-bit PowerShell: **Yes**

### Compliance rules

The following rules are defined in `settings.json`:

| Rule | Operator | Data type | Expected value |
|------|----------|-----------|----------------|
| ConfigRefreshEnabled | IsEquals | Boolean | true |
| ScheduledTaskReady | IsEquals | Boolean | true |

> [!Note]
> The `ConfigRefreshPaused` property is collected but not evaluated as a compliance rule. It is included in the JSON output for visibility and can be used for reporting via Microsoft Graph.

## Deployment

To deploy this custom compliance script package:

1. Sign in to the [Microsoft Intune admin center](https://go.microsoft.com/fwlink/?linkid=2109431)
2. Navigate to **Endpoint security** > **Device compliance** > **Scripts**
3. Select **Add** > **Windows 10 and later** and configure:
   - Upload the `discovery.ps1` script
   - Set script execution properties as documented above
4. Navigate to **Devices** > **Compliance** and create a new compliance policy
5. Under **Custom compliance**, select the uploaded discovery script
6. Upload the `settings.json` file
7. Assign the policy to your target device groups

> [!Important]
> Test this package in a non-production environment before deploying to production devices. Use a dedicated security group with a limited set of test devices, or apply an assignment filter to scope the policy during validation.

## Requirements

Config Refresh is a Windows 11 feature that requires specific updates. Windows 10 devices do not support Config Refresh.

- **Windows 11, version 21H2** with [KB5035854](https://support.microsoft.com/kb/5035854) (Build 10.0.22000.2836) or later
- **Windows 11, version 22H2** with [KB5034848](https://support.microsoft.com/kb/5034848) (Build 10.0.22621.3235) or later
- Devices enrolled in Microsoft Intune
- Microsoft Intune Management Extension installed
- Config Refresh feature configured via Settings Catalog
- PowerShell 5.1 or later

## Related documentation

For more information about Config Refresh and custom compliance in Microsoft Intune, see the following resources.

- [Config Refresh overview](https://learn.microsoft.com/mem/intune/configuration/config-refresh)
- [Use custom compliance settings in Microsoft Intune](https://learn.microsoft.com/mem/intune/protect/compliance-use-custom-settings)
- [Custom compliance discovery scripts](https://learn.microsoft.com/mem/intune/protect/compliance-custom-script)
- [Custom compliance JSON schema](https://learn.microsoft.com/mem/intune/protect/compliance-custom-json)
