# Copilot Instructions - Windows kaleidoscope

These instructions define project-specific rules for GitHub Copilot in this repository. Generic conventions for PowerShell, Markdown, terminology, and GitHub workflows are defined in the `.github/instructions/` files and apply automatically - this file covers only project-level overrides and patterns unique to Windows kaleidoscope.

## Project overview

**Windows kaleidoscope** is a Microsoft Intune management solution for Windows 10/11 enterprise devices. For a full description of what the project provides and its solution areas, see [README.md](../README.md).

**Author:** Jesper Nielsen (@dotjesper)
**License:** MIT
**Runtime:** PowerShell 5.1 via the Microsoft Intune Management Extension
**Target platforms:** Windows 10 22H2+, Windows 11

## Repository structure

The full repository structure is documented in [README.md](../README.md). In addition to the solution folders described there, the repository includes these internal folders:

- `.assets/` - image assets used in documentation
- `.config/` - PSScriptAnalyzer settings profiles (`Default.psd1`, `Strict.psd1`, `CI.psd1`)
- `.github/` - GitHub Copilot instructions and repository configuration
- `.vscode/` - Visual Studio Code workspace settings, tasks, and recommended extensions

The `.gitignore` excludes `desktop.ini`, `.bin/`, `.dev/`, `.docs/`, `.github/instructions/`, and `.notes/` from version control.

## Folder and file naming conventions

### Remediation package folders

Remediation package folders use lowercase kebab-case. The prefix determines the package type:

| Prefix | Purpose | Contains |
|--------|---------|----------|
| `collect-*` | Data collection, non-remediable | `detect.ps1` only |
| `monitor-*` | Ongoing monitoring with remediation | `detect.ps1` + `remediate.ps1` |
| `invoke-*` | One-time management action | `detect.ps1` + `remediate.ps1` |

Examples: `collect-battery-health`, `monitor-additional-lsa-protection`, `invoke-delete-dublicated-files`

### Script files

Each package contains a standard set of files:

| File | Purpose |
|------|---------|
| `detect.ps1` | Remediation detection script |
| `remediate.ps1` | Remediation action script |
| `discovery.ps1` | Custom compliance discovery script |
| `settings.json` | Custom compliance rule definitions |
| `README.md` | Package documentation |

### Compliance policy files

Compliance policy files follow the naming format: `WSR-C-Windows Compliance - [Focus Area] settings.json`

Example: `WSR-C-Windows Compliance - Trusted Platform Module (TPM) settings.json`

Each policy covers a single, focused compliance area - never combine multiple concerns into one policy.

---

## PowerShell project overrides

These rules override or extend the generic conventions in `powershell.instructions.md` for this repository's Microsoft Intune deployment context.

**Do not include `PSScriptInfo` headers.** All scripts in this repository are Microsoft Intune deployment scripts (remediation, platform, discovery), not standalone tools intended for the PowerShell Gallery. The `PSScriptInfo` block described in `powershell.instructions.md` does not apply to any script in this repository - omit it entirely.

**Do not use `SupportsShouldProcess`.** Use `[CmdletBinding()]` without `SupportsShouldProcess` for all scripts in this repository. These scripts run non-interactively under the Microsoft Intune Management Extension where `-WhatIf` and `-Confirm` are not applicable.

**Do not use `Set-StrictMode`.** The generic `powershell.instructions.md` requires `Set-StrictMode -Version Latest` in all scripts. This project omits it because remediation and detection scripts are short, single-purpose scripts where strict mode adds overhead without meaningful benefit in the Microsoft Intune execution context.

### Comment-based help overrides

The generic script structure from `powershell.instructions.md` applies (comment-based help, `#requires`, `[CmdletBinding()]`, `param()`, `begin`/`process`/`end`). This project uses a specific `.NOTES` and `.LINK` format:

```powershell
<#

.NOTES
    version: 1.0.0
    date: March 20, 2026
    license: MIT License

.LINK
    https://github.com/dotjesper/windows-kaleidoscope
#>
```

### Condition flags

