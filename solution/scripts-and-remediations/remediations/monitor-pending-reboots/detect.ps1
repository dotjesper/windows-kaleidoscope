<#
.SYNOPSIS
    Detect pending reboots

.DESCRIPTION
    Detect pending reboots from multiple Windows sources including Component Based
    Servicing, Windows Update, pending file rename operations, update volatile flags,
    Netlogon domain join state, and pending computer renames. Uses a configurable
    grace period before reporting non-compliant and respects a notification cooldown
    marker written by the remediation script to prevent repeated remediation failures.

.PARAMETER pendingRebootThresholdDays
    Number of days a pending reboot must persist before reporting non-compliant.
    Default is 5. Set to 0 to report non-compliant immediately.

.PARAMETER notificationCooldownDays
    Number of days after a user notification before re-triggering remediation.
    Default is 3.

.EXAMPLE
    .\detect.ps1

    Detects pending reboots and reports non-compliant if the reboot has been pending
    beyond the configured threshold and no recent notification has been sent.

.NOTES
    version: 1.0.0
    date: April 13, 2025
    license: MIT License

.LINK
    https://github.com/dotjesper/windows-kaleidoscope
#>

#requires -Version 5.1

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false, HelpMessage = 'Number of days before a pending reboot triggers non-compliant')]
    [ValidateRange(0, 30)]
    [int]$pendingRebootThresholdDays = 5,

    [Parameter(Mandatory = $false, HelpMessage = 'Number of days after notification before re-triggering remediation')]
    [ValidateRange(1, 14)]
    [int]$notificationCooldownDays = 3
)

