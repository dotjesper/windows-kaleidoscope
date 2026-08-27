---
Title: Windows Autopilot device preparation
Date: August 27, 2026
Author: dotjesper
Status: In development
---

[![Built for Windows 11](https://img.shields.io/badge/Built%20for%20Windows%2011-Yes-blue?style=flat)](https://windows.com/ "Built for Windows 11")
[![Built for Windows Autopilot Device Preparation](https://img.shields.io/badge/Built%20for%20Windows%20Autopilot-Yes-blue?style=flat)](https://learn.microsoft.com/autopilot/device-preparation/overview/ "Windows Autopilot")

[![PSScriptAnalyzer verified](https://img.shields.io/badge/PowerShell%20Script%20Analyzer%20verified-Yes-green?style=flat)](https://learn.microsoft.com/powershell/module/psscriptanalyzer/ "PowerShell Script Analyzer")
[![PowerShell Constrained Language mode verified](https://img.shields.io/badge/PowerShell%20Constrained%20Language%20mode%20verified-No-orange?style=flat)](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_language_modes/ "PowerShell Language mode")
[![Strict Mode verified](https://img.shields.io/badge/Strict%20Mode%20verified-Yes-green?style=flat)](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/set-strictmode/ "Set-StrictMode -Version latest")

# Windows Autopilot device preparation

Prepares Windows devices during Windows Autopilot enrollment and Windows 365 Cloud PC provisioning. This folder contains two independent platform scripts that cover different parts of the device preparation phase.

## Scripts in this folder

| Script | Purpose | Log file |
|--------|---------|----------|
| `device-preparation.ps1` | Computer naming, OOBE registry settings, BitLocker Drive Encryption validation, and location markers | `DevicePreparation.log` |
| `defender-update.ps1` | Forces a Microsoft Defender Antivirus security intelligence update and logs the versions before and after | `DefenderUpdate.log` |

Each script is deployed as its own Microsoft Intune platform script, with its own assignment, log file, and exit code. The scripts have no dependency on each other and can be deployed together or on their own. In most environments, `device-preparation.ps1` is assigned to all Autopilot devices, and `defender-update.ps1` is added only where the security intelligence update is not delivered during OOBE.

## Why two scripts

The Microsoft Defender Antivirus update is deliberately kept out of `device-preparation.ps1` for the following reasons:

- **Different target scenarios.** Device naming, OOBE settings, and location markers apply to every Autopilot device. The Defender update targets a narrower gap: the `OobeEnableRtpAndSignatureUpdate` CSP - the *Oobe Enable Rtp And Sig Update* Settings Catalog policy - is not always applied, most notably during Windows 365 Cloud PC provisioning, which leaves the Cloud PC with outdated security intelligence and misleading compliance signals.
- **Different assignment needs.** Keeping the scripts separate makes it possible to assign the Defender update only to the device groups that need it, such as Windows 365 Cloud PCs, without changing the device preparation assignment.
- **Different runtime behavior.** `defender-update.ps1` deliberately waits for the Microsoft Defender Antivirus service, retries the update, and can run for several minutes. `device-preparation.ps1` completes quickly and a successful rename sets a pending reboot flag. Separating them keeps a slow or failing signature update from delaying or re-running the device configuration work.
- **Independent failure and retry.** Microsoft Intune retries a failed platform script on the next three consecutive check-ins. As separate scripts, a failed Defender update is retried on its own, and the device preparation result stays unaffected.

> [!NOTE]
> The two scripts may be merged into a single device preparation script in a future release, most likely as an additional feature flag, once the platform behavior for security intelligence updates during OOBE and Windows 365 provisioning is consistent. Until then, deploy them as separate platform scripts.

---

## device-preparation.ps1

Automates initial Windows device setup during Autopilot enrollment by configuring computer naming, OOBE registry settings, BitLocker Drive Encryption validation, and location markers.

### Overview

This script prepares Windows devices during Windows Autopilot enrollment by performing automated device configuration tasks. It supports multiple naming conventions, configures OOBE settings to streamline the user experience, validates BitLocker Drive Encryption status, and sets location markers for regional configuration.

### Features

The script provides the following capabilities, each controlled independently via the `-Features` bitmask:

- **Device Renaming** - Rename computers using serial number, random digits, or SHA256 hash
- **OOBE Configuration** - Disables privacy prompts, voice features, and EULA pages
- **BitLocker Validation** - Reports encryption status, method, and key protectors
- **Location Markers** - Sets registry-based markers for regional settings

### Requirements

The script requires the following to run:

- **PowerShell** - Version 5.1 or later
- **Elevation** - Must run as Administrator
- **Operating System** - Windows 11

### Parameters

The script accepts the following parameters:

- **`-Features`** (Int, default: `15`) - Bitmask to enable/disable features (see Feature Flags below)
- **`-Prefix`** (String, default: `WSR5`) - Custom prefix for computer name (max 5 characters)
- **`-Suffix`** (String, default: empty) - Custom suffix for computer name (max 5 characters)
- **`-NamingMethod`** (String, default: empty) - Naming method: `%SERIAL%` or `%RAND:x%`
- **`-LocationMarker`** (String, default: `DEN`) - Registry marker for location/region settings
- **`-LocationMarkerPath`** (String) - Registry path for location marker
- **`-logFilePath`** (String, default: `DevicePreparation.log`) - Custom log file path
- **`-WhatIf`** (Switch) - Preview changes without executing (common parameter)
- **`-Verbose`** (Switch) - Show detailed output during execution (common parameter)

### Feature flags

The `-Features` parameter uses a bitmask to control which features are enabled:

| Flag | Value | Feature |
|:----:|:-----:|---------|
| 1 | 0001 | Device Renaming |
| 2 | 0010 | OOBE Registry Settings |
| 4 | 0100 | BitLocker Drive Encryption Validation |
| 8 | 1000 | Location Marker |

#### Common combinations

Common feature flag combinations for typical deployment scenarios:

| Value | Features Enabled |
|------:|------------------|
| `15` | All features (default) |
| `7` | Renaming + OOBE + BitLocker Drive Encryption (no location marker) |
| `5` | Renaming + BitLocker Drive Encryption |
| `3` | Renaming + OOBE |
| `1` | Device Renaming only |
| `4` | BitLocker Drive Encryption Validation only |
| `0` | All features disabled |

#### Feature flag examples

Examples showing how to use the `-Features` parameter:

```powershell
# All features enabled (default)
.\device-preparation.ps1 -Features 15

# Only BitLocker Drive Encryption validation
.\device-preparation.ps1 -Features 4

# Device renaming and OOBE settings only
.\device-preparation.ps1 -Features 3 -Prefix "LAP"

# All features except location marker
.\device-preparation.ps1 -Features 7 -Prefix "PC" -NamingMethod "%SERIAL%"
```

### Usage examples

The following examples demonstrate common usage patterns for the script.

#### Basic usage (default SHA256 naming)

Running the script without specifying a naming method uses SHA256 hashing:

```powershell
.\device-preparation.ps1
```

Generates a name like `WSR578A7D663F45` using SHA256 hash of the serial number.

#### Serial number based naming

Using the device serial number as the basis for the computer name:

```powershell
.\device-preparation.ps1 -Prefix "WIN-" -Suffix "-01" -NamingMethod "%SERIAL%"
```

Generates a name like `WIN-ABC123DEF-01` using the device serial number.

#### Random digit naming

Using randomly generated digits for the computer name:

```powershell
.\device-preparation.ps1 -Prefix "PC" -NamingMethod "%RAND:8%"
```

Generates a name like `PC12345678` using 8 random digits.

#### Custom location marker

Setting a custom location marker with a custom registry path:

```powershell
.\device-preparation.ps1 -Prefix "LAP" -LocationMarker "USA" -LocationMarkerPath "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Contoso\Location"
```

#### Test mode (WhatIf)

Previewing changes without making any modifications to the system:

```powershell
.\device-preparation.ps1 -Prefix "TEST" -WhatIf -Verbose
```

### Naming methods

The script supports three naming methods for generating computer names.

#### %SERIAL% - serial number

Uses the device's BIOS serial number (with hyphens removed) as the basis for the computer name.

```
Prefix + SerialNumber + Suffix = Computer Name
WIN    + ABC123DEF    + 01     = WINABC123DEF01 (truncated to 15 chars)
```

#### %RAND:x% - random digits

Generates `x` random digits for the computer name.

```
Prefix + RandomDigits + Suffix = Computer Name
PC     + 12345678     + DEN    = PC12345678DEN
```

#### Default - SHA256 hash

When no naming method is specified, generates a SHA256 hash of the serial number for consistent, unique naming.

```
Prefix + SHA256Hash   + Suffix = Computer Name
WSR5   + 78A7D663F45  + <none> = WSR578A7D663F45
```

#### Name validation

Name validation is performed automatically after the name is generated:

- Truncates names exceeding 15 characters (NetBIOS limit)
- Removes invalid characters (only A-Z, 0-9, and hyphen allowed)
- Removes leading/trailing hyphens
- Falls back to a GUID if serial number is unavailable

### OOBE registry settings

The script configures the following OOBE settings:

- **`DisablePrivacyExperience`** (DWORD: 1) - Skips privacy settings prompts
- **`DisableVoice`** (DWORD: 1) - Disables voice features during OOBE
- **`PrivacyConsentStatus`** (DWORD: 1) - Sets privacy consent status
- **`ProtectYourPC`** (DWORD: 3) - Configures system protection level
- **`HideEULAPage`** (DWORD: 1) - Hides the EULA acceptance page

**Registry Path:** `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE`

### BitLocker Drive Encryption validation

The script validates and reports BitLocker Drive Encryption status:

- Protection status (On/Off)
- Encryption method (e.g., XtsAes256)
- Key protectors (TPM, RecoveryPassword, etc.)
- Volume status (FullyEncrypted, EncryptionInProgress, etc.)

> [!NOTE]
> This feature validates and reports BitLocker Drive Encryption status only; it does not enable or configure BitLocker Drive Encryption.

### Location marker

The location marker creates a registry-based marker that can be used by other scripts or policies to determine device location and apply regional configurations.

**Default Path:** `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE`

**Value Name:** `LocationMarker`

**Value Type:** String

### Logging

Logs are written in CMTrace/Intune format to:

```
%ProgramData%\Microsoft\IntuneManagementExtension\Logs\DevicePreparation.log
```

#### Log entry types

The script uses three severity levels for log entries:

- **Type 1** - Informational (CMTrace: Default)
- **Type 2** - Warning (CMTrace: Yellow)
- **Type 3** - Error (CMTrace: Red)

#### Execution summary

At the end of execution, the script logs a summary of all features and their outcomes:

- Device Renamed: True/False
- OOBE Settings Applied: True/False
- BitLocker Validated: True/False
- Location Marker Set: True/False
- List of any warnings encountered
- List of any errors encountered

#### Exit codes

The script returns the following exit codes:

| Code | Meaning |
|:----:|---------|
| `0`  | Success - all enabled features completed without errors |
| `1`  | Failure - one or more errors occurred during execution |

### Microsoft Intune deployment

#### Script properties

Configure the following properties in the Microsoft Intune admin center:

Name: **Windows Autopilot - Device Preparation Script**

Description: **Configures device naming, OOBE settings, BitLocker Drive Encryption validation, and location markers during Autopilot enrollment.**

Publisher: **Jesper Nielsen**

#### Script settings

Configure the following settings in the Microsoft Intune admin center:

PowerShell script: **device-preparation.ps1**

Run this script using the logged-on credentials: **No**

Enforce script signature check: **No**

Run script in 64-bit PowerShell host: **Yes**

#### Assignments

Assign this script to a **device group** containing your Autopilot devices.

> [!Important]
> This script requires administrator privileges and should run in the SYSTEM context during Autopilot enrollment.

### Testing

The script supports local testing before deploying via Microsoft Intune.

#### Local testing

> [!NOTE]
> This script requires 64-bit PowerShell. Ensure you are running `%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe`, not the 32-bit host under `SysWOW64`.

```powershell
# Test with WhatIf to preview changes
.\device-preparation.ps1 -Prefix "TEST" -WhatIf -Verbose

# Test with verbose output (actual execution)
.\device-preparation.ps1 -Prefix "TEST" -Verbose
```

#### Validate log output

Verify log output after running the script:

```powershell
# Open log in CMTrace or view in PowerShell
Get-Content "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\DevicePreparation.log" -Tail 50
```

### Troubleshooting

The following sections cover common issues and verification steps.

#### Common issues

Common issues and their resolutions:

- **Script fails with "Access Denied"**
  - Cause: Not running as Administrator
  - Solution: Run PowerShell as Administrator or deploy via Intune

- **Computer name not changed**
  - Cause: Device already has the correct prefix
  - Solution: Expected behavior - no action needed

- **BitLocker validation fails**
  - Cause: BitLocker module not available
  - Solution: Ensure running on Windows 11 with BitLocker capability

- **Serial number fallback used**
  - Cause: BIOS serial number empty or unavailable
  - Solution: Script uses GUID as fallback; verify BIOS configuration

#### Verify pending reboot

After a successful device rename, verify the pending reboot flag:

```powershell
Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" -Name "RebootRequired" -ErrorAction SilentlyContinue
```

---

## defender-update.ps1

Forces a Microsoft Defender Antivirus security intelligence update during device preparation and logs the versions detected before and after the update.

### Overview

This script is intended for scenarios where the built-in mechanisms do not deliver the expected result:

- The `OobeEnableRtpAndSignatureUpdate` CSP - the *Oobe Enable Rtp And Sig Update* Settings Catalog policy - is not applied or does not work as expected.
- Windows 365 Cloud PC provisioning, where the setting is not applied to the Cloud PC, but Microsoft Defender Antivirus still needs to be current to produce clean compliance signals.

### Features

The script performs the following steps:

- **Service validation** - Waits for the Microsoft Defender Antivirus service (`WinDefend`) to reach a running state and verifies that the Defender PowerShell module is available
- **Pre-update state** - Logs product, engine, and service versions, signature versions, signature age, last update time, running mode, and real-time protection state
- **Security intelligence update** - Runs `Update-MpSignature` against the configured update source with configurable retries, and falls back to `MpCmdRun.exe` when the Defender PowerShell module is unavailable or the cmdlet fails
- **Post-update state** - Logs the same values again, compares them with the pre-update values, and reports whether the signature version changed

### Requirements

The script requires the following to run:

- **PowerShell** - Version 5.1 or later
- **Elevation** - Must run as Administrator
- **Operating System** - Windows 10/11, including Windows 365 Cloud PC
- **Network** - Access to the configured update source

### Parameters

The script accepts the following parameters:

- **`-UpdateSource`** (String, default: `MicrosoftUpdateServer`) - Update source used by `Update-MpSignature`. Valid values: `InternalDefinitionUpdateServer`, `MicrosoftUpdateServer`, `MMPC`, `FileShares`
- **`-InitialDelaySeconds`** (Int, default: `30`) - Seconds to wait before the update is attempted, allowing networking and the Microsoft Defender Antivirus service to settle during OOBE
- **`-ServiceTimeoutSeconds`** (Int, default: `300`) - Maximum seconds to wait for the Microsoft Defender Antivirus service to reach a running state
- **`-RetryCount`** (Int, default: `3`) - Number of update attempts before the update is considered failed
- **`-RetryDelaySeconds`** (Int, default: `30`) - Seconds to wait between update attempts
- **`-PostUpdateDelaySeconds`** (Int, default: `30`) - Seconds to wait after the update before the resulting versions are read
- **`-logFilePath`** (String, default: `DefenderUpdate.log`) - Custom log file path
- **`-WhatIf`** (Switch) - Preview changes without executing (common parameter)
- **`-Verbose`** (Switch) - Show detailed output during execution (common parameter)

### Usage examples

The following examples demonstrate common usage patterns for the script.

#### Basic usage

Running the script with default settings:

```powershell
.\defender-update.ps1
```

#### Alternate update source

Updating directly from the Microsoft Malware Protection Center with additional retries:

```powershell
.\defender-update.ps1 -UpdateSource "MMPC" -RetryCount 5
```

#### Interactive testing

Running the update without an initial delay, useful when testing the script interactively:

```powershell
.\defender-update.ps1 -InitialDelaySeconds 0 -PostUpdateDelaySeconds 5 -Verbose
```

### Logging

Logs are written in CMTrace/Intune format to:

```
%ProgramData%\Microsoft\IntuneManagementExtension\Logs\DefenderUpdate.log
```

#### Execution summary

At the end of execution, the script logs a summary of the update outcome:

- Microsoft Defender Antivirus service running: True/False
- Microsoft Defender Antivirus status retrieved: True/False
- Update attempted: True/False
- Update succeeded: True/False
- Signature version before and after the update
- Signature version changed: True/False
- List of any warnings encountered
- List of any errors encountered

#### Exit codes

The script returns the following exit codes:

| Code | Meaning |
|:----:|---------|
| `0`  | Success - the update completed without errors |
| `1`  | Failure - one or more errors occurred, allowing the Microsoft Intune Management Extension to retry the script on the next check-ins |

### Microsoft Intune deployment

#### Script properties

Configure the following properties in the Microsoft Intune admin center:

Name: **Windows Autopilot - Microsoft Defender Antivirus Update Script**

Description: **Forces a Microsoft Defender Antivirus security intelligence update during device preparation and Windows 365 Cloud PC provisioning.**

Publisher: **Jesper Nielsen**

#### Script settings

Configure the following settings in the Microsoft Intune admin center:

PowerShell script: **defender-update.ps1**

Run this script using the logged-on credentials: **No**

Enforce script signature check: **No**

Run script in 64-bit PowerShell host: **Yes**

#### Assignments

Assign this script to a **device group** containing the devices where the security intelligence update is not delivered during OOBE, such as Windows 365 Cloud PCs.

> [!Important]
> This script requires administrator privileges and should run in the SYSTEM context during device preparation.

### Testing

The script supports local testing before deploying via Microsoft Intune.

#### Local testing

```powershell
# Preview the update without executing it
.\defender-update.ps1 -WhatIf -Verbose

# Run the update without the initial delay
.\defender-update.ps1 -InitialDelaySeconds 0 -PostUpdateDelaySeconds 5 -Verbose
```

#### Validate log output

Verify log output after running the script:

```powershell
# Open log in CMTrace or view in PowerShell
Get-Content "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\DefenderUpdate.log" -Tail 50
```

### Troubleshooting

Common issues and their resolutions:

- **Microsoft Defender Antivirus service did not reach a running state**
  - Cause: The `WinDefend` service is still starting, or a third-party antivirus product is present
  - Solution: Increase `-ServiceTimeoutSeconds`, or verify that Microsoft Defender Antivirus is the active antivirus product

- **Defender PowerShell module unavailable**
  - Cause: The Defender module is not loaded during early OOBE
  - Solution: Expected behavior - the script falls back to `MpCmdRun.exe`

- **Update failed after all attempts**
  - Cause: No network connectivity, or the configured update source is unreachable
  - Solution: Verify network access to the update source, or change `-UpdateSource`

- **Signature version unchanged**
  - Cause: The device already has the current security intelligence version
  - Solution: Expected behavior - no action needed

---

## Version history

### device-preparation.ps1

Version history for the device preparation script:

**1.5.0** (2026-04-10)

- Replaced logging function with Write-Log
- Added FullLanguage mode check
- Added Set-StrictMode
- Added OS version logging
- Added exit codes
- Updated script headers
- Verified with strict PSScriptAnalyzer profile

**1.4.3** (2025-12-17)

- Added Features bitmask parameter for granular feature control

**1.4.2** (2025-12-17)

- Added WhatIf support
- Added execution summary
- Added NetBIOS character validation
- Improved error handling

**1.4.1** (2025-12-17)

- Fixed typos
- Added parameter validation
- Improved documentation
- Standardized error handling

**1.4.0** (2025-05-09)

- Initial public release

### defender-update.ps1

Version history for the Microsoft Defender Antivirus update script:

**1.0.0** (2026-08-27)

- Initial release

## License and disclaimer

This project is licensed under the MIT License - see the [LICENSE](../../../../LICENSE) file for details.

This script is provided "as-is" without warranty of any kind. The author(s) and contributor(s) are not liable for any damages arising from its use. Before production use, test thoroughly in a non-production environment, modify as needed for your specific requirements, and review all registry and system changes.

By using this script, you acknowledge that you understand and accept these terms and assume all risks associated with its use.

[![Jesper on Bluesky](https://img.shields.io/badge/follow-@dotjesper.bsky.social-whitesmoke?style=social&logo=bluesky)](https://bsky.app/profile/dotjesper.bsky.social/ "Follow Jesper")
