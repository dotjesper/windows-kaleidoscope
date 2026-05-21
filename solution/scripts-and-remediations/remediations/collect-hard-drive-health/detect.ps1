<#
.SYNOPSIS
    Collect hard drive health status and reliability metrics

.DESCRIPTION
    Actively collect hard drive health throughout Windows devices by checking physical disk health
    status, SMART failure prediction, wear level, read/write error counts, and temperature. Allows
    proactive hard drive replacement prior to having to remediate disk failures reactively.

.PARAMETER maxWearValue
    Define maximum acceptable wear value. Valid range 0-100

.PARAMETER maxReadWriteErrors
    Define maximum acceptable read/write error count

.PARAMETER maxTemperature
    Define maximum acceptable temperature in Celsius

.EXAMPLE
    .\detect.ps1

    Collect hard drive health status and reliability metrics using default thresholds.

.NOTES
    version: 1.1.0
    date: April 4, 2025
    license: MIT License

.LINK
    https://github.com/dotjesper/windows-kaleidoscope
#>

#requires -Version 5.1
#requires -RunAsAdministrator

[CmdletBinding()]
param (
    #variables
    [Parameter(Mandatory = $false, HelpMessage = 'Choose maximum acceptable wear value')]
    [ValidateRange(0, 100)]
    [int]$maxWearValue = 90,

    [Parameter(Mandatory = $false, HelpMessage = 'Choose maximum acceptable read/write error count')]
    [int]$maxReadWriteErrors = 100,

    [Parameter(Mandatory = $false, HelpMessage = 'Choose maximum acceptable temperature in Celsius')]
    [int]$maxTemperature = 60
)

begin {
    Set-StrictMode -Version Latest

    #variables :: conditions
    [bool]$runScriptIn64bitPowerShell = $true

    #variables :: environment
    [bool]$diskHealthIssueDetected = $false
    [string]$outputReport = ''
    [datetime]$scriptStartTime = (Get-Date).ToUniversalTime()
}
process {
    #region :: check conditions
    if ($runScriptIn64bitPowerShell -eq $true -and $([System.Environment]::Is64BitProcess) -eq $false) {
        Write-Error -Message 'Windows PowerShell 64-bit is required.' -Category 'ResourceUnavailable' -ErrorId 'B001'
        exit 1
    }
    #endregion

    #region :: main logic
    try {
        #region :: get physical disk information
        $physicalDisks = Get-PhysicalDisk
        if (-not $physicalDisks) {
            [string]$elapsedTime = ('{0:00.000}' -f ((Get-Date).ToUniversalTime() - $scriptStartTime).TotalSeconds) -replace ',', '.'
            Write-Output -InputObject "[$elapsedTime] No physical disks found or unable to obtain disk information."
            exit 0
        }
        [int]$diskCount = ($physicalDisks | Measure-Object).Count
        #endregion

        #region :: check SMART failure prediction
        [bool]$smartAvailable = $false
        [bool]$smartFailurePredicted = $false
        try {
            $smartStatus = Get-CimInstance -Namespace 'root\wmi' -ClassName 'MSStorageDriver_FailurePredictStatus' -ErrorAction SilentlyContinue
            if ($smartStatus) {
                [bool]$smartAvailable = $true
                foreach ($smart in $smartStatus) {
                    if ($smart.PredictFailure -eq $true) {
                        [bool]$smartFailurePredicted = $true
                        [bool]$diskHealthIssueDetected = $true
                    }
                }
            }
        }
        catch {
            Write-Warning -Message 'Unable to retrieve SMART failure prediction status.'
        }
        #endregion

        #region :: check physical disks and reliability counters
        foreach ($disk in $physicalDisks) {
            [string]$diskFriendlyName = $disk.FriendlyName
            [string]$diskMediaType = $disk.MediaType
            [string]$healthStatus = $disk.HealthStatus

            # Collect reliability metrics for this disk
            [string]$wearValue = 'n/a'
            [string]$readErrors = 'n/a'
            [string]$writeErrors = 'n/a'
            [string]$temperature = 'n/a'

            if ($healthStatus -ne 'Healthy') {
                [bool]$diskHealthIssueDetected = $true
            }

            try {
                $reliability = $disk | Get-StorageReliabilityCounter -ErrorAction SilentlyContinue
                if ($reliability) {
                    # Wear value
                    if ($null -ne $reliability.Wear) {
                        [string]$wearValue = "$($reliability.Wear)%"
                        if ($reliability.Wear -ge $maxWearValue) {
                            [bool]$diskHealthIssueDetected = $true
                            [string]$wearValue = "$($reliability.Wear)% [!]"
                        }
                    }
                    # Read errors
                    if ($null -ne $reliability.ReadErrorsTotal) {
                        [string]$readErrors = "$($reliability.ReadErrorsTotal)"
                        if ($reliability.ReadErrorsTotal -ge $maxReadWriteErrors) {
                            [bool]$diskHealthIssueDetected = $true
                            [string]$readErrors = "$($reliability.ReadErrorsTotal) [!]"
                        }
                    }
                    # Write errors
                    if ($null -ne $reliability.WriteErrorsTotal) {
                        [string]$writeErrors = "$($reliability.WriteErrorsTotal)"
                        if ($reliability.WriteErrorsTotal -ge $maxReadWriteErrors) {
                            [bool]$diskHealthIssueDetected = $true
                            [string]$writeErrors = "$($reliability.WriteErrorsTotal) [!]"
                        }
                    }
                    # Temperature
                    if ($null -ne $reliability.Temperature) {
                        [string]$temperature = "$($reliability.Temperature)C"
                        if ($reliability.Temperature -ge $maxTemperature) {
                            [bool]$diskHealthIssueDetected = $true
                            [string]$temperature = "$($reliability.Temperature)C [!]"
                        }
                    }
                }
            }
            catch {
                Write-Warning -Message "Unable to retrieve reliability counters for disk '$diskFriendlyName'."
            }

            # Build per-disk report line
            [string]$outputReport = "$outputReport | $diskFriendlyName ($diskMediaType): health=$healthStatus, wear=$wearValue, readErr=$readErrors, writeErr=$writeErrors, temp=$temperature"
        }
        #endregion

        #region :: build final output
        [string]$elapsedTime = ('{0:00.000}' -f ((Get-Date).ToUniversalTime() - $scriptStartTime).TotalSeconds) -replace ',', '.'
        [string]$smartReport = 'SMART=n/a'

        # SMART status takes precedence over other health indicators since it is a direct failure prediction. If SMART predicts failure, report that as the primary issue.
        if ($smartAvailable -eq $true) {
            [string]$smartReport = 'SMART=ok'
        }

        # If SMART failure is predicted, flag that as the primary issue in the report since it is a direct failure prediction. Other indicators are important but SMART is more definitive.
        if ($smartFailurePredicted -eq $true) {
            [string]$smartReport = 'SMART=failure predicted [!]'
        }

        # Final output report includes elapsed time, overall SMART status, and per-disk health and reliability metrics. Disks with issues are flagged with [!].
        if ($diskHealthIssueDetected -eq $true) {
            Write-Output -InputObject "[$elapsedTime] Hard drive health issue detected (Disks: $diskCount, $smartReport)$outputReport"
            exit 1
        }
        else {
            Write-Output -InputObject "[$elapsedTime] All hard drives healthy (Disks: $diskCount, $smartReport)$outputReport"
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
