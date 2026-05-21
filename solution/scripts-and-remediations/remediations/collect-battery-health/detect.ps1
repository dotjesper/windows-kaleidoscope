<#
.SYNOPSIS
    Collect presence of battery and collect battery health

.DESCRIPTION
    Actively collect the battery health throughout Windows devices, allowing proactive battery replacement prior to have to remediate battery issues reactively.

.PARAMETER batteryHealthThreshold
    Define minimum battery health threshold. Valid range 0-100

.EXAMPLE
    .\detect.ps1

.NOTES
    version: 1.2.0
    date: May 17, 2023
    license: MIT License

.LINK
    https://github.com/dotjesper/windows-kaleidoscope
#>

#requires -Version 5.1

[CmdletBinding()]
param (
    #variables
    [Parameter (Mandatory = $False, HelpMessage = 'Choose battery health threshold') ]
    [ValidateRange(0, 100)]
    [int]$batteryHealthThreshold = 40
)

begin {
    Set-StrictMode -Version Latest

    # variables :: Conditions
    [bool]$runScriptIn64bitPowerShell = $false

    # variables :: Environment
    [int]$batteryReplaceCounter = 0
    [datetime]$scriptStartTime = (Get-Date).ToUniversalTime()
}
process {
    #region :: Check conditions
    if ($runScriptIn64bitPowerShell -eq $true -and $([System.Environment]::Is64BitProcess) -eq $false) {
        Write-Error -Message 'Windows PowerShell 64-bit is required.' -Category 'ResourceUnavailable' -ErrorId 'B001'
        exit 1
    }
    #endregion
    try {
        if (Get-CimInstance -ClassName win32_battery) {
            #region :: get battery information
            try {
                $win32_batteryDeviceIDs = Get-CimInstance -ClassName Win32_Battery -Namespace ROOT/CIMV2 | Select-Object -ExpandProperty DeviceID
                $batteryReplaceText = "Batteries found: $($win32_batteryDeviceIDs.Count)"
            }
            catch {
                $errMsg = $_.Exception.Message
                Write-Error -Message $errMsg
                exit 1
            }
            finally {}
            #endregion

            #region :: get battery health
            foreach ($win32_batteryDeviceID in $win32_batteryDeviceIDs) {
                try {
                    # ROOT\WMI battery classes require DCOM protocol - Get-CimInstance fails with these legacy WMI providers
                    $batteryInstanceName = Get-WmiObject -Class 'BatteryStaticData' -Namespace 'ROOT\WMI' | Where-Object { $_.UniqueID -eq $win32_batteryDeviceID } | Select-Object -ExpandProperty InstanceName
                    $batteryDesignedCapacity = Get-WmiObject -Class 'BatteryStaticData' -Namespace 'ROOT\WMI' | Where-Object { $_.InstanceName -eq $batteryInstanceName } | Select-Object -ExpandProperty DesignedCapacity
                    $batteryFullChargedCapacity = Get-WmiObject -Class 'BatteryFullChargedCapacity' -Namespace 'ROOT\WMI' | Where-Object { $_.InstanceName -eq $batteryInstanceName } | Select-Object -ExpandProperty FullChargedCapacity
                }
                catch {
                    $errMsg = $_.Exception.Message
                    Write-Error -Message $errMsg
                    exit 1
                }
                finally {}
                [int]$batteryHealth = ($batteryFullChargedCapacity / $batteryDesignedCapacity) * 100
                if ($batteryHealth -le $batteryHealthThreshold) {
                    [int]$batteryReplaceCounter = $batteryReplaceCounter + 1
                }
                [string]$batteryReplaceText = "$batteryReplaceText, $batteryHealth%"
            }
            [string]$elapsedTime = ('{0:00.000}' -f ((Get-Date).ToUniversalTime() - $scriptStartTime).TotalSeconds) -replace ',', '.'
            if ($batteryReplaceCounter -gt 0) {
                Write-Output -InputObject "[$elapsedTime] Battery replacement required ($batteryReplaceText)"
                exit 1
            }
            else {
                Write-Output -InputObject "[$elapsedTime] Battery replacement not required ($batteryReplaceText)"
                exit 0
            }
            #endregion
        }
        else {
            [string]$elapsedTime = ('{0:00.000}' -f ((Get-Date).ToUniversalTime() - $scriptStartTime).TotalSeconds) -replace ',', '.'
            Write-Output -InputObject "[$elapsedTime] Battery not found or unable to obtain battery information from WMI."
            exit 0
        }
    }
    catch {
        $errMsg = $_.Exception.Message
        Write-Error -Message $errMsg -Category 'SyntaxError' -ErrorId 'C001'
        exit 1
    }
    finally {}
}
end {}
