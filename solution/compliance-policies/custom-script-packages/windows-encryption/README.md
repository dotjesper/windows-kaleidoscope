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

# Custom compliance: Windows encryption

This custom compliance script package validates BitLocker Drive Encryption status on the system drive. Use this package to ensure devices are fully encrypted with an approved encryption method and key protector type.

## Overview

The discovery script collects the following properties from the system drive and returns them as a JSON object for compliance evaluation:

| Setting | Description |
|---------|-------------|
| **ProtectionStatus** | Whether BitLocker protection is active (`On` or `Off`) |
| **EncryptionMethod** | The encryption algorithm in use (e.g., `XtsAes128`, `XtsAes256`) |
| **KeyProtectorType** | The TPM-based key protector type (e.g., `Tpm`, `TpmPin`) |
| **VolumeStatus** | The encryption state of the volume (e.g., `FullyEncrypted`, `EncryptionInProgress`) |
| **PinProtectorEnabled** | Whether a TPM+PIN key protector is configured (`True` or `False`) |

## Script package information

This package contains:

- **discovery.ps1** — The discovery script that collects BitLocker encryption status
- **settings.json** — The compliance rules definition for Microsoft Intune

External logging: **No**

> [!Note]
> The discovery script uses `Get-BitLockerVolume`, which requires administrator privileges. The script must run in SYSTEM context (logged-on credentials set to **No**).

## Script package properties

Configure the custom compliance script in the Microsoft Intune admin center using the values below.

### Basic

Name: **Custom Compliance - Windows Encryption**

Description: **Validates BitLocker Drive Encryption status, encryption method, and key protector type on managed devices.**

Publisher: **Jesper Nielsen**

### Settings

Run this script using the logged-on credentials: **No**

Enforce script signature check: **No**

Run script in 64-bit PowerShell: **Yes**

### Compliance rules

The following rules are defined in `settings.json`:

| Rule | Operator | Data type | Expected value |
|------|----------|-----------|----------------|
| ProtectionStatus | IsEquals | String | On |
| KeyProtectorType | IsEquals | String | Tpm |
| EncryptionMethod | IsEquals | String | XtsAes128 |
| VolumeStatus | IsEquals | String | FullyEncrypted |
| PinProtectorEnabled | IsEquals | String | False |

> [!Note]
> The default `PinProtectorEnabled` rule expects `False`, which means a TPM+PIN pre-boot PIN is **not** required. If your organization requires a pre-boot PIN, change the `Operand` for `PinProtectorEnabled` to `True` and update `KeyProtectorType` to `TpmPin` in `settings.json`.

> [!Note]
> Adjust the other expected values to match your organization's encryption policy. For example, change `EncryptionMethod` to `XtsAes256` if your policy requires 256-bit encryption.

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

For more information about BitLocker and custom compliance in Microsoft Intune, see the following resources.

- [Use custom compliance settings in Microsoft Intune](https://learn.microsoft.com/mem/intune/protect/compliance-use-custom-settings)
- [Custom compliance discovery scripts](https://learn.microsoft.com/mem/intune/protect/compliance-custom-script)
- [Custom compliance JSON schema](https://learn.microsoft.com/mem/intune/protect/compliance-custom-json)
- [Encrypt Windows devices with BitLocker in Microsoft Intune](https://learn.microsoft.com/mem/intune/protect/encrypt-devices)
- [BitLocker overview](https://learn.microsoft.com/windows/security/operating-system-security/data-protection/bitlocker/)
