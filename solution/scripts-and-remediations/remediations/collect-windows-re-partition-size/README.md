---
Title: README
Date: July 24, 2024
Author: dotjesper
Status: In development
---

[![Built for Windows 11](https://img.shields.io/badge/Built%20for%20Windows%2011-Yes-blue?style=flat)](https://windows.com/ "Built for Windows 11")
[![Built for Windows 10](https://img.shields.io/badge/Built%20for%20Windows%2010-Yes-blue?style=flat)](https://windows.com/ "Built for Windows 10")
[![Built for Windows Autopilot](https://img.shields.io/badge/Built%20for%20Windows%20Autopilot-Yes-blue?style=flat)](https://docs.microsoft.com/en-us/mem/autopilot/windows-autopilot/ "Windows Autopilot")

[![PSScriptAnalyzer verified](https://img.shields.io/badge/PowerShell%20Script%20Analyzer%20verified-No-green?style=flat)](https://docs.microsoft.com/en-us/powershell/module/psscriptanalyzer/ "PowerShell Script Analyzer")
[![PowerShell Constrained Language mode verified](https://img.shields.io/badge/PowerShell%20Constrained%20Language%20mode%20verified-Yes-green?style=flat)](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_language_modes/ "PowerShell Language mode")

# Microsoft Intune remediation: Collect Windows RE partition size.

The Windows RE partition is a hidden partition on the hard drive that contains the Windows RE files. The size of this partition depends on the version of Windows 10/11 and the type of installation. Some older versions of Windows 10 or some upgrade scenarios may have created a Windows RE partition that is too small to accommodate the [KB5028997](https://support.microsoft.com/topic/kb5028997-instructions-to-manually-resize-your-partition-to-install-the-winre-update-400faa27-9343-461c-ada9-24c8229763bf "Instructions to manually resize your partition to install the WinRE update") update. If you try to install the update without resizing the partition, you may encounter an error message that says "We couldn't update the system reserved partition".

[KB5028997](https://support.microsoft.com/topic/kb5028997-instructions-to-manually-resize-your-partition-to-install-the-winre-update-400faa27-9343-461c-ada9-24c8229763bf "Instructions to manually resize your partition to install the WinRE update") is a Windows 10 update that fixes a security vulnerability in the Windows Recovery Environment (winre).

The disk partition for Windows RE tools must be at least 300 megabytes (MB). Typically, **between 500-700 MB** is allocated for the Windows RE tools image depending on base language and added customizations.

The allocation for Windows RE must also include sufficient free space for backup utilities to capture the partition.

Follow these guidelines for the Windows RE partition:

- For Windows operating systems later than Windows 10, version 2004 or Windows Server 2022, the partition must have at **least 200 MB of free space**.
- The partition must be the last partition on the drive to support dynamic resizing, typically **partition 4** on UEFI devices and **partition 3** on legacy BIOS devices.
- The partition must use the following Type ID: DE94BBA4-06D1-4D40-A16A-BFD50179D6AC

The Windows RE tools should be in a partition that's separate from the Windows partition. This separation supports automatic failover and the startup of partitions that are encrypted by using Windows BitLocker Drive Encryption.

## Script package information

Windows RE partition size Threshold: **1024MB**

External logging: **No**

## Script package properties

### Basic

Name: **Collect Windows RE partition size**

Description: **Collect Windows RE partition size**

Publisher: **Jesper Nielsen**

### Settings

Detection script: **Yes**

Remediation script: **No**

Run this script using the logged-on credentials: **No**

Enforce script signature check: **No**

Run script in 64-bit PowerShell: **No**

### Assignments

Schedule: **Weekly**
