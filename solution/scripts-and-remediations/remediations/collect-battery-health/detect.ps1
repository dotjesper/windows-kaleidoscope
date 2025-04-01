#requires -Version 5.1
<#
.SYNOPSIS
    Collect presence of battery and collect battery health
.DESCRIPTION
    Actively collect the battery health throughout Windows devices, allowing proactive battery replacement prior to have to remediate battery issues reactively.
.PARAMETER batteryHealthThreshold
    Define mminimum battery health threshold. Valid range 0-100
.EXAMPLE
    .\detect.ps1
.NOTES
    version: 1.2.0.2
    date: May 17, 2023
    license: MIT License
.LINK
    [Jesper on Bluesky](https://bsky.app/profile/dotjesper.bsky.social "Jesper on Bluesky")
    [Jesper on GitHub](https://github.com/dotjesper/ "Jesper on GitHub")
#>
[CmdletBinding()]
param (
    #variables
    [Parameter (Mandatory = $False, HelpMessage = "Choose battery health threshold") ]
    [ValidateRange(0,100)]
    [int]$batteryHealthThreshold = 40
)
begin {
    #variables :: conditions
    [bool]$runScriptIn64bitPowerShell = $false
    #variables :: environment
    [int]$batteryReplaceCounter = 0
}
process {
    #region check conditions
    if ($runScriptIn64bitPowerShell -eq $true -and $([System.Environment]::Is64BitProcess) -eq $false) {
        Write-Error -Message "Windows PowerShell 64-bit is requered." -Category "ResourceUnavailable" -ErrorId "B001"
        exit 1
    }
    #endregion
    try {
        if (Get-CimInstance -ClassName win32_battery) {
            #region get battery information
            try {
                $win32_batteryDeviceIDs = Get-CimInstance -ClassName Win32_Battery -Namespace ROOT/CIMV2:CIM_Battery | Select-Object -ExpandProperty DeviceID
                $batteryReplaceText = "Batteries found: $($win32_batteryDeviceIDs.Count)"
            }
            catch {
                $errMsg = $_.Exception.Message
                Write-Error -Message $errMsg
                exit 1
            }
            finally {}
            #endregion
            #region get battery health
            foreach ($win32_batteryDeviceID in $win32_batteryDeviceIDs) {
                try {
                    $batteryInstanceName = Get-WmiObject -Class "BatteryStaticData" -Namespace "ROOT\WMI" | Where-Object { $_.UniqueID -eq $win32_batteryDeviceID } | Select-Object -ExpandProperty InstanceName
                    $batteryDesignedCapacity = Get-WmiObject -Class "BatteryStaticData" -Namespace "ROOT\WMI" | Where-Object { $_.InstanceName -eq $batteryInstanceName } | Select-Object -ExpandProperty DesignedCapacity

                    $batteryFullChargedCapacity = Get-WmiObject -Class "BatteryFullChargedCapacity" -Namespace "ROOT\WMI" | Where-Object { $_.InstanceName -eq $batteryInstanceName } | Select-Object -ExpandProperty FullChargedCapacity

                    
                    #$batteryDesignedCapacity = (Get-CimInstance -Namespace ROOT\WMI -ClassName "BatteryStaticData").DesignedCapacity !!!
                    #$batteryFullChargedCapacity = (Get-CimInstance -Namespace ROOT\WMI -ClassName "BatteryFullChargedCapacity").FullChargedCapacity
                    #$batteryFullChargedCapacity = (Get-CimInstance -Namespace ROOT\WMI -ClassName "BatteryFullChargedCapacity"
                    #https://garytown.com/gathering-battery-information-via-powershell-wmi
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
                [string]$batteryReplaceText = "$batteryReplaceText" + ", " + "$batteryHealth" + "%"
            }
            if ($batteryReplaceCounter -gt 0) {
                Write-Output -InputObject "Battery replacement required ($batteryReplaceText)"
                exit 1
            }
            else {
                Write-Output -InputObject "Battery replacement not required ($batteryReplaceText)"
                exit 0
            }
            #endregion
        }
        else {
            Write-Output -InputObject "Battery not found or unable to obtain battery information from WMI!"
            exit 0
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
