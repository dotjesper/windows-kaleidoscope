---
Title: README
Date: April 7, 2026
Author: dotjesper
Status: In development
---

# Custom compliance script packages

Custom compliance script packages extend Microsoft Intune compliance policies with custom detection logic. Each package contains a PowerShell discovery script and a `settings.json` file that defines the compliance rules evaluated against the script output.

## How custom compliance works

Custom compliance settings in Microsoft Intune use a discovery script to collect device data and a settings file to define the expected values. The discovery script returns a JSON object, and each rule in the settings file evaluates a property from that object.

For more information, see the following Microsoft Learn resources:

- [Use custom compliance settings in Microsoft Intune](https://learn.microsoft.com/mem/intune/protect/compliance-use-custom-settings "Use custom compliance settings in Microsoft Intune")
- [Custom compliance discovery scripts](https://learn.microsoft.com/mem/intune/protect/compliance-custom-script "Custom compliance discovery scripts")
- [Custom compliance JSON schema](https://learn.microsoft.com/mem/intune/protect/compliance-custom-json "Custom compliance JSON schema")

## Available packages

The following custom compliance script packages are available:

| Package | Description |
|:--------|:------------|
| `sample` | Sample package demonstrating the custom compliance script structure |
| `windows-config-refresh` | Sample package demonstrating configuration refresh |
| `windows-edition` | Validates the Windows edition and operating system SKU |
| `windows-encryption` | Validates the BitLocker encryption method |
| `windows-hypervisor` | Validates hypervisor presence and configuration |

## Package structure

Each custom compliance script package contains the following files:

| File | Purpose |
|:-----|:--------|
| `discovery.ps1` | PowerShell script that collects device data and returns JSON output |
| `settings.json` | Rule definitions that evaluate properties from the discovery script output |
| `README.md` | Package documentation |
