---
Title: README
Date: April 13, 2026
Author: dotjesper
Status: In development
---

[![Built for Windows 11](https://img.shields.io/badge/Built%20for%20Windows%2011-Yes-blue?style=flat)](https://windows.com/ "Built for Windows 11")
[![Built for Windows 10](https://img.shields.io/badge/Built%20for%20Windows%2010-Yes-blue?style=flat)](https://windows.com/ "Built for Windows 10")

[![PSScriptAnalyzer verified](https://img.shields.io/badge/PowerShell%20Script%20Analyzer%20verified-Yes-green?style=flat)](https://learn.microsoft.com/powershell/module/psscriptanalyzer/ "PowerShell Script Analyzer")
[![PowerShell Constrained Language mode verified](https://img.shields.io/badge/PowerShell%20Constrained%20Language%20mode%20verified-Yes-green?style=flat)](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_language_modes/ "PowerShell Language mode")
[![Strict Mode verified](https://img.shields.io/badge/Strict%20Mode%20verified-Yes-green?style=flat)](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/set-strictmode/ "Set-StrictMode -Version latest")

# Microsoft Intune remediation: Monitor pending reboots

Detect pending reboots on Windows devices and notify the user when a reboot has been pending beyond a configurable threshold. Uses a marker-based approach: the detection script tracks how long a reboot has been pending and respects a notification cooldown period, while the remediation script displays a toast notification and writes a cooldown marker to prevent repeated notifications.

## Script package information

External logging: **No**

## How it works

The package uses registry markers at `HKCU\SOFTWARE\windows-kaleidoscope\monitor-pending-reboots` to track pending reboot state across runs:

1. **First detection** - When a pending reboot is found for the first time, the detection script creates `FirstSeenDate` and `LastBootDate` markers and exits compliant (grace period).
2. **Grace period** - The device remains compliant until the pending reboot has persisted for longer than the configured threshold (default: 5 days).
3. **Threshold exceeded** - Once the grace period expires and no recent notification has been sent, the detection script exits non-compliant, triggering remediation.
4. **Notification** - The remediation script displays a toast notification asking the user to restart, then writes a `NotificationSentDate` marker.
5. **Post-remediation check** - The detection script recognizes the fresh notification marker and exits compliant, so Microsoft Intune reports remediation as successful.
6. **Cooldown** - The notification cooldown (default: 3 days) prevents repeated notifications. After the cooldown expires, the cycle repeats if the reboot is still pending.
7. **Reboot resets markers** - If the device reboots, the detection script detects the changed boot time and clears all markers.

### Pending reboot sources

The detection script checks the following registry locations:

- `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending`
- `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootInProgress`
- `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\PackagesPending`
- `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired`
- `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\PostRebootReporting`
- `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Services\Pending` (GUID subkeys)
- `HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\PendingFileRenameOperations`
- `HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\PendingFileRenameOperations2`
- `HKLM\SOFTWARE\Microsoft\Updates\UpdateExeVolatile` (value is not 0)
- `HKLM\SYSTEM\CurrentControlSet\Services\Netlogon\JoinDomain`
- `HKLM\SYSTEM\CurrentControlSet\Services\Netlogon\AvoidSpnSet`
- `HKLM\SYSTEM\CurrentControlSet\Control\ComputerName\ActiveComputerName` vs `ComputerName` (pending rename)

### Notification hero image

The remediation script displays a toast notification that optionally includes a hero image. The image is embedded as a Base64-encoded string in the `$base64HeroImage` variable in `remediate.ps1`. When the variable is empty (default), the notification displays without a hero image. When a Base64 string is provided, the script decodes it and writes it to `%TEMP%\pendingRebootHeroImage.png` before displaying the notification.

#### Image requirements

- **Format:** PNG
- **Recommended size:** 364 x 180 pixels (Windows toast hero image dimensions)
- **Maximum file size:** Keep the source PNG under 150 KB to avoid excessive script size after encoding
- **Content:** Use a simple branded banner — avoid small text as hero images render at varying DPI scales

#### Converting a PNG to Base64

Use PowerShell to convert a PNG file to a Base64 string:

```powershell
[System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes('C:\path\to\hero-image.png')) | Set-Clipboard
```

This copies the Base64 string to the clipboard. Paste it as the value of `$base64HeroImage` in `remediate.ps1`.

To verify an existing Base64 string by decoding it back to a file:

```powershell
[System.IO.File]::WriteAllBytes('C:\temp\preview.png', [System.Convert]::FromBase64String($base64HeroImage))
```

#### Replacing the image

1. Prepare a PNG image at 364 x 180 pixels
2. Convert it to a Base64 string using the command above
3. Replace the value of `$base64HeroImage` in `remediate.ps1` with the new string
4. Test the notification in a Windows Sandbox or non-production device to verify the image renders correctly

> **Note:** The Base64 conversion commands use .NET types (`[System.Convert]`, `[System.IO.File]`) that are blocked under Constrained Language Mode. Run these commands in a local development environment, not on a managed device. The encoded string itself is safe to embed in the remediation script.

## Script package properties

### Basic

Name: **Monitor pending reboots**

Description: **Detect pending reboots and notify the user when a reboot has been pending beyond the configured threshold.**

Publisher: **Jesper Nielsen**

### Settings

Detection script: **Yes**

Remediation script: **Yes**

Run this script using the logged-on credentials: **Yes**

Enforce script signature check: **No**

Run script in 64-bit PowerShell: **Yes**

### Assignments

Schedule: **Daily**

## Expected output

### detect.ps1

| Exit code | Output |
|:---------:|:-------|
| `exit 0` | `[00.000] No pending reboot detected.` |
| `exit 0` | `[00.000] Pending reboot detected (WindowsUpdate) - first seen, within 3 day grace period.` |
| `exit 0` | `[00.000] Pending reboot detected (WindowsUpdate) - pending for 2 days, within 3 day grace period.` |
| `exit 1` | `[00.000] Pending reboot detected (WindowsUpdate, ComponentServicing) - pending for 5 days, notification required.` |
