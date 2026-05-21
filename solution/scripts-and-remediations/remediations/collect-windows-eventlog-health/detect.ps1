<#
.SYNOPSIS
    Collect Windows Eventlog health

.DESCRIPTION
    In the realm of system administration, maintaining the integrity and accessibility of Windows Event Logs is
    paramount. These logs serve as a crucial tool for troubleshooting and diagnosing issues within the system.
    However, by default, Windows Event Logs are designed to be overwritten once the maximum event log size is reached.
    This can pose a significant challenge for administrators who require a consistent record of events for a minimum
    of days.

.PARAMETER logRetentionThreshold
    The number of days that the Windows Event Logs should be retained for. The default value is 7 days.

.PARAMETER queryLevel
    The level of logs to query. The default value is 1.
    1: Windows Logs
    2: All Logs

.EXAMPLE
    .\detect.ps1

    Run the script with default settings (7-day threshold, Windows Logs only).

.NOTES

    version: 1.0.0
    date: May 24, 2024
    license: MIT License

.LINK
    https://github.com/dotjesper/windows-kaleidoscope
#>

#requires -version 5.1
#requires -RunAsAdministrator

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false, HelpMessage = 'Choose Windows Eventlog retention threshold (days)')]
    [ValidateRange(1, 365)]
    [int]$logRetentionThreshold = 7,

    [Parameter(Mandatory = $false, HelpMessage = "Choose event logs to check 'Windows Logs [1]' or 'All Logs [2]'")]
    [ValidateSet(1, 2)]
    [int]$queryLevel = 1
)

