#requires -Version 5.1
<#
.SYNOPSIS
    Detect Automatically Adjust Active Hours setting
.DESCRIPTION
    Starting with Windows 10 build 14316, users can set the time in which they are most active on their device by changing active hours.
    utomatically Adjust Active Hours lets Windows know when users usually use this device.
.EXAMPLE
    .\detect.ps1
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
            if ($regValues.SmartActiveHoursState -eq 1) {
                Write-Output -InputObject "Automatically Adjust Active Hours settings enabled ($($regValues.SmartActiveHoursState))"
                exit 0
            }
            elseif ($($regValues.SmartActiveHoursState) -eq 2) {
                Write-Output -InputObject "Automatically Adjust Active Hours overruled by user ($($regValues.SmartActiveHoursState))"
                exit 1
            }
            else {
                Write-Output -InputObject "Automatically Adjust Active Hours settings not enabled ($($regValues.SmartActiveHoursState))"
                exit 1
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
