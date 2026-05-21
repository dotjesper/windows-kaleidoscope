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

# Custom compliance: Windows edition

This custom compliance script package validates the Windows edition (operating system SKU) and OS architecture on managed devices. Use this package to ensure devices run an approved Windows edition, such as Enterprise, and a required architecture.

## Overview

The discovery script collects the following properties from the device and returns them as a JSON object for compliance evaluation:

| Setting | Description |
|---------|-------------|
| **WindowsEdition** | The operating system SKU as an integer, reported by `Win32_OperatingSystem` |
| **OSArchitecture** | The OS architecture string (e.g., `64-bit`), reported by `Win32_OperatingSystem` |

### Common Windows edition SKU values

The `OperatingSystemSKU` property returns an integer that identifies the Windows edition. Common values used in enterprise environments:

| SKU | Edition |
|----:|:--------|
| 4 | Windows Enterprise |
| 27 | Windows Enterprise N |
| 48 | Windows Professional |
| 49 | Windows Professional N |
| 72 | Windows Enterprise Evaluation |
| 125 | Windows Enterprise (LTSC) |
| 175 | Windows 365 Enterprise |

For a complete list, see [OperatingSystemSKU values](https://learn.microsoft.com/windows/win32/cimwin32prov/win32-operatingsystem).

## Script package information

This package contains:

- **discovery.ps1** — The discovery script that collects Windows edition and architecture
- **settings.json** — The compliance rules definition for Microsoft Intune

External logging: **No**

## Script package properties

Configure the custom compliance script in the Microsoft Intune admin center using the values below.

### Basic

Name: **Custom Compliance - Windows Edition**

Description: **Validates the Windows edition (SKU) and OS architecture on managed devices.**

Publisher: **Jesper Nielsen**

### Settings

Run this script using the logged-on credentials: **No**

Enforce script signature check: **No**

Run script in 64-bit PowerShell: **Yes**

### Compliance rules

The following rules are defined in `settings.json`:

| Rule | Operator | Data type | Expected value |
|------|----------|-----------|----------------|
| WindowsEdition | IsEquals | Int64 | 4 |
| OSArchitecture | Contains | String | 64-bit |

> [!Note]
> The default `WindowsEdition` rule expects SKU `4` (Windows Enterprise). Update the `Operand` value in `settings.json` to match the Windows edition required in your environment.

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

## Related documentation

For more information about custom compliance and Windows edition identifiers, see the following resources.

- [Use custom compliance settings in Microsoft Intune](https://learn.microsoft.com/mem/intune/protect/compliance-use-custom-settings)
- [Custom compliance discovery scripts](https://learn.microsoft.com/mem/intune/protect/compliance-custom-script)
- [Custom compliance JSON schema](https://learn.microsoft.com/mem/intune/protect/compliance-custom-json)
- [Win32_OperatingSystem class](https://learn.microsoft.com/windows/win32/cimwin32prov/win32-operatingsystem)
