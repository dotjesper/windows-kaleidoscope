---
Title: README
Date: Juni 14, 2024
Author: dotjesper
Status: In development
---

[![Built for Windows 11](https://img.shields.io/badge/Built%20for%20Windows%2011-Yes-blue?style=flat)](https://windows.com/ "Built for Windows 11")
[![Built for Windows 10](https://img.shields.io/badge/Built%20for%20Windows%2010-Yes-blue?style=flat)](https://windows.com/ "Built for Windows 10")
[![Built for Windows Autopilot](https://img.shields.io/badge/Built%20for%20Windows%20Autopilot-Yes-blue?style=flat)](https://learn.microsoft.com/mem/autopilot/windows-autopilot/ "Windows Autopilot")

[![PSScriptAnalyzer verified](https://img.shields.io/badge/PowerShell%20Script%20Analyzer%20verified-Yes-green?style=flat)](https://learn.microsoft.com/powershell/module/psscriptanalyzer/ "PowerShell Script Analyzer")
[![PowerShell Constrained Language mode verified](https://img.shields.io/badge/PowerShell%20Constrained%20Language%20mode%20verified-No-green?style=flat)](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_language_modes/ "PowerShell Language mode")
[![Strict Mode verified](https://img.shields.io/badge/Strict%20Mode%20verified-Yes-green?style=flat)](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/set-strictmode/ "Set-StrictMode -Version latest")

# Microsoft Intune remediation: Collect browser extensions

The detection script will collect and upload browser extension installed, to Log Analytics in Azure Monitor.

Collecting browser extensions for the following browsers;
- Microsoft Edge
- Google Chrome
- Mozilla Firefox

Extensions are collected for all user profiles in browsers, and can result in extensions is reported multiple times due to the nature of the browsers handle extensions.
The script will collect the following information for each extension;
- Browser       : Browser name
- Author        : Extension author
- Name          : Extension name
- Description   : Extension description
- Version       : Extension version
- Update URL    : Extension update URL
- Path          : Extension path
- Extension ID  : Extension ID
- Source URI    : Extension URI (Firefox only)
- Profile       : Browser Profile name
- User          : User name
- Computer      : Computer name

Extensions are collected for all user profiles in the above browsers, and can result in extensions is reported multiple times, due to the nature of how browsers handle extensions.

> Script tested on Microsoft Edge and Google Chrome version 102+.

## Script package information

External logging: **no**

## Prerequisites

This script requires a Log Analytics workspace to receive the collected data. To obtain the WorkspaceId and SharedKey:

1. In the [Azure portal](https://portal.azure.com), navigate to your Log Analytics workspace
2. Select **Agents** under **Settings**
3. Copy the **Workspace ID** and **Primary key** values
4. Replace the `WorkspaceId` and `SharedKey` parameter defaults in the script

The script creates a custom table using the `TableName` parameter value (default: `browserExtensions`). The table appears in Log Analytics with a `_CL` suffix (e.g., `browserExtensions_CL`).

To run the script without sending data to Log Analytics, use the `-SkipUpload` switch.

## Script package properties

### Basic

Name: **Collect browser extensions**

Description: **Collect browser extensions installed in Microsoft Edge and/or Google Chrome, collected extensions are uploaded to Log Analytics in Azure Monitor.**

Publisher: **Jesper Nielsen**

### Settings

Detection script: **Yes**

Remediation script: **No**

Run this script using the logged-on credentials: **Yes**

Enforce script signature check: **No**

Run script in 64-bit PowerShell: **Yes**

### Assignments

Schedule: **Weekly**

## Expected output

### detect.ps1

| Exit code | Output |
|:---------:|:-------|
| `exit 0` | `[00.000] Collected information for 12 extensions.` |
| `exit 0` | `[00.000] No extensions found.` |

## KQL query examples for collected data

The following KQL queries can be used to analyze collected browser extension data in Log Analytics.

List all distinct extensions by name, description, and extension ID:

```kql
browserExtensions_CL
| where name_s !startswith "__MSG_"
| distinct name_s, description_s, extensionId_s
```

Count the number of unique extension names across all devices:

```kql
browserExtensions_CL
| summarize names = dcount(name_s)
```

List all collected browser extension records:

```kql
browserExtensions_CL
| distinct *
```

Drop all data from the custom table for cleanup or testing purposes:

```kql
.drop extents from browserExtensions_CL
```

For more information, see [Delete data in Azure Data Explorer](https://learn.microsoft.com/azure/data-explorer/delete-data).

## Future improvements

Future improvements planned for this package:

**Migrate to the Logs Ingestion API.** The HTTP Data Collector API used by this script is [deprecated](https://learn.microsoft.com/azure/azure-monitor/logs/data-collector-api). The modern replacement is the Logs Ingestion API with Data Collection Rules (DCR) and Data Collection Endpoints (DCE). This would replace the shared key authentication with Microsoft Entra ID app registration, provide scoped write permissions, and use a defined schema via DCR instead of the `_CL` suffix convention.
