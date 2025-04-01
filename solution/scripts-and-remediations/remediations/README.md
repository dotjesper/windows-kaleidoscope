# Microsoft Intune Remediation Scripts

Remediations are script packages that can detect and fix common support issues on a user's device before they even realize there's a problem. Remediations can help reduce support calls. Remediations can be used to automate tasks such as clearing the cache, resetting the network settings, or updating the Endpoint Security definition files. Remediations can help you reduce the number of support tickets and improve the user experience.

You can use Microsoft Intune to create and assign remediation script packages, which are collections of scripts that run on a schedule or on demand. You can also monitor the status and results of the remediation scripts on the Intune portal.

To use remediations, you need a Windows device enrolled in Micrsoft Intune and installed the Microsoft Intune Management Extension.

To write remediation scripts, you need to have basic knowledge of PowerShell and follow the [Development Best Practices and guidelines](https://learn.microsoft.com/powershell/scripting/developer/cmdlet/strongly-encouraged-development-guidelines?view=powershell-5.1 "Strongly Encouraged Development Guidelines - PowerShell 5.1") provided by Microsoft.

> [!Important]
> Proactive Remediations is renamed to Remediations and is now available from Microsoft Intune > Devices > Manage devices > Scripts and remediations.

To read more about how to Use PowerShell Remediations scripts on Windows 10/11 devices, go [here](https://learn.microsoft.com/mem/intune/fundamentals/remediations/ "Remediations").

## Script requirements

- You can have up to 200 script packages.
- Ensure the scripts are encoded in UTF-8 (not UTF-8 BOM).
- The maximum allowed output size limit is 2048 characters.
- A script package can contain a detection script only or both a detection script and a remediation script.
- Don't put secrets in scripts. Consider using parameters to handle secrets instead.
- Don't put reboot commands in detection or remediations scripts.

Read more about Script requirements [here](https://learn.microsoft.com/en-us/mem/intune/fundamentals/remediations#script-requirements/ "Remediations").

If the option **Enforce script signature check** is enabled in the Script Package Settings page of creating a script package, the script runs using the device's PowerShell execution policy. The default execution policy for Windows client computers is **Restricted**. For more information, see [PowerShell execution policies](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_execution_policies/ "PowerShell execution policies").

- I highly recommend signing your Remediation scripts and **Enforce script signature check**, however make sure the certificate is in the **Trusted Publishers** certificate store. As with any certificate, the certificate authority must be trusted by the device.
- Scripts without **Enforce script signature check** use the **Bypass** execution policy.

## Licensing

Remediations requires users of the devices to have one of the following licenses:

- Windows 10/11 Enterprise E3 or E5 (included in Microsoft 365 F3, E3, or E5)
- Windows 10/11 Education A3 or A5 (included in Microsoft 365 A3 or A5)
- Windows 10/11 Virtual Desktop Access (VDA) per user

## Repository naming

All **Remediations** script packages are either **Collect**, **Manage** or **Monitor** packages.

- **Collect** packages contains detection script only and is used for *collecting* non-remediable information, e.g., battery health, firmware data or similar information.
- **Invoke** packages contain both detection- and remediation scripts for *managing* remediable settings, and is mostly used as *one-time* remidiations or [Run a remediation script on-demand](https://learn.microsoft.com/mem/intune/fundamentals/remediations#run-a-remediation-script-on-demand-preview "Run a remediation script on-demand").
- **Monitor** packages contain both detection- and remediation scripts, for *monitoring* remediable settings, e.g., registry values, folders and files.

## Create a script policy and assign it

The Microsoft Intune Management Extension service gets the scripts from Microsoft Intune and runs them.

To deploy script packages, follow the instructions [here](https://learn.microsoft.com/mem/intune/apps/intune-management-extension#create-a-script-policy-and-assign-it "Create a script policy and assign it").

## Monitor remediation status for a device

You can view the status of Remediations that are assigned or run on-demand to a device.

- Sign in to the [Microsoft Intune admin center](https://go.microsoft.com/fwlink/?linkid=2109431 "Microsoft Intune admin center").
- Navigate to Devices > By platform > Windows > select a supported device.
- Select Remediations in the Monitor section.

Alternatively, you can use the PowerShell script `Invoke-RemediationReport.ps1`, designed to connect to Microsoft Graph, and help you easily find, analyze and export returned outputs. Save the output as a .csv or .html file. Find the script in the [supporting-scripts](../platform-scripts/supporting-scripts) folder. Exporting allows you to share the results with others for further analysis.
