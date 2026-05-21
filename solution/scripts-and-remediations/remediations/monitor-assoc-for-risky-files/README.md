---
Title: README
Date: April 10, 2026
Author: dotjesper
Status: In development
---

[![Built for Windows 11](https://img.shields.io/badge/Built%20for%20Windows%2011-Yes-blue?style=flat)](https://windows.com/ "Built for Windows 11")
[![Built for Windows 10](https://img.shields.io/badge/Built%20for%20Windows%2010-Yes-blue?style=flat)](https://windows.com/ "Built for Windows 10")
[![Built for Windows Autopilot](https://img.shields.io/badge/Built%20for%20Windows%20Autopilot-Yes-blue?style=flat)](https://learn.microsoft.com/mem/autopilot/windows-autopilot/ "Windows Autopilot")

[![PSScriptAnalyzer verified](https://img.shields.io/badge/PowerShell%20Script%20Analyzer%20verified-Yes-green?style=flat)](https://learn.microsoft.com/powershell/module/psscriptanalyzer/ "PowerShell Script Analyzer")
[![PowerShell Constrained Language mode verified](https://img.shields.io/badge/PowerShell%20Constrained%20Language%20mode%20verified-Yes-green?style=flat)](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_language_modes/ "PowerShell Language mode")
[![Strict Mode verified](https://img.shields.io/badge/Strict%20Mode%20verified-Yes-green?style=flat)](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/set-strictmode/ "Set-StrictMode -Version latest")

# Microsoft Intune remediation: Monitor Windows default action for list of potentially malicious file types

Monitor Windows default action for list of potentially malicious file types.

When looking at file names in Explorer, be aware Windows might hide the file extension for known file types. Please notice, changing default behaviour to EDIT will cause scripts to open on e.g. Notepad if not properly prefixed with target executable.

Potentially dangerous extensions: JSE, JS, reg, VBE, VBS, WSF, bat, cmd, hta.

## File types and common practice

The following table lists the file types monitored by this package, their default shell action in Windows, and the recommended action to reduce risk.

| File type | Extension | Description | Default action | Recommended action |
|:---------:|:---------:|-------------|:--------------:|:------------------:|
| `JSEFile` | .jse | JScript Encoded File | open (execute) | edit |
| `JSFile` | .js | JScript File | open (execute) | edit |
| `regfile` | .reg | Registry Entries | open (merge) | edit |
| `VBEFile` | .vbe | VBScript Encoded File | open (execute) | edit |
| `VBSFile` | .vbs | VBScript Script File | open (execute) | edit |
| `WSFFile` | .wsf | Windows Script File | open (execute) | edit |
| `batfile` | .bat | Windows Batch File | open (execute) | edit |
| `cmdfile` | .cmd | Windows Command Script | open (execute) | edit |
| `htafile` | .hta | HTML Application | open (execute) | edit |

By default, Windows associates these file types with an **open** action, which means double-clicking a file will execute it. This is a common attack vector where users are tricked into running malicious scripts disguised as documents or other harmless files.

Changing the default action to **edit** causes the file to open in a text editor (e.g. Notepad) instead of executing. This gives the user an opportunity to inspect the file contents before deciding to run it. Scripts can still be executed intentionally by right-clicking and selecting **Open** or by running them from a command prompt.

This approach does not block execution entirely - it is a desired state configuration that reduces accidental execution risk while preserving the ability to run scripts when needed.

Available file actions for these file types:

| Action | Behaviour |
|:------:|:----------|
| `open` | Execute the file (Windows default) |
| `edit` | Open in a text editor |
| `print` | Send to printer |
| `runas` | Execute with elevated privileges |

## Script package information

External logging: **No**

## Script package properties

### Basic

Name: **Monitor Windows default action for list of potentially malicious file types**.

Description: **Monitor Windows default action for list of potentially malicious file types.**

Publisher: **Jesper Nielsen**

### Settings

Detection script: **Yes**

Remediation script: **Yes**

Run this script using the logged-on credentials: **No**

Enforce script signature check: **No**

Run script in 64-bit PowerShell: **No**

### Assignments

Schedule: **Weekly**

## Expected output

### detect.ps1

| Exit code | Output |
|:---------:|:-------|
| `exit 0` | `[00.000] File extension properly configured: .bat=txtfile .cmd=txtfile` |
| `exit 1` | `[00.000] 2 file extension misconfigured: .js=JSFile (expected: txtfile) .vbs=VBSFile (expected: txtfile)` |
