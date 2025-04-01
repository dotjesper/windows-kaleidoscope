---
Title: README
Date: April 22, 2021
Author: dotjesper
Status: In development
---

[![Built for Windows 11](https://img.shields.io/badge/Built%20for%20Windows%2011-Yes-blue?style=flat)](https://windows.com/ "Built for Windows 11")
[![Built for Windows 10](https://img.shields.io/badge/Built%20for%20Windows%2010-Yes-blue?style=flat)](https://windows.com/ "Built for Windows 10")
[![Built for Windows Autopilot](https://img.shields.io/badge/Built%20for%20Windows%20Autopilot-Yes-blue?style=flat)](https://docs.microsoft.com/en-us/mem/autopilot/windows-autopilot/ "Windows Autopilot")

[![PSScriptAnalyzer verified](https://img.shields.io/badge/PowerShell%20Script%20Analyzer%20verified-Yes-green?style=flat)](https://docs.microsoft.com/en-us/powershell/module/psscriptanalyzer/ "PowerShell Script Analyzer")
[![PowerShell Constrained Language mode verified](https://img.shields.io/badge/PowerShell%20Constrained%20Language%20mode%20verified-No-green?style=flat)](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_language_modes/ "PowerShell Language mode")

# Microsoft Intune remediation: Monitor Windows System Stability Index

Reliability Monitor is an advanced tool that provides a system stability overview and details about events that impact reliability. It calculates the Stability Index shown in the System Stability Chart over the lifetime of the system.

Based on data collected over the lifetime of the system, each date in the System Stability Chart includes a graph point showing that day's System Stability Index rating. The System Stability Index is a number from 1 (least stable) to 10 (most stable) and is a weighted measurement derived from the number of specified failures seen over a rolling historical period. Reliability Events in the System Stability Report describe the specific failures.

Recent failures are weighted more heavily than past failures, allowing an improvement over time to be reflected in an ascending System Stability Index once a reliability issue has been resolved.

Days when the system is powered off or in a sleep state are not used when calculating the System Stability Index.

If there is not enough data to calculate a steady System Stability Index, the graphed line will be dotted. When enough data has been recorded to generate a steady System Stability Index, the graphed line will be solid.

If there are any significant changes to the system time, an Information icon will appear on the graph for each day on which the system time was adjusted.

Reliability Monitor maintains up to a year of history for system stability and reliability events. The System Stability Chart displays a rolling graph organized by date.

A quick way to see the state of a Windows machine is to open Reliability Monitor. It’s a built-in tool that has been around since Windows Vista and still works in Windows 10. You probably don’t hear much about it, but it’s quite useful.

**Application failures** Every time you have an application failure, which can be an application crashing or hanging, it will show a red "x" in that column.

**Windows failures** This column will get a red "x" when you have a BSOD.

**Miscellaneous failures** These are when the system unexpectedly loses power. The power button might force a shutdown or possibly the battery could run completely out.

**Warnings**:** These do not impact your stability score but provide good information. They will show when an application installation/removal, Windows Update, or driver update was unsuccessful.

**Information** This column will get a blue "i" when there are system changes you should be aware of. Driver installation, Windows Updates, and software installations will all appear in this column. This information can be very handy when troubleshooting what caused a failure.

## Script package information

Reliability Stability Threshold: **4** [1-10]

External logging: **No**

## Script package properties

### Basic

Name: **Monitor Windows System Stability Index**

Description: **Monitor Windows System Stability Index, fails if Reliability Stability Metrics average is below 4.**

Publisher: **Jesper Nielsen**

### Settings

Detection script: **Yes**

Remediation script: **No**

Run this script using the logged-on credentials: **No**

Enforce script signature check: **No**

Run script in 64-bit PowerShell: **Yes**

### Assignments

Schedule: **Weekly**

## References

[Monitoring Windows system stability with PowerShell](https://4sysops.com/archives/monitoring-windows-system-stability-with-powershell/ "Monitoring Windows system stability with PowerShell")

[Use PowerShell to Determine Computer Reliability](https://devblogs.microsoft.com/scripting/use-powershell-to-determine-computer-reliability/ "Use PowerShell to Determine Computer Reliability")

### Examples

```Powershell
Get-Ciminstance -ClassName Win32_ReliabilityStabilityMetrics | Measure-Object -Average -Maximum  -Minimum -Property systemStabilityIndex

Get-Ciminstance -ClassName Win32_ReliabilityStabilityMetrics | Select StartMeasurementDate, SystemStabilityIndex | Out-GridView
```