begin {
    Set-StrictMode -Version Latest

    #variables :: conditions
    [bool]$runScriptIn64bitPowerShell = $true
    [bool]$runUsingLoggedOnCredentials = $true

    #variables :: environment
    [string]$markerRegRoot = 'HKCU'
    [string]$markerRegPath = 'SOFTWARE\windows-kaleidoscope\monitor-pending-reboots'
    [datetime]$scriptStartTime = (Get-Date).ToUniversalTime()
}
process {
    #region :: check conditions
    if ($runScriptIn64bitPowerShell -eq $true -and $([System.Environment]::Is64BitProcess) -eq $false) {
        Write-Error -Message 'Windows PowerShell 64-bit is required.' -Category 'ResourceUnavailable' -ErrorId 'B001'
        exit 1
    }
    if ($runUsingLoggedOnCredentials -eq $true -and $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name -eq 'NT AUTHORITY\SYSTEM')) {
        Write-Error -Message 'Script is running as SYSTEM. Please configure the script to run using logged-on credentials.' -Category 'ResourceUnavailable' -ErrorId 'B002'
        exit 1
    }
    #endregion

    #region :: main logic
    try {
        #region :: check pending reboot sources
        [bool]$pendingRebootFound = $false
        [array]$pendingRebootSources = @()

        # Component Based Servicing - RebootPending
        [string]$cbsRegRoot = 'HKLM'
        [string]$cbsRegPath = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending'
        if (Test-Path -Path $($cbsRegRoot + ':\' + $cbsRegPath)) {
            $pendingRebootFound = $true
            $pendingRebootSources += 'Component Based Servicing'
        }

        # Windows Update - RebootRequired
        [string]$wuRegRoot = 'HKLM'
        [string]$wuRegPath = 'SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired'
        if (Test-Path -Path $($wuRegRoot + ':\' + $wuRegPath)) {
            $pendingRebootFound = $true
            $pendingRebootSources += 'Windows Update'
        }

        # Session Manager - PendingFileRenameOperations and PendingFileRenameOperations2
        [string]$smRegRoot = 'HKLM'
        [string]$smRegPath = 'SYSTEM\CurrentControlSet\Control\Session Manager'
        if (Test-Path -Path $($smRegRoot + ':\' + $smRegPath)) {
            $pfroProp = Get-ItemProperty -Path "Registry::$smRegRoot\$smRegPath" -Name 'PendingFileRenameOperations' -ErrorAction SilentlyContinue
            if ($pfroProp) {
                $pendingRebootFound = $true
                $pendingRebootSources += 'Pending File Rename Operations'
            }
            $pfro2Prop = Get-ItemProperty -Path "Registry::$smRegRoot\$smRegPath" -Name 'PendingFileRenameOperations2' -ErrorAction SilentlyContinue
            if ($pfro2Prop) {
                $pendingRebootFound = $true
                if ($pendingRebootSources -notcontains 'Pending File Rename Operations') {
                    $pendingRebootSources += 'Pending File Rename Operations'
                }
            }
        }

        # Component Based Servicing - RebootInProgress
        [string]$cbsRipRegPath = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootInProgress'
        if (Test-Path -Path $($cbsRegRoot + ':\' + $cbsRipRegPath)) {
            $pendingRebootFound = $true
            if ($pendingRebootSources -notcontains 'Component Based Servicing') {
                $pendingRebootSources += 'Component Based Servicing'
            }
        }

        # Component Based Servicing - PackagesPending
        [string]$cbsPpRegPath = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\PackagesPending'
        if (Test-Path -Path $($cbsRegRoot + ':\' + $cbsPpRegPath)) {
            $pendingRebootFound = $true
            if ($pendingRebootSources -notcontains 'Component Based Servicing') {
                $pendingRebootSources += 'Component Based Servicing'
            }
        }

        # Windows Update - PostRebootReporting
        [string]$wuPrrRegPath = 'SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\PostRebootReporting'
        if (Test-Path -Path $($wuRegRoot + ':\' + $wuPrrRegPath)) {
            $pendingRebootFound = $true
            if ($pendingRebootSources -notcontains 'Windows Update') {
                $pendingRebootSources += 'Windows Update'
            }
        }

        # Windows Update - Services Pending
        [string]$wuSpRegPath = 'SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Services\Pending'
        if (Test-Path -Path $($wuRegRoot + ':\' + $wuSpRegPath)) {
            $wuSpChildren = Get-ChildItem -Path "Registry::$wuRegRoot\$wuSpRegPath" -ErrorAction SilentlyContinue
            if ($wuSpChildren) {
                $pendingRebootFound = $true
                if ($pendingRebootSources -notcontains 'Windows Update') {
                    $pendingRebootSources += 'Windows Update'
                }
            }
        }

        # Updates - UpdateExeVolatile
        [string]$updRegRoot = 'HKLM'
        [string]$updRegPath = 'SOFTWARE\Microsoft\Updates'
        if (Test-Path -Path $($updRegRoot + ':\' + $updRegPath)) {
            $uevProp = Get-ItemProperty -Path "Registry::$updRegRoot\$updRegPath" -Name 'UpdateExeVolatile' -ErrorAction SilentlyContinue
            if ($uevProp -and $uevProp.UpdateExeVolatile -ne 0) {
                $pendingRebootFound = $true
                $pendingRebootSources += 'Update Exe Volatile'
            }
        }

        # Netlogon - JoinDomain and AvoidSpnSet
        [string]$nlRegRoot = 'HKLM'
        [string]$nlRegPath = 'SYSTEM\CurrentControlSet\Services\Netlogon'
        if (Test-Path -Path $($nlRegRoot + ':\' + $nlRegPath)) {
            $jdProp = Get-ItemProperty -Path "Registry::$nlRegRoot\$nlRegPath" -Name 'JoinDomain' -ErrorAction SilentlyContinue
            if ($jdProp) {
                $pendingRebootFound = $true
                $pendingRebootSources += 'Netlogon'
            }
            $asProp = Get-ItemProperty -Path "Registry::$nlRegRoot\$nlRegPath" -Name 'AvoidSpnSet' -ErrorAction SilentlyContinue
            if ($asProp) {
                $pendingRebootFound = $true
                if ($pendingRebootSources -notcontains 'Netlogon') {
                    $pendingRebootSources += 'Netlogon'
                }
            }
        }

        # Computer Name Change Pending
        [string]$cnRegRoot = 'HKLM'
        [string]$cnActiveRegPath = 'SYSTEM\CurrentControlSet\Control\ComputerName\ActiveComputerName'
        [string]$cnPendingRegPath = 'SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName'
        if ((Test-Path -Path $($cnRegRoot + ':\' + $cnActiveRegPath)) -and (Test-Path -Path $($cnRegRoot + ':\' + $cnPendingRegPath))) {
            $activeName = Get-ItemProperty -Path "Registry::$cnRegRoot\$cnActiveRegPath" -Name 'ComputerName' -ErrorAction SilentlyContinue
            $pendingName = Get-ItemProperty -Path "Registry::$cnRegRoot\$cnPendingRegPath" -Name 'ComputerName' -ErrorAction SilentlyContinue
            if ($activeName -and $pendingName -and ($activeName.ComputerName -ne $pendingName.ComputerName)) {
                $pendingRebootFound = $true
                $pendingRebootSources += 'Computer Rename'
            }
        }
        #endregion

        #region :: evaluate pending reboot state
        if ($pendingRebootFound -eq $false) {
            # no pending reboot - clean up markers if present
            if (Test-Path -Path $($markerRegRoot + ':\' + $markerRegPath)) {
                Remove-Item -Path "Registry::$markerRegRoot\$markerRegPath" -Force
            }
            [string]$elapsedTime = ('{0:00.000}' -f ((Get-Date).ToUniversalTime() - $scriptStartTime).TotalSeconds) -replace ',', '.'
            Write-Output -InputObject "[$elapsedTime] No pending reboot detected."
            exit 0
        }

        # pending reboot detected
        [string]$sourcesList = $pendingRebootSources -join ', '
        [string]$currentBootDate = Get-Date -Date (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime -Format 'yyyy-MM-ddTHH:mm:ss'

        # check if marker registry key exists
        if (-not (Test-Path -Path $($markerRegRoot + ':\' + $markerRegPath))) {
            # first detection - create marker with first seen date and boot date
            $null = New-Item -Path "Registry::$markerRegRoot\$markerRegPath" -Force
            $null = New-ItemProperty -Path "Registry::$markerRegRoot\$markerRegPath" -Name 'FirstSeenDate' -Value (Get-Date -Format 'yyyy-MM-ddTHH:mm:ss') -PropertyType 'String' -Force
            $null = New-ItemProperty -Path "Registry::$markerRegRoot\$markerRegPath" -Name 'LastBootDate' -Value $currentBootDate -PropertyType 'String' -Force
            [string]$elapsedTime = ('{0:00.000}' -f ((Get-Date).ToUniversalTime() - $scriptStartTime).TotalSeconds) -replace ',', '.'
            Write-Output -InputObject "[$elapsedTime] Pending reboot detected ($sourcesList) - first seen, within $pendingRebootThresholdDays day grace period."
            exit 0
        }

        # marker exists - check if device was rebooted since marker was created
        $storedBootProp = Get-ItemProperty -Path "Registry::$markerRegRoot\$markerRegPath" -Name 'LastBootDate' -ErrorAction SilentlyContinue
        if ($storedBootProp) {
            if ($storedBootProp.LastBootDate -ne $currentBootDate) {
                # device was rebooted since marker was written - reset markers for new pending reboot
                Remove-Item -Path "Registry::$markerRegRoot\$markerRegPath" -Recurse -Force
                $null = New-Item -Path "Registry::$markerRegRoot\$markerRegPath" -Force
                $null = New-ItemProperty -Path "Registry::$markerRegRoot\$markerRegPath" -Name 'FirstSeenDate' -Value (Get-Date -Format 'yyyy-MM-ddTHH:mm:ss') -PropertyType 'String' -Force
                $null = New-ItemProperty -Path "Registry::$markerRegRoot\$markerRegPath" -Name 'LastBootDate' -Value $currentBootDate -PropertyType 'String' -Force
                [string]$elapsedTime = ('{0:00.000}' -f ((Get-Date).ToUniversalTime() - $scriptStartTime).TotalSeconds) -replace ',', '.'
                Write-Output -InputObject "[$elapsedTime] Pending reboot detected ($sourcesList) - new pending reboot after device restart, within $pendingRebootThresholdDays day grace period."
                exit 0
            }
        }

        # same boot session - check grace period
        $firstSeenProp = Get-ItemProperty -Path "Registry::$markerRegRoot\$markerRegPath" -Name 'FirstSeenDate' -ErrorAction SilentlyContinue
        if (-not $firstSeenProp) {
            # marker key exists but FirstSeenDate is missing - write it now
            $null = New-ItemProperty -Path "Registry::$markerRegRoot\$markerRegPath" -Name 'FirstSeenDate' -Value (Get-Date -Format 'yyyy-MM-ddTHH:mm:ss') -PropertyType 'String' -Force
            $null = New-ItemProperty -Path "Registry::$markerRegRoot\$markerRegPath" -Name 'LastBootDate' -Value $currentBootDate -PropertyType 'String' -Force
            [string]$elapsedTime = ('{0:00.000}' -f ((Get-Date).ToUniversalTime() - $scriptStartTime).TotalSeconds) -replace ',', '.'
            Write-Output -InputObject "[$elapsedTime] Pending reboot detected ($sourcesList) - first seen, within $pendingRebootThresholdDays day grace period."
            exit 0
        }

        [int]$daysSinceFirstSeen = ((Get-Date) - (Get-Date -Date $firstSeenProp.FirstSeenDate)).Days
        if ($daysSinceFirstSeen -lt $pendingRebootThresholdDays) {
            [string]$elapsedTime = ('{0:00.000}' -f ((Get-Date).ToUniversalTime() - $scriptStartTime).TotalSeconds) -replace ',', '.'
            Write-Output -InputObject "[$elapsedTime] Pending reboot detected ($sourcesList) - pending for $daysSinceFirstSeen days, within $pendingRebootThresholdDays day grace period."
            exit 0
        }

        # grace period exceeded - check notification cooldown
        $notificationProp = Get-ItemProperty -Path "Registry::$markerRegRoot\$markerRegPath" -Name 'NotificationSentDate' -ErrorAction SilentlyContinue
        if ($notificationProp) {
            [int]$daysSinceNotification = ((Get-Date) - (Get-Date -Date $notificationProp.NotificationSentDate)).Days
            if ($daysSinceNotification -lt $notificationCooldownDays) {
                [string]$elapsedTime = ('{0:00.000}' -f ((Get-Date).ToUniversalTime() - $scriptStartTime).TotalSeconds) -replace ',', '.'
                Write-Output -InputObject "[$elapsedTime] Pending reboot detected ($sourcesList) - pending for $daysSinceFirstSeen days, user notified $daysSinceNotification days ago."
                exit 0
            }
        }

        # grace period exceeded and no fresh notification - trigger remediation
        [string]$elapsedTime = ('{0:00.000}' -f ((Get-Date).ToUniversalTime() - $scriptStartTime).TotalSeconds) -replace ',', '.'
        Write-Output -InputObject "[$elapsedTime] Pending reboot detected ($sourcesList) - pending for $daysSinceFirstSeen days, notification required."
        exit 1
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
