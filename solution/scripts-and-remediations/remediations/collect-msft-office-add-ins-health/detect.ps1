<#
.SYNOPSIS
    Collect Microsoft Office add-in health information

.DESCRIPTION
    Collect Microsoft Office add-in resiliency data from the registry to identify add-ins that
    have been disabled by Office due to performance or stability issues. Office 2013 and later
    versions provide add-in resiliency: if a COM add-in causes slow startup, slow shutdown,
    crashes, or exceeds resource thresholds, Office disables it automatically.

    The script checks per-application resiliency registry keys for Office 16.0 (Microsoft 365,
    Office 2016, Office 2019, Office 2021, and Office 2024):
    - HKCU:\SOFTWARE\Microsoft\Office\16.0\<App>\Resiliency\DisabledItems (disabled add-ins)
    - HKCU:\SOFTWARE\Microsoft\Office\16.0\<App>\Resiliency\DoNotDisableAddinList (user re-enabled)
    - HKCU:\SOFTWARE\Microsoft\Office\16.0\<App>\Resiliency\NotificationReminderAddinData (slow add-ins)

    When a user re-enables a disabled add-in via the "Always enable this add-in" option, the
    add-in ProgID is written to DoNotDisableAddinList with a DWORD value indicating the original
    disable reason (crash, slow shutdown, boot load, etc.).

    Add-in performance events are also logged in the Application Event log under Event ID 45
    (load times) and Event ID 59 (disabled add-ins).

    The detection reports non-compliant (exit 1) when one or more add-ins have been disabled
    by Office due to performance or stability issues.

.EXAMPLE
    .\detect.ps1

    Collect Office add-in health data and report status.

.NOTES
    version: 1.0.0
    date: April 13, 2026
    license: MIT License

.LINK
    https://github.com/dotjesper/windows-kaleidoscope
#>

#requires -Version 5.1

[CmdletBinding()]
param ()

begin {
    Set-StrictMode -Version Latest

    #variables :: conditions
    [bool]$runScriptIn64bitPowerShell = $false
    [bool]$runUsingLoggedOnCredentials = $true

    #variables :: environment
    [string]$regRoot = 'HKCU'
    [string]$regPathResiliency = 'SOFTWARE\Microsoft\Office\16.0'
    [array]$officeApplications = @('Excel', 'Outlook', 'PowerPoint', 'Word')
    [int]$disabledAddInCount = 0
    [string]$outputText = ''
    [datetime]$scriptStartTime = (Get-Date).ToUniversalTime()
}
process {
    #region :: check conditions
    if ($runScriptIn64bitPowerShell -eq $true -and $([System.Environment]::Is64BitProcess) -eq $false) {
        Write-Error -Message 'Windows PowerShell 64-bit is required.' -Category 'ResourceUnavailable' -ErrorId 'B001'
        exit 1
    }
    if ($runUsingLoggedOnCredentials -eq $true -and $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name -eq 'NT AUTHORITY\SYSTEM')) {
        Write-Error -Message 'Script is running as SYSTEM. Please run the script as user.' -Category 'ResourceUnavailable' -ErrorId 'B002'
        exit 1
    }
    #endregion

    #region :: main logic
    try {
        foreach ($officeApp in $officeApplications) {
            #region :: check for disabled add-ins
            [string]$disabledItemsPath = "$regPathResiliency\$officeApp\Resiliency\DisabledItems"
            if (Test-Path -Path $($regRoot + ':\' + $disabledItemsPath)) {
                [array]$disabledItems = Get-ItemProperty -Path "Registry::$regRoot\$disabledItemsPath"
                [array]$disabledProperties = $disabledItems.PSObject.Properties | Where-Object { $_.Name -notmatch '^PS' }
                if ($disabledProperties.Count -gt 0) {
                    [int]$disabledAddInCount = $disabledAddInCount + $disabledProperties.Count
                    [string]$outputText = "$outputText $officeApp disabled: $($disabledProperties.Count)."
                }
            }
            #endregion

            #region :: check for add-in load time notifications
            [string]$notificationPath = "$regPathResiliency\$officeApp\Resiliency\NotificationReminderAddinData"
            if (Test-Path -Path $($regRoot + ':\' + $notificationPath)) {
                [array]$notificationItems = Get-ItemProperty -Path "Registry::$regRoot\$notificationPath"
                [array]$notificationProperties = $notificationItems.PSObject.Properties | Where-Object { $_.Name -notmatch '^PS' }
                if ($notificationProperties.Count -gt 0) {
                    [string]$outputText = "$outputText $officeApp slow add-ins: $($notificationProperties.Count)."
                }
            }
            #endregion

            #region :: check for re-enabled add-ins
            [string]$doNotDisablePath = "$regPathResiliency\$officeApp\Resiliency\DoNotDisableAddinList"
            if (Test-Path -Path $($regRoot + ':\' + $doNotDisablePath)) {
                [array]$reenabledItems = Get-ItemProperty -Path "Registry::$regRoot\$doNotDisablePath"
                [array]$reenabledProperties = $reenabledItems.PSObject.Properties | Where-Object { $_.Name -notmatch '^PS' }
                if ($reenabledProperties.Count -gt 0) {
                    [string]$outputText = "$outputText $officeApp re-enabled: $($reenabledProperties.Count)."
                }
            }
            #endregion
        }

        #region :: build final output
        [string]$elapsedTime = ('{0:00.000}' -f ((Get-Date).ToUniversalTime() - $scriptStartTime).TotalSeconds) -replace ',', '.'

        if ($disabledAddInCount -gt 0) {
            Write-Output -InputObject "[$elapsedTime] Add-ins disabled by Office ($disabledAddInCount).$outputText"
            exit 1
        }
        else {
            if ($outputText -ne '') {
                Write-Output -InputObject "[$elapsedTime] No disabled add-ins found.$outputText"
            }
            else {
                Write-Output -InputObject "[$elapsedTime] No disabled add-ins found. No resiliency data detected."
            }
            exit 0
        }
        #endregion
    }
    catch {
        $errMsg = $_.Exception.Message
        Write-Error -Message $errMsg -Category 'SyntaxError' -ErrorId 'C001'
        exit 1
    }
    finally {}
    #endregion
}
end {}
