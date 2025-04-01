#requires -Version 5.1
<#
.SYNOPSIS
    Turn On Automatically Adjust Active Hours setting
.DESCRIPTION
    Starting with Windows 10 build 14316, users can set the time in which they are most active on their device by changing active hours.
    utomatically Adjust Active Hours lets Windows know when users usually use this device.
    When a restart is necessary to finish installing an update, Windows won't automatically restart your device during active hours.
.EXAMPLE
    .\remediate.ps1
.NOTES
    version: 1.2.0.2
    date: April 15, 2021
    license: MIT License
.LINK
    [Jesper on Bluesky](https://bsky.app/profile/dotjesper.bsky.social "Jesper on Bluesky")
    [Jesper on GitHub](https://github.com/dotjesper/ "Jesper on GitHub")
#>
[CmdletBinding()]
param (
    #variables
    [string]$regRoot = "HKLM",
    [string]$regPath = "SOFTWARE\Microsoft\WindowsUpdate\UX\Settings"
)
begin {
    #variables :: conditions
    [bool]$runScriptIn64bitPowerShell = $true
    #variables :: environment
}
process {
    #region check conditions
    if ($runScriptIn64bitPowerShell -eq $true -and $([System.Environment]::Is64BitProcess) -eq $false) {
        Write-Error -Message "Windows PowerShell 64-bit is requered." -Category "ResourceUnavailable" -ErrorId "B001"
        exit 1
    }
    #endregion
    try {
        if (Test-Path -Path $($regRoot + ":\" + $regPath)) {
            [array]$regValues = Get-ItemProperty -Path "Registry::$regRoot\$regPath"
            if ($($regValues.SmartActiveHoursState) -ne 1) {
                Write-Output -InputObject "Enabling Automatically Adjust Active Hours settings ($($regValues.SmartActiveHoursState)$($regValues.SmartActiveHoursSuggestionState)$($regValues.SmartActiveHoursStart)$($regValues.SmartActiveHoursEnd))"
                $null = New-ItemProperty -Path "Registry::$regRoot\$regPath" -Name "SmartActiveHoursState" -Value 1 -PropertyType "DWORD" -Force
                $null = New-ItemProperty -Path "Registry::$regRoot\$regPath" -Name "SmartActiveHoursSuggestionState" -Value 0 -PropertyType "DWORD" -Force
                $null = New-ItemProperty -Path "Registry::$regRoot\$regPath" -Name "ActiveHoursStart" -Value $($regValues.SmartActiveHoursStart) -PropertyType "DWORD" -Force
                $null = New-ItemProperty -Path "Registry::$regRoot\$regPath" -Name "ActiveHoursEnd" -Value $($regValues.SmartActiveHoursEnd) -PropertyType "DWORD" -Force
            }
            else {
                Write-Output -InputObject "Automatically Adjust Active Hours settings enabled ($($regValues.SmartActiveHoursState)$($regValues.SmartActiveHoursSuggestionState)$($regValues.SmartActiveHoursStart)$($regValues.SmartActiveHoursEnd))"
            }
        }
        else {
            Write-Output -InputObject "Automatically Adjust Active Hours settings not avaliable ($((Get-CimInstance -ClassName WIn32_OperatingSystem).OSArchitecture))"
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