Every script declares boolean condition flags in the `begin` block under `#variables :: conditions`. These control runtime checks in the `process` block:

| Flag | Purpose |
|------|---------|
| `[bool]$runScriptIn64bitPowerShell` | Require 64-bit PowerShell |

### Standardized error codes

The project uses a fixed set of error codes across all scripts:

| Error ID | Category | Meaning |
|----------|----------|---------|
| `B001` | `ResourceUnavailable` | 64-bit PowerShell required |
| `C001` | `SyntaxError` | Catch-all for runtime errors |

### Exit codes

Microsoft Intune interprets exit codes to determine script outcomes:

| Code | Meaning |
|------|---------|
| `exit 0` | Success (compliant, healthy, no action needed) |
| `exit 1` | Failure (non-compliant, error, action needed) |

Detection scripts: `exit 0` means compliant, `exit 1` triggers remediation.

### Script output streams

Microsoft Intune captures output differently for detection and remediation scripts. The admin center exposes these columns:

| Column | Source | Stream |
|--------|--------|--------|
| Pre-remediation detection output | `detect.ps1` (first run) | stdout (`Write-Output`) |
| Post-remediation detection output | `detect.ps1` (second run) | stdout (`Write-Output`) |
| Error output | Both scripts | stderr (`Write-Error`) |

Remediation script stdout (`Write-Output`) is **not** captured by Microsoft Intune and is not visible in the admin center or via Microsoft Graph. Only `Write-Error` from remediation scripts surfaces in the error output column.

**Detection scripts:** Use `Write-Output -InputObject` with state-based, factual messages that include detected values. The same script runs before and after remediation — write messages that describe what was observed, not what should happen next.

**Remediation scripts:** Use `Write-Error` for meaningful failure diagnostics. `Write-Output` in remediation scripts provides no operational value since the output is discarded.

### 64-bit check pattern

The standardized 64-bit check pattern:

```powershell
#region check conditions
if ($runScriptIn64bitPowerShell -eq $true -and $([System.Environment]::Is64BitProcess) -eq $false) {
    Write-Error -Message "Windows PowerShell 64-bit is required." -Category "ResourceUnavailable" -ErrorId "B001"
    exit 1
}
#endregion
```

### Registry operations

Registry operations must always split the registry root from the path. Use `Test-Path` before accessing registry values:

```powershell
[string]$regRoot = "HKLM"
[string]$regPath = "SYSTEM\CurrentControlSet\Control\Lsa"

if (Test-Path -Path $($regRoot + ":\" + $regPath)) {
    [array]$regValues = Get-ItemProperty -Path "Registry::$regRoot\$regPath"
}
```

For writing registry values, use `New-ItemProperty` with `-Force`:

```powershell
$null = New-ItemProperty -Path "Registry::$regRoot\$regPath" -Name "RunAsPPL" -Value 1 -PropertyType "DWORD" -Force
```

### Discovery scripts (custom compliance)

Discovery scripts must return a hashtable converted to compressed JSON in the `end` block:

```powershell
end {
    $hash = @{
        PropertyName1 = $value1
        PropertyName2 = $value2
    }
    return $hash | ConvertTo-Json -Compress
}
```

The hashtable keys must match the `SettingName` values in the corresponding `settings.json`.

---

## JSON conventions

### Custom compliance settings (settings.json)

Custom compliance settings follow the Microsoft Intune custom compliance schema:

```json
{
  "Rules": [
    {
      "SettingName": "PropertyName",
      "Operator": "IsEquals",
      "DataType": "String",
      "Operand": "ExpectedValue",
      "MoreInfoUrl": "https://learn.microsoft.com/...",
      "RemediationStrings": [
        {
          "Language": "en_US",
          "Title": "Non-compliant: {ActualValue} found",
          "Description": "Please contact your administrator for more information."
        }
      ]
    }
  ]
}
```

Rules for custom compliance settings:

