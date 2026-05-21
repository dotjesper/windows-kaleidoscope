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

# Custom compliance: Windows hypervisor

This custom compliance script package validates that hardware virtualization is available on managed devices. Virtualization support is a prerequisite for security features such as Credential Guard, memory integrity (HVCI), and Windows Sandbox.

## Overview

The discovery script evaluates three conditions to determine whether virtualization is available, and returns a single computed boolean result:

| Check | Source | Description |
|-------|--------|-------------|
| VMMonitorModeExtensions | `Win32_Processor` | Whether the processor supports VM monitor mode extensions (Intel VT-x / AMD-V) |
| VirtualizationFirmwareEnabled | `Win32_Processor` | Whether virtualization is enabled in firmware (BIOS/UEFI) |
| HypervisorPresent | `Win32_ComputerSystem` | Whether a hypervisor is currently running |

The script reports `Virtualization = true` if either:

- The processor supports VM monitor mode extensions **and** virtualization is enabled in firmware, or
- A hypervisor is already present on the device

## Script package information

This package contains:

- **discovery.ps1** — The discovery script that evaluates virtualization availability
- **settings.json** — The compliance rules definition for Microsoft Intune

External logging: **No**

## Script package properties

Configure the custom compliance script in the Microsoft Intune admin center using the values below.

### Basic

Name: **Custom Compliance - Windows Hypervisor**

Description: **Validates that hardware virtualization is available on managed devices.**

Publisher: **Jesper Nielsen**

### Settings

Run this script using the logged-on credentials: **No**

Enforce script signature check: **No**

Run script in 64-bit PowerShell: **Yes**

### Compliance rules

The following rules are defined in `settings.json`:

| Rule | Operator | Data type | Expected value |
|------|----------|-----------|----------------|
| Virtualization | IsEquals | Boolean | true |

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

> [!Note]
> Devices running as virtual machines may report `HypervisorPresent = true` but `VMMonitorModeExtensions = false` depending on the host configuration and whether nested virtualization is enabled.

## Related documentation

For more information about virtualization-based security and custom compliance in Microsoft Intune, see the following resources.

- [Use custom compliance settings in Microsoft Intune](https://learn.microsoft.com/mem/intune/protect/compliance-use-custom-settings)
- [Custom compliance discovery scripts](https://learn.microsoft.com/mem/intune/protect/compliance-custom-script)
- [Custom compliance JSON schema](https://learn.microsoft.com/mem/intune/protect/compliance-custom-json)
- [Enable virtualization-based protection of code integrity](https://learn.microsoft.com/windows/security/hardware-security/enable-virtualization-based-protection-of-code-integrity)
