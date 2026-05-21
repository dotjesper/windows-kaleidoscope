---
Title: README
Date: April 7, 2026
Author: dotjesper
Status: In development
---

# Microsoft Intune remediation scripts

Remediations are script packages that can detect and fix common support issues on a user's device before they even realize there is a problem. Remediations can help reduce support calls and improve the user experience by automating tasks such as clearing the cache, resetting the network settings, or updating the Endpoint Security definition files.

You can use Microsoft Intune to create and assign remediation script packages, which are collections of scripts that run on a schedule or on demand. You can also monitor the status and results of the remediation scripts in the Microsoft Intune admin center.

To use remediations, you need a Windows device enrolled in Microsoft Intune with the Microsoft Intune Management Extension installed.

To write remediation scripts, you need to have basic knowledge of PowerShell and follow the [Development Best Practices and guidelines](https://learn.microsoft.com/powershell/scripting/developer/cmdlet/strongly-encouraged-development-guidelines "Strongly Encouraged Development Guidelines - PowerShell 5.1") provided by Microsoft.

> [!IMPORTANT]
> Proactive Remediations has been renamed to Remediations and is now available from Microsoft Intune > Devices > Manage devices > Scripts and remediations.

For more information about using PowerShell remediations scripts on Windows 10/11 devices, see [Remediations](https://learn.microsoft.com/mem/intune/fundamentals/remediations/ "Remediations").

## Script requirements

Remediation scripts must meet the following requirements:

- You can have up to 200 script packages.
- Ensure the scripts are encoded in UTF-8 (not UTF-8 BOM).
- The maximum allowed output size limit is 2048 characters.
- A script package can contain a detection script only or both a detection script and a remediation script.
- Do not put secrets in scripts. Consider using parameters to handle secrets instead.
- Do not put reboot commands in detection or remediation scripts.

For more information about script requirements, see [Script requirements](https://learn.microsoft.com/mem/intune/fundamentals/remediations#script-requirements "Remediations").

If the option **Enforce script signature check** is enabled in the Script Package Settings page of creating a script package, the script runs using the device's PowerShell execution policy. The default execution policy for Windows client computers is **Restricted**. For more information, see [PowerShell execution policies](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_execution_policies/ "PowerShell execution policies").

- Signing remediation scripts and enabling **Enforce script signature check** is highly recommended. Make sure the certificate is in the **Trusted Publishers** certificate store. As with any certificate, the certificate authority must be trusted by the device.
- Scripts without **Enforce script signature check** use the **Bypass** execution policy.

## Licensing

Remediations require users of the devices to hold one of the following licenses:

- Windows 10/11 Enterprise E3 or E5 (included in Microsoft 365 F3, E3, or E5)
- Windows 10/11 Education A3 or A5 (included in Microsoft 365 A3 or A5)
- Windows 10/11 Virtual Desktop Access (VDA) per user

## Repository naming

All remediation script packages follow a naming convention with a prefix that indicates the package type:

| Prefix | Purpose | Contains |
|:-------|:--------|:---------|
| `collect-*` | Data collection for non-remediable information (e.g., battery health, firmware data) | `detect.ps1` only |
| `invoke-*` | One-time management actions or on-demand remediations | `detect.ps1` + `remediate.ps1` |
| `monitor-*` | Ongoing monitoring of remediable settings (e.g., registry values, folders, files) | `detect.ps1` + `remediate.ps1` |

## Create a script policy and assign it

The Microsoft Intune Management Extension service gets the scripts from Microsoft Intune and runs them. To deploy script packages, follow the instructions at [Create and assign remediation scripts](https://learn.microsoft.com/mem/intune/fundamentals/remediations "Remediations").

## Monitor remediation status for a device

You can view the status of remediations that are assigned or run on-demand to a device:

1. Sign in to the [Microsoft Intune admin center](https://go.microsoft.com/fwlink/?linkid=2109431 "Microsoft Intune admin center").
2. Navigate to Devices > By platform > Windows > select a supported device.
3. Select Remediations in the Monitor section.

Alternatively, you can use the PowerShell script `Invoke-RemediationReport.ps1`, designed to connect to Microsoft Graph and help you find, analyze, and export returned outputs. Save the output as a `.csv` or `.html` file. Find the script in the [supporting-scripts](../../supporting-scripts) folder.