- `SettingName` must exactly match a property key returned by the discovery script.
- Always specify `Operator` explicitly (`IsEquals`, `GreaterEquals`, `LessThan`, etc.).
- Always specify `DataType` explicitly (`String`, `Int64`, `Boolean`, `Version`).
- Always include `MoreInfoUrl` pointing to relevant documentation.
- Always include at least `en_US` in `RemediationStrings`.
- Use `{ActualValue}` placeholder in Title/Description to show the detected value.

### Compliance policy exports

Compliance policy exports are Microsoft Graph API exports. Do not manually author them - export from Microsoft Intune using tools like IntuneManagement. Each JSON file targets a single compliance area.

---

## Documentation standards

### README.md files

Every remediation package, custom compliance package, and platform script folder must include a `README.md`. Use this structure:

```markdown
---
Title: README
Date: March 20, 2026
Author: dotjesper
Status: In development
---

[![Built for Windows 11](https://img.shields.io/badge/Built%20for%20Windows%2011-Yes-blue?style=flat)](https://windows.com/ "Built for Windows 11")
[![Built for Windows 10](https://img.shields.io/badge/Built%20for%20Windows%2010-Yes-blue?style=flat)](https://windows.com/ "Built for Windows 10")
[![Built for Windows Autopilot](https://img.shields.io/badge/Built%20for%20Windows%20Autopilot-Yes-blue?style=flat)](https://learn.microsoft.com/mem/autopilot/windows-autopilot/ "Windows Autopilot")

[![PSScriptAnalyzer verified](https://img.shields.io/badge/PowerShell%20Script%20Analyzer%20verified-Yes-green?style=flat)](https://learn.microsoft.com/powershell/module/psscriptanalyzer/ "PowerShell Script Analyzer")
[![PowerShell Constrained Language mode verified](https://img.shields.io/badge/PowerShell%20Constrained%20Language%20mode%20verified-Yes-green?style=flat)](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_language_modes/ "PowerShell Language mode")

# Microsoft Intune remediation: [Name]

Brief description of what this package does and why it matters.

## Script package information

External logging: **No**

## Script package properties

### Basic

Name: **[Display name for Microsoft Intune]**

Description: **[Description for Microsoft Intune]**

Publisher: **Jesper Nielsen**

### Settings

Detection script: **Yes**

Remediation script: **Yes** / **No**

Run this script using the logged-on credentials: **Yes** / **No**

Enforce script signature check: **Yes** / **No**

Run script in 64-bit PowerShell: **Yes** / **No**

### Assignments

Schedule: **Daily** / **Hourly** / **Once**
```

### Badges

Package READMEs include platform and quality badges:

- **Built for Windows 11** / **Built for Windows 10** - always include both
- **Built for Windows Autopilot** - include when applicable
- **PSScriptAnalyzer verified** - Yes if the script passes PSScriptAnalyzer
- **PowerShell Constrained Language mode verified** - Yes if tested in CLM

---

## Compliance and security

### Execution constraints

Scripts in this repository run under the Microsoft Intune Management Extension with these constraints:

- All scripts run under the Microsoft Intune Management Extension.
- Maximum output to stdout: 2048 characters.
- No external module dependencies in remediation scripts.
- No user interaction - never prompt for input, display GUI dialogs, or assume an interactive session.
- Do not include reboot commands in detection or remediation scripts.

### Constrained Language Mode specifics

The generic CLM rules in `powershell.instructions.md` apply. In addition, these project-specific constraints apply:

- Only these .NET type accelerators are permitted: `[int]`, `[string]`, `[bool]`, `[array]`, `[version]`, `[IntPtr]`. All others (e.g., `[Convert]`, `[System.IO.Path]`) are blocked under CLM.
- Use `switch` statements instead of dynamic method invocation where CLM blocks direct method calls.
- Binary registry values (`REG_BINARY`) cannot be processed under CLM - log a warning and skip the operation.
- Where CLM compatibility is not possible for a specific code path, guard it with `$script:IsConstrainedLanguageMode` and handle gracefully (log a warning and skip).

### Licensing requirements

Licensing requirements for remediation scripts are documented in the [README.md](../README.md).

---

## Patterns to follow

These patterns demonstrate the correct structure and conventions for scripts in this repository.