begin {
    Set-StrictMode -Version Latest

    # variables :: Conditions
    [bool]$runScriptIn64bitPowerShell = $false

    # variables :: Environment
    [int]$healthyLogs = 0
    [int]$unhealthyLogs = 0
    [datetime]$scriptStartTime = (Get-Date).ToUniversalTime()

    #variables :: logfile
    [string]$logName = 'EventLogHealth.log'
    [string]$logFilePath = "$($Env:ProgramData)\Microsoft\IntuneManagementExtension\Logs\$logName"

    #region :: functions
    function Write-Log {
        <#
        .SYNOPSIS
            Write formatted log entries to a CMTrace/Intune-compatible log file.

        .DESCRIPTION
            Writes log entries with CMTrace and Microsoft Intune Management Extension compatible formatting.
            Supports different log levels (Info, Warning, Error) and component-based logging.

        .PARAMETER Message
            The log message to write.

        .PARAMETER Component
            The component or section of the script generating the log entry.

        .PARAMETER Severity
            The severity level of the log entry:
            1: Information (Default)
            2: Warning
            3: Error
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory = $true, ValueFromPipeline = $true, HelpMessage = 'Log message to write')]
            [string]$Message,

            [Parameter(Mandatory = $false, HelpMessage = 'Component generating the log message')]
            [string]$Component = '',

            [Parameter(Mandatory = $false, HelpMessage = 'Severity level of the log message')]
            [ValidateSet(1, 2, 3)]
            [int]$Severity = 1
        )
        process {
            try {
                [datetime]$timestamp = Get-Date

                # Compute UTC offset in minutes for CMTrace-compatible time field
                [timespan]$utcOffset = $timestamp - $timestamp.ToUniversalTime()
                [int]$utcOffsetMinutes = $utcOffset.TotalMinutes
                [string]$utcOffsetStr = if ($utcOffsetMinutes -ge 0) { "+$utcOffsetMinutes" } else { "$utcOffsetMinutes" }

                # Build CMTrace-compatible log entry
                [string]$logEntry = "<![LOG[$($Message)]LOG]!>" +
                "<time=""$($timestamp.ToString('HH:mm:ss.fffffff'))$utcOffsetStr"" " +
                "date=""$($timestamp.ToString('MM-dd-yyyy'))"" " +
                "component=""$Component"" context="""" " +
                "type=""$Severity"" thread=""$PID"" file="""">"

                # Ensure log directory exists
                if (-not (Test-Path -Path "$(Split-Path -Path $logFilePath)")) {
                    New-Item -ItemType 'Directory' -Path "$(Split-Path -Path $logFilePath)" | Out-Null
                }

                # Write to log file
                Add-Content -Path $logFilePath -Value $logEntry -Encoding 'UTF8' -ErrorAction 'Stop'
            }
            catch {
                Write-Warning "Failed to write to log file: $($_.Exception.Message)"
            }
        }
    }
    #endregion
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
        Write-Log -Message 'Windows Event log health check started' -Component 'EventLogHealth'

        # Query event logs based on the specified query level
        switch ($queryLevel) {
            1 {
                [array]$winEventLogs = Get-WinEvent -ListLog 'Application', 'Security', 'Setup', 'System', 'ForwardedEvents' -ErrorAction SilentlyContinue |
                    Where-Object { $_.RecordCount -gt 0 } |
                    Select-Object -ExpandProperty 'LogName'
                Write-Log -Message "Event logs ($queryLevel): $($winEventLogs.Count) queried" -Component 'EventLogHealth'
            }
            2 {
                [array]$winEventLogs = Get-WinEvent -ListLog * -ErrorAction SilentlyContinue |
                    Where-Object { $_.RecordCount -gt 0 } |
                    Select-Object -ExpandProperty 'LogName'
                Write-Log -Message "Event logs ($queryLevel): $($winEventLogs.Count) queried" -Component 'EventLogHealth'
            }
            Default {
                Write-Error -Message 'Invalid query level' -Category 'InvalidArgument' -ErrorId 'A001'
                Write-Log -Message 'Invalid query level' -Component 'EventLogHealth'
                exit 1
            }
        }

        # Iterate through each event log and evaluate health based on retention threshold and log size
        foreach ($winEventLog in $winEventLogs) {
            try {
                Write-Verbose -Message "$winEventLog log"
                $logInfo = Get-WinEvent -LogName $winEventLog -MaxEvents 1 -Oldest
                [int]$logRetentionDays = ((Get-Date) - ($logInfo.TimeCreated)).Days
                $logDetails = Get-WinEvent -ListLog $winEventLog
                $logFileSizeMB = $logDetails.FileSize / 1048576
                $logMaximumSizeMB = $logDetails.MaximumSizeInBytes / 1048576
                $percentUsed = ($logFileSizeMB / $logMaximumSizeMB) * 100
                if ($logRetentionDays -gt $logRetentionThreshold) {
                    Write-Verbose -Message "> log is healthy [$logRetentionDays days]"
                    Write-Log -Message "$winEventLog log is healthy ($logRetentionDays days)" -Component 'EventLogHealth'
                    Write-Verbose -Message "> starting event timestamp: $($logInfo.TimeCreated)"
                    Write-Log -Message "$winEventLog log starting event timestamp: $($logInfo.TimeCreated)" -Component 'EventLogHealth'
                    Write-Verbose -Message "> log size: $('{0:N2}' -f $logFileSizeMB) MB [$('{0:N2}' -f $percentUsed)% used]"
                    Write-Log -Message "$winEventLog log size: $('{0:N2}' -f $logFileSizeMB) MB ($('{0:N2}' -f $percentUsed)% used)" -Component 'EventLogHealth'
                    $healthyLogs = $healthyLogs + 1
                }
                else {
                    Write-Verbose -Message "> log is below the threshold [$logRetentionDays days]"
                    Write-Log -Message "$winEventLog log is below the threshold ($logRetentionDays days)" -Component 'EventLogHealth'
                    Write-Verbose -Message "> first event time stamp: $($logInfo.TimeCreated)"
                    Write-Log -Message "$winEventLog log first event time stamp: $($logInfo.TimeCreated)" -Component 'EventLogHealth'
                    Write-Verbose -Message "> log size: $('{0:N2}' -f $logFileSizeMB) MB [$('{0:N2}' -f $percentUsed)% used]"
                    Write-Log -Message "$winEventLog log size: $('{0:N2}' -f $logFileSizeMB) MB ($('{0:N2}' -f $percentUsed)% used)" -Component 'EventLogHealth'
                    $unhealthyLogs = $unhealthyLogs + 1
                }
            }
            catch {
                Write-Warning -Message "Failed to query $winEventLog log: $($_.Exception.Message)"
                Write-Log -Message "Failed to query $winEventLog log: $($_.Exception.Message)" -Component 'EventLogHealth'
                $unhealthyLogs = $unhealthyLogs + 1
            }
        }

        # Output summary of healthy vs unhealthy logs and exit with appropriate code
        Write-Log -Message "Healthy logs: $healthyLogs" -Component 'EventLogHealth'
        Write-Log -Message "Unhealthy logs: $unhealthyLogs" -Component 'EventLogHealth'
        [string]$elapsedTime = ('{0:00.000}' -f ((Get-Date).ToUniversalTime() - $scriptStartTime).TotalSeconds) -replace ',', '.'
        if ($unhealthyLogs -eq 0) {
            Write-Output -InputObject "[$elapsedTime] All logs are healthy"
            exit 0
        }
        else {
            Write-Output -InputObject "[$elapsedTime] Healthy logs: $healthyLogs | Unhealthy logs: $unhealthyLogs"
            exit 1
        }
    }
    catch {
        [string]$errorMessage = $_.Exception.Message
        Write-Error -Message $errorMessage -Category 'SyntaxError' -ErrorId 'C001'
        exit 1
    }
    finally {}
    #endregion
}
end {}
