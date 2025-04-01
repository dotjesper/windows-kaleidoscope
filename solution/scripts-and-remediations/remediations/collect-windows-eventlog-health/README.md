---
Title: README
Date: May 24, 2024
Author: dotjesper
Status: In development
---

[![Built for Windows 11](https://img.shields.io/badge/Built%20for%20Windows%2011-Yes-blue?style=flat)](https://windows.com/ "Built for Windows 11")
[![Built for Windows 10](https://img.shields.io/badge/Built%20for%20Windows%2010-Yes-blue?style=flat)](https://windows.com/ "Built for Windows 10")
[![Built for Windows Autopilot](https://img.shields.io/badge/Built%20for%20Windows%20Autopilot-Yes-blue?style=flat)](https://docs.microsoft.com/en-us/mem/autopilot/windows-autopilot/ "Windows Autopilot")

[![PSScriptAnalyzer verified](https://img.shields.io/badge/PowerShell%20Script%20Analyzer%20verified-Yes-green?style=flat)](https://docs.microsoft.com/en-us/powershell/module/psscriptanalyzer/ "PowerShell Script Analyzer")
[![PowerShell Constrained Language mode verified](https://img.shields.io/badge/PowerShell%20Constrained%20Language%20mode%20verified-Yes-green?style=flat)](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_language_modes/ "PowerShell Language mode")

# Microsoft Intune remediation: Collect Windows Eventlog health

In the realm of system administration, maintaining the integrity and accessibility of Windows Event Logs is paramount. These logs serve as a crucial tool for troubleshooting and diagnosing issues within the system. However, by default, Windows Event Logs are designed to be overwritten once the maximum event log size is reached. This can pose a significant challenge for administrators who require a consistent record of events for a minimum of days.

To address this concern, leveraging remidiation script to colelct the age of Windows Event Logs allow administrators to fine tune eventlog size.

The "Collect Windows Eventlog health" remidiation script is engineered to easily collect the requqred information. By implementing this script, administrators can:

- **Ensure Log Retention**. Automatically check and maintain event logs on the system for at least seven days, enhancing troubleshooting efficacy.
- **Enhance Efficiency**. Reduce manual oversight by automating the monitoring of log age, allowing administrators to focus on more critical tasks.
- **Increase Reliability**. Prevent the premature overwriting of event logs, ensuring that historical data is available when needed for comprehensive analysis.

## Script package information

Windows Eventlog health threshold: **7 days**

External logging: **Yes**

External log: **"%ProgramData%\Microsoft\IntuneManagementExtension\Logs\eventloghealth.log"**

## Script package properties

### Basic

Name: **Collect Windows Eventlog health**

Description: **Collect Windows Eventlog health**

Publisher: **Jesper Nielsen**

### Settings

Detection script: **Yes**

Remediation script: **No**

Run this script using the logged-on credentials: **No**

Enforce script signature check: **No**

Run script in 64-bit PowerShell: **No**

### Assignments

Schedule: **Weekly**