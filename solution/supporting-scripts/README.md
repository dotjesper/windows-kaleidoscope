---
Title: README
Date: April 13, 2026
Author: dotjesper
Status: In development
---

# Supporting scripts

[![Built for Windows 11](https://img.shields.io/badge/Built%20for%20Windows%2011-Yes-blue?style=flat)](https://windows.com/ "Built for Windows 11")
[![Built for Windows 10](https://img.shields.io/badge/Built%20for%20Windows%2010-Yes-blue?style=flat)](https://windows.com/ "Built for Windows 10")

Supporting scripts are utility and reporting scripts that complement the main solution. These scripts are meant to help with common tasks or challenges that you might encounter while working with Microsoft Intune remediations. They are not essential for the functionality of the project, but they can save time and simplify administrative workflows.

> [!IMPORTANT]
> Do not run these scripts from PowerShell ISE.

Before using any of the supporting scripts, make sure you have the latest version of the repository and that you have installed any required dependencies.

These scripts are provided as a convenience and are not thoroughly tested or guaranteed to work in all situations. Use them at your own risk and always back up your data before making any changes. If you encounter any issues or bugs with the scripts, please report them on the repository's [issue tracker](https://github.com/dotjesper/windows-kaleidoscope/issues "Report an issue").

## Script: Invoke-RemediationReport.ps1

The `Invoke-RemediationReport.ps1` script connects to Microsoft Graph, fetches organization metadata, and reads remediation packages. The script checks for the presence of required modules and exits if they are not found. It then attempts to connect to Microsoft Graph, either with a specified TenantId or without. If the connection is successful, it fetches the organization metadata from Microsoft Graph.

[![PSScriptAnalyzer verified](https://img.shields.io/badge/PowerShell%20Script%20Analyzer%20verified-Yes-green?style=flat)](https://learn.microsoft.com/powershell/module/psscriptanalyzer/ "PowerShell Script Analyzer")
[![PowerShell Constrained Language mode verified](https://img.shields.io/badge/PowerShell%20Constrained%20Language%20mode%20verified-Not%20Supported-red?style=flat)](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_language_modes/ "PowerShell Language mode")
![Signed](https://img.shields.io/badge/Signed-No-red?style=flat)

### Examples

The following examples demonstrate common ways to run the `Invoke-RemediationReport.ps1` script.

```powershell
# Description: Run the remediation report with default settings
# Elevation is not required - Microsoft Graph authentication handles permissions

.\Invoke-RemediationReport.ps1
```

```powershell
# Description: Run the remediation report with HTML output and install required components
# Elevation is not required - Microsoft Graph authentication handles permissions

.\Invoke-RemediationReport.ps1 -scriptPackageOutputType "html" -installRequiredComponents $true
```

### Parameters

For a full list of available parameters, run the `Get-Help` command:

```powershell
# Description: Display help for the Invoke-RemediationReport script
# Elevation is not required

Get-Help -Name .\Invoke-RemediationReport.ps1
```

### Functional description

The functional description of the `Invoke-RemediationReport.ps1` script covers the following steps:

1. **Module check** - The script starts by checking if the required module is present. If the module is not found, it outputs a message and exits.
1. **Connecting to Microsoft Graph** - The script attempts to connect to Microsoft Graph. If a TenantId is provided, it uses that for the connection. If not, it connects without specifying a TenantId. If the user cancels the authentication, the script exits.
1. **Fetching organization metadata** - If the connection to Microsoft Graph is successful, the script fetches the organization metadata using a GET request to the Microsoft Graph API.
1. **Setting internal variables** - The script sets up internal variables using the fetched organization metadata, including the TenantId, tenant display name, and an array for storing device health script remediation details.
1. **Reading remediation packages** - The script prepares for reading remediation packages by setting up the Microsoft Graph URL and API version.

### Script output

The script handles the output of remediation package details in the following steps:

1. **Checking remediation details** - The script checks if there are any remediation details to process. If there are none, it outputs a message and suggests checking if any device health script packages have been assigned and are active.
1. **Opening grid view** - If there are remediation details to process, the script opens these details in a grid view.
1. **Selecting rows** - The script allows the user to select one or more rows from the grid view. If no rows are selected, it outputs a message to inform the user.
1. **Exporting selected rows** - If any rows are selected, the script exports them to either a CSV or HTML file, depending on the specified output type.

### Revision history

The revision history tracks changes and updates to the `Invoke-RemediationReport.ps1` script.

- **1.0.0** - April 7, 2026 - Script rewrite, renamed parameters, new features, Windows 11 25H2 support
- **0.9.4** - June 19, 2024 - Updated to support Windows 11 24H2, script improvements
- **0.9.0** - June 19, 2024 - Updated to support Microsoft Graph, script improvements
- **0.8.7** - October 24, 2023 - Updated to support Windows 11 23H2, minor bug fixes
- **0.8.0** - September 4, 2023 - Conceptual preview
