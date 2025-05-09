# Supporting Scripts

These scripts are meant to help you with some common tasks or challenges that you might encounter while working with the main codebase. They are not essential for the functionality of the project, but they can make your life easier and save you some time.

You can run them from the command line or from your preferred IDE. Each script has a descriptive name and a comment at the top explaining its purpose and usage. Some scripts may require additional arguments or parameters, which you can find out by running the script with the -h or --help flag.

> [!IMPORTANT]
> Do not run these scripts from PowerShell ISE!

Before using any of the supporting scripts, please make sure that you have the latest version of the repository and that you have installed any required dependencies.

Please note:

- These scripts are not meant to be complete or final solutions, but rather proof of concept or functional exploration of some ideas or techniques that might be useful for the project. They are intended to demonstrate some possibilities and inspire further development and improvement.
- These scripts are provided as a convenience and are not thoroughly tested or guaranteed to work in all situations. Use them at your own risk and always backup your data before making any changes. If you encounter any issues or bugs with the scripts, please report them on the repository's issue tracker or contact the author.

## Script: Invoke-RemediationReport.ps1

This PowerShell script is designed to connect to Microsoft Graph, fetch organization metadata, and prepare for reading remediation packages. The script first checks for the presence of required modules and exits if they are not found. It then attempts to connect to Microsoft Graph, either with a specified TenantId or without. If the connection is successful, it fetches the organization metadata from Microsoft Graph. The script also sets up some internal variables for later use.

[![PSScriptAnalyzer verified](https://img.shields.io/badge/PowerShell%20Script%20Analyzer%20verified-Yes-green?style=flat)](https://learn.microsoft.com/powershell/module/psscriptanalyzer/ "PowerShell Script Analyzer")
[![PowerShell Constrained Language mode verified](https://img.shields.io/badge/PowerShell%20Constrained%20Language%20mode%20verified-Not%20Supported-red?style=flat)](https://docs.microsoft.com/powershell/module/microsoft.powershell.core/about/about_language_modes/ "PowerShell Language mode")
![Signed](https://img.shields.io/badge/Signed-No-red?style=flat)

### Examples

```PowerShell
.\Invoke-RemediationReport.ps1

.\Invoke-RemediationReport.ps1 -$scriptPackageOutputType "htmL" -installRequiredComponents $true
```

### Parameters

For a full list of avaliable parameters, please run the `get-help` command.

```PowerShell
get-help -name .\Invoke-RemediationReport.ps1
```

### Functional Description

1. **Module Check**: The script starts by checking if a required module is present. If the module is not found, it outputs a message and exits.
2. **Connecting to Microsoft Graph**: The script attempts to connect to Microsoft Graph. If a TenantId is provided, it uses that for the connection. If not, it connects without specifying a TenantId. If the user cancels the authentication, the script outputs a message and exits.
3. **Fetching Organization Metadata**: If the connection to Microsoft Graph is successful, the script fetches the organization metadata using a GET request to the Microsoft Graph API.
4. **Setting Internal Variables**: The script sets up some internal variables using the fetched organization metadata. These variables include the TenantId, tenantDisplayName, and an array for storing device health script remediation details.
5. **Reading Remediation Packages**: The script prepares for reading remediation packages by setting up the Microsoft Graph URL and API version.

### Script Output

This PowerShell script section is responsible for handling the output of remediation package details. It first checks if there are any remediation details to process. If there are, it opens these details in a grid view and allows the user to select one or more rows. The selected rows are then exported to either a CSV or HTML file, depending on the specified output type. If no rows are selected, it outputs a message to inform the user. If there are no remediation details to process, it outputs a message to inform the user and suggests checking if any device health script packages have been assigned and are active.

1. **Checking Remediation Details**: The script first checks if there are any remediation details to process. If there are, it proceeds to the next step. If not, it outputs a message to inform the user and suggests checking if any device health script packages have been assigned and are active.
2. **Opening Grid View**: If there are remediation details to process, the script opens these details in a grid view and outputs a message indicating the number of rows opened.
3. **Selecting Rows**: The script allows the user to select one or more rows from the grid view. If any rows are selected, it proceeds to the next step. If no rows are selected, it outputs a message to inform the user.
4. **Exporting Selected Rows**: If any rows are selected, the script exports these rows to either a CSV or HTML file, depending on the specified output type. It outputs a message indicating the number of rows exported and the location of the exported file.

The script outputs various messages at different stages:

1. **Checking Remediation Details**: If there are no remediation details to process, the script outputs a message indicating this and suggests checking if any device health script packages have been assigned and are active.
2. **Opening Grid View**: If there are remediation details to process, the script outputs a message indicating the number of rows opened in the grid view.
3. **Selecting Rows**: If no rows are selected from the grid view, the script outputs a message indicating this.
4. **Exporting Selected Rows**: If any rows are selected, the script outputs a message indicating the number of rows exported and the location of the exported file.

### Revision

Creation date: September 4, 2023
- Purpose/Change 0.8.0: Conceptual preview

Editig date: October 24, 2023
- Purpose/Change 0.8.7: Updated to support Windows 11 23H2 & minor bug fixes

Editig date: June 19, 2024
- Purpose/Change 0.9.0: Updated to support MgGraph & script improvements
- Purpose/Change 0.9.4: Updated to support Windows 11 24H2 & script improvements
