<#
.SYNOPSIS
    Collect Windows last boot time

.DESCRIPTION
    Collect Windows last boot time, script will fail if exceeding threshold.

.PARAMETER ComputerMaximumUptimeThreshold
    Choose computer maximum up-time days threshold. Default is 7.

.EXAMPLE
    .\detect.ps1

.NOTES
    version: 1.2.5
    date: June 17, 2022
    license: MIT License

.LINK
    https://github.com/dotjesper/windows-kaleidoscope
#>

#requires -Version 5.1

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false, HelpMessage = 'Choose computer maximum up-time days threshold')]
    [ValidateRange(0, 30)]
    [int]$ComputerMaximumUptimeThreshold = 7
)

begin {
    Set-StrictMode -Version Latest

    # variables :: Conditions
    [bool]$runScriptIn64bitPowerShell = $false

    # variables :: Environment
    [datetime]$scriptStartTime = (Get-Date).ToUniversalTime()
}
process {
    #region :: Check conditions
    if ($runScriptIn64bitPowerShell -eq $true -and $([System.Environment]::Is64BitProcess) -eq $false) {
        Write-Error -Message 'Windows PowerShell 64-bit is required.' -Category 'ResourceUnavailable' -ErrorId 'B001'
        exit 1
    }
    #endregion

    #region :: main
    try {
        $lastBootUpTime = (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
        [int]$uptimeDays = ((Get-Date) - $lastBootUpTime).Days
        [string]$elapsedTime = ('{0:00.000}' -f ((Get-Date).ToUniversalTime() - $scriptStartTime).TotalSeconds) -replace ',', '.'
        if ($uptimeDays -ge $ComputerMaximumUptimeThreshold) {
            Write-Output -InputObject "[$elapsedTime] Device uptime has exceeded the defined $ComputerMaximumUptimeThreshold days uptime threshold - last boot $uptimeDays days ago - a restart is recommended."
            exit 1
        }
        else {
            Write-Output -InputObject "[$elapsedTime] Device uptime is within the defined $ComputerMaximumUptimeThreshold days uptime threshold - last boot $uptimeDays days ago."
            exit 0
        }
    }
    catch {
        $errorMessage = $_.Exception.Message
        Write-Error -Message $errorMessage -Category 'SyntaxError' -ErrorId 'C001'
        exit 1
    }
    finally {}
    #endregion
}
end {}
