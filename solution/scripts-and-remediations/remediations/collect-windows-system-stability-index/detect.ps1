#requires -Version 5.1
<#
.SYNOPSIS
    Collect Windows system stability index
.DESCRIPTION
    Based on the Reliability and Performance Monitor data. The Reliability Monitor will show users the System Stability Index for that day together with additional information, in case any important system events took place.
    This script will collect the Reliability and Performance Monitor data and based on the avarage systemStabilityIndex avaliable and score this from 1 to 10.
.PARAMETER reliabilityStabilityThreshold
    Defines the minimum reliability stability average value for script to report 'failed'. Default is 4.
.EXAMPLE
    .\detect.ps1
.NOTES
    version: 1.2.4.2
    date: May 18, 2022
    license: MIT License
.LINK
    [Jesper on Bluesky](https://bsky.app/profile/dotjesper.bsky.social "Jesper on Bluesky")
    [Jesper on GitHub](https://github.com/dotjesper/ "Jesper on GitHub")
#>
[CmdletBinding()]
param (
    #variables
    [Parameter (Mandatory = $False, HelpMessage = "Choose reliability stability threshold") ]
    [ValidateRange(1,10)]
    [int]$reliabilityStabilityThreshold = 4
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
        [array]$ReliabilityStabilityMetrics = Get-Ciminstance -ClassName Win32_ReliabilityStabilityMetrics | Measure-Object -Average -Maximum  -Minimum -Property systemStabilityIndex
        $reliabilityStabilityAverage = [math]::Round($($reliabilityStabilityMetrics.Average), 2)
        $reliabilityStabilityMaximum = [math]::Round($($reliabilityStabilityMetrics.Maximum), 2)
        $reliabilityStabilityMinimum = [math]::Round($($reliabilityStabilityMetrics.Minimum), 2)
        if ($($reliabilityStabilityMetrics.Average) -gt $reliabilityStabilityThreshold) {
            Write-Output -InputObject "Reliability index is above the index threshold (Avr $reliabilityStabilityAverage Max $reliabilityStabilityMaximum Min $reliabilityStabilityMinimum)"
            exit 0
        }
        else {
            Write-Output -InputObject "Reliability index is below the index threshold (Avr $reliabilityStabilityAverage Max $reliabilityStabilityMaximum Min $reliabilityStabilityMinimum)"
            exit 1
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
