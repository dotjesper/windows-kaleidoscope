<#
.SYNOPSIS
    Collect Windows system stability index
.DESCRIPTION
    Based on the Reliability and Performance Monitor data. The Reliability Monitor will show users the System Stability Index for that day together with additional information, in case any important system events took place.
    This script will collect the Reliability and Performance Monitor data and based on the average systemStabilityIndex available and score this from 1 to 10.
.PARAMETER reliabilityStabilityThreshold
    Defines the minimum reliability stability average value for script to report 'failed'. Default is 4.
.EXAMPLE
    .\detect.ps1
.NOTES
    version: 1.2.4
    date: May 18, 2022
    license: MIT License
.LINK
    https://github.com/dotjesper/windows-kaleidoscope
#>

#requires -Version 5.1

[CmdletBinding()]
param (
    [Parameter (Mandatory = $False, HelpMessage = 'Choose reliability stability threshold')]
    [ValidateRange(1, 10)]
    [int]$reliabilityStabilityThreshold = 4
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

    #region :: Main logic
    try {
        # Get the average, maximum and minimum system stability index from the Reliability and Performance Monitor data
        [array]$ReliabilityStabilityMetrics = Get-CimInstance -ClassName Win32_ReliabilityStabilityMetrics | Measure-Object -Average -Maximum -Minimum -Property systemStabilityIndex
        [string]$reliabilityStabilityAverage = '{0:N2}' -f $ReliabilityStabilityMetrics.Average
        [string]$reliabilityStabilityMaximum = '{0:N2}' -f $ReliabilityStabilityMetrics.Maximum
        [string]$reliabilityStabilityMinimum = '{0:N2}' -f $ReliabilityStabilityMetrics.Minimum

        # Compare the average system stability index with the threshold and output the result
        [string]$elapsedTime = ('{0:00.000}' -f ((Get-Date).ToUniversalTime() - $scriptStartTime).TotalSeconds) -replace ',', '.'
        if ($($reliabilityStabilityMetrics.Average) -gt $reliabilityStabilityThreshold) {
            Write-Output -InputObject "[$elapsedTime] Reliability index is above the index threshold (Avr $reliabilityStabilityAverage Max $reliabilityStabilityMaximum Min $reliabilityStabilityMinimum)"
            exit 0
        }
        else {
            Write-Output -InputObject "[$elapsedTime] Reliability index is below the index threshold (Avr $reliabilityStabilityAverage Max $reliabilityStabilityMaximum Min $reliabilityStabilityMinimum)"
            exit 1
        }
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
