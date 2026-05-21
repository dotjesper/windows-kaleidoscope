---
Title: README
Date: April 7, 2026
Author: dotjesper
Status: In development
---

# Solution

The solution folder contains all production-ready deliverables for the **Windows kaleidoscope** project. Each subfolder targets a specific area of Microsoft Intune device management.

## Folder structure

The solution is organized into the following areas:

```text
 📂 solution/
  ├─ 📝 README.md
  ├─ 📄 solution.wsb                 # Windows Sandbox configuration
  ├─ 📁 compliance-policies/         # Compliance policies and custom compliance packages
  ├─ 📁 scripts-and-remediations/    # Platform scripts and remediation packages
  └─ 📁 supporting-scripts/          # Utility and reporting scripts
```

## Compliance policies

Pre-built Microsoft Intune compliance policy exports and custom compliance discovery scripts. Each compliance policy covers a single, focused compliance area. Custom script packages pair a PowerShell discovery script with a `settings.json` file that defines the compliance rules.

## Scripts and remediations

Remediation script packages organized by purpose, plus platform scripts for one-time execution scenarios. Remediation packages follow a naming convention with prefixes that indicate their type: `collect-*` for data collection, `monitor-*` for ongoing monitoring, and `invoke-*` for one-time actions.

## Supporting scripts

Utility and reporting scripts that complement the main solution. These scripts are not deployed through Microsoft Intune remediations but are used for administrative tasks such as Microsoft Graph-based remediation reporting.

## Windows Sandbox

The `solution.wsb` file provides a Windows Sandbox configuration for testing scripts in an isolated environment before deploying to production devices.