### Good: Detection script for registry monitoring

```powershell
#requires -Version 5.1
[CmdletBinding()]
param ()
begin {
    [bool]$runScriptIn64bitPowerShell = $false
    [string]$regRoot = "HKLM"
    [string]$regPath = "SYSTEM\CurrentControlSet\Control\Lsa"
}
process {
    #region check conditions
    if ($runScriptIn64bitPowerShell -eq $true -and $([System.Environment]::Is64BitProcess) -eq $false) {
        Write-Error -Message "Windows PowerShell 64-bit is required." -Category "ResourceUnavailable" -ErrorId "B001"
        exit 1
    }
    #endregion
    try {
        if (Test-Path -Path $($regRoot + ":\" + $regPath)) {
            [array]$regValues = Get-ItemProperty -Path "Registry::$regRoot\$regPath"
            if ($regValues.TargetValue -eq 1) {
                Write-Output -InputObject "Setting properly configured"
                exit 0
            }
            else {
                Write-Output -InputObject "Setting misconfigured"
                exit 1
            }
        }
    }
    catch {
        $errMsg = $_.Exception.Message
        Write-Error -Message $errMsg -Category "SyntaxError" -ErrorId "C001"
        exit 1
    }
    finally {}
}
end {}
```

### Good: Discovery script for custom compliance

```powershell
#requires -Version 5.1
[CmdletBinding()]
param ()
begin {
    [bool]$runScriptIn64bitPowerShell = $true
}
process {
    #region check conditions
    if ($runScriptIn64bitPowerShell -eq $true -and $([System.Environment]::Is64BitProcess) -eq $false) {
        Write-Error -Message "Windows PowerShell 64-bit is required." -Category "ResourceUnavailable" -ErrorId "B001"
        exit 1
    }
    #endregion
    try {
        [string]$Value1 = (Get-CimInstance Win32_OperatingSystem).Caption
        [int]$Value2 = (Get-CimInstance Win32_OperatingSystem).OperatingSystemSKU
    }
    catch {
        $errMsg = $_.Exception.Message
        Write-Error -Message $errMsg
        exit 1
    }
    finally {}
}
end {
    $hash = @{ Caption = $Value1; Edition = $Value2 }
    return $hash | ConvertTo-Json -Compress
}
```

## Anti-patterns to avoid

These anti-patterns show common mistakes to avoid when writing scripts for this repository.

### Bad: Missing type declarations and improper structure

```powershell
# Missing #requires, no CmdletBinding, no begin/process/end
param ($threshold = 80)
$value = Get-ItemProperty "HKLM:\SOFTWARE\Key"
if ($value.Setting -eq 1) { echo "OK" } else { echo "FAIL"; exit 1 }
```

### Bad: Monolithic error handling and hard-coded paths

```powershell
# Hard-coded full registry path, no Test-Path, Write-Host usage
$val = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
Write-Host "Value is $($val.RunAsPPL)"
```

### Bad: Discovery script returning wrong format

```powershell
# Returning plain text instead of JSON
end {
    Write-Output "Edition=Enterprise, Arch=64-bit"
}
```

---

## Copilot behavior guidelines

When helping with this repository:

1. **Follow existing patterns exactly.** Match the coding style, variable naming, header format, and structure of existing scripts. Consistency matters more than personal preference.
2. **Respect the Microsoft Intune execution context.** Scripts run under the Intune Management Extension with no user interaction. Never prompt for input, display GUI dialogs, or assume an interactive session.
3. **Never suggest deploying compliance policies without testing.** Always include warnings about piloting and validating in non-production environments first.
4. **When creating new remediation packages**, include all required files (`detect.ps1`, `remediate.ps1` if applicable, `README.md`) following the documented templates.
5. **For JSON compliance rules**, ensure `SettingName` values match the exact property names returned by the discovery script's hashtable.
6. **No policy enforcement settings.** Windows kaleidoscope is a desired state configuration tool, not a policy enforcement solution. Do not include settings designed to restrict or prevent users from changing their configuration.
