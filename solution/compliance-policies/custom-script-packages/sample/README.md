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

# Custom compliance: Sample

Sample custom compliance package demonstrating the structure and conventions for Microsoft Intune custom compliance discovery scripts and settings files.

## Overview

The discovery script collects basic device hardware information and returns it as a JSON object. The compliance rules in `settings.json` evaluate the returned properties against expected values.

The discovery script checks the following properties:

| Setting | Description |
|---------|-------------|
| **BiosVersion** | The SMBIOS BIOS version reported by `Win32_BIOS` |
| **TPMChipPresent** | Whether a TPM chip is present on the device |
| **Manufacturer** | The device manufacturer reported by `Win32_ComputerSystem` |

## Script package information

This package contains:

- **discovery.ps1** — The discovery script that collects device data
- **settings.json** — The compliance rules definition for Microsoft Intune

External logging: **No**

> [!Note]
> The discovery script uses `Get-Tpm`, which requires administrator privileges. The script must run in SYSTEM context (logged-on credentials set to **No**).

## Script package properties

Configure the custom compliance script in the Microsoft Intune admin center using the values below.

### Basic

Name: **Sample custom compliance**

Description: **Sample custom compliance package demonstrating the custom compliance script structure.**

Publisher: **Jesper Nielsen**

### Settings

Run this script using the logged-on credentials: **No**

Enforce script signature check: **No**

Run script in 64-bit PowerShell: **Yes**

### Compliance rules

The following rules are defined in `settings.json`:

| Rule | Operator | Data type | Expected value |
|------|----------|-----------|----------------|
| BiosVersion | GreaterEquals | Version | 12.21.100 |
| TPMChipPresent | IsEquals | Boolean | true |
| Manufacturer | IsEquals | String | Microsoft Corporation |

## Working with multi-value compliance checks

The custom compliance `settings.json` schema supports only single-value operators such as `IsEquals`, `GreaterEquals`, and `LessThan`. There is no `IsIn` or `Contains` operator for matching against multiple allowed values.

When a compliance rule needs to validate against multiple acceptable values — for example, allowing devices from Microsoft, Lenovo, and Dell — move the validation logic into the discovery script. Return a computed boolean result instead of the raw value, and evaluate that boolean in `settings.json`.

For example, to allow multiple manufacturers, update the discovery script to compare the device manufacturer against an approved list:

```powershell
[array]$approvedManufacturers = @('Microsoft Corporation', 'LENOVO', 'Dell Inc.')
[bool]$approvedManufacturer = (Get-CimInstance -ClassName Win32_ComputerSystem).Manufacturer -in $approvedManufacturers
```

Then replace the `Manufacturer` rule in `settings.json` with a boolean check:

```json
{
  "SettingName": "ApprovedManufacturer",
  "Operator": "IsEquals",
  "DataType": "Boolean",
  "Operand": true,
  "MoreInfoUrl": "https://learn.microsoft.com/mem/intune/protect/compliance-custom-script",
  "RemediationStrings": [
    {
      "Language": "en_US",
      "Title": "Device manufacturer is not approved. Detected: {ActualValue}.",
      "Description": "Only Microsoft, Lenovo, and Dell devices are supported."
    }
  ]
}
```

This pattern applies to any compliance check where multiple values are acceptable — operating system editions, antivirus product names, or approved software versions.

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
> Test this package in a non-production environment before deploying to production devices. Use a dedicated security group with a limited set of test devices, or apply an assignment filter to scope the policy to specific hardware models or device names during validation.

## Related documentation

For more information about custom compliance in Microsoft Intune, see the following resources.

- [Use custom compliance settings in Microsoft Intune](https://learn.microsoft.com/mem/intune/protect/compliance-use-custom-settings)
- [Custom compliance discovery scripts](https://learn.microsoft.com/mem/intune/protect/compliance-custom-script)
- [Custom compliance JSON schema](https://learn.microsoft.com/mem/intune/protect/compliance-custom-json)
