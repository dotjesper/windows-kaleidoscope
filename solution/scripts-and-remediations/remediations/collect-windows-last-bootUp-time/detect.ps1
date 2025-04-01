#requires -Version 5.1
<#
.SYNOPSIS
    Collect Windows last boot time
.DESCRIPTION
    Collect Windows last boot time, script will fail if exceeding threshold.
.PARAMETER computerMaximumUptimeThreshold
    Choose computer maximum up-time days threshold. Default is 7.
.EXAMPLE
    .\detect.ps1
.NOTES
    version: 1.2.2.1
    date: June 17, 2022
    license: MIT License
.LINK
    [Jesper on Bluesky](https://bsky.app/profile/dotjesper.bsky.social "Jesper on Bluesky")
    [Jesper on GitHub](https://github.com/dotjesper/ "Jesper on GitHub")
#>
[CmdletBinding()]
param (
    #variables
    [Parameter (Mandatory = $False, HelpMessage = "Choose computer maximum up-time days threshold") ]
    [ValidateRange(0,30)]
    [int]$computerMaximumUptimeThreshold = 7
)
begin {
    #variables :: conditions
    [bool]$runScriptIn64bitPowerShell = $false
    #variables :: environment
}
process {
    #region check conditions
    if ($runScriptIn64bitPowerShell -eq $true -and $([System.Environment]::Is64BitProcess) -eq $false) {
        Write-Error -Message "Windows PowerShell 64-bit is requered." -Category "ResourceUnavailable" -ErrorId "B001"
        exit 1
    }
    try {
        $computerUptime = Get-ComputerInfo -Property OSUptime
        if ($computerUptime.OsUptime.Days -ge $computerMaximumUptimeThreshold) {
            Write-Output -InputObject "Device uptime has exceeded the defined $computerMaximumUptimeThreshold days uptime threshold - last boot $($computerUptime.OsUptime.Days) days ago - a restart is recomended."
            exit 1
        }
        else {
            Write-Output -InputObject "Device uptime is within the defined $computerMaximumUptimeThreshold days uptime threshold - last boot $($computerUptime.OsUptime.Days) days ago."
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
