#requires -Version 5.1
<#
.SYNOPSIS
    Collect Windows Eventlog health
.DESCRIPTION
    In the realm of system administration, maintaining the integrity and accessibility of Windows Event Logs is
    paramount. These logs serve as a crucial tool for troubleshooting and diagnosing issues within the system.
    However, by default, Windows Event Logs are designed to be overwritten once the maximum event log size is reached.
    This can pose a significant challenge for administrators who require a consistent record of events for a minimum
    of days.
.PARAMETER windowsEventlogHealthThreshold
    The number of days that the Windows Event Logs should be retained for. The default value is 7 days.
.PARAMETER queryLevel
    The level of logs to query. The default value is 1.
    1: Windows Logs
    2: All Logs
.EXAMPLE
    .\detect.ps1
.NOTES
    version: 1.0.0.0
    date: May 24, 2024
    license: MIT License
.LINK
    [Jesper on Bluesky](https://bsky.app/profile/dotjesper.bsky.social "Jesper on Bluesky")
    [Jesper on GitHub](https://github.com/dotjesper/ "Jesper on GitHub")
#>
[CmdletBinding()]
param (
    #variables
    [Parameter (Mandatory = $False, HelpMessage = "Choose Windows Eventlog retention threshold (days)") ]
    [int]$logRetentionThreshold = 7,
    [Parameter (Mandatory = $False, HelpMessage = "Choose event logs to check 'Windows Logs [1]' or 'All Logs [2]'")]
    [ValidateSet(1,2)]
    [int]$queryLevel = 1
)
begin {
    #variables :: conditions
    [bool]$runScriptIn64bitPowerShell = $false
    #variables :: environment
    [int]$healthyLogs = 0
    [int]$unhealthyLogs = 0
    [string]$fLogContentFile = "$($Env:ProgramData)\Microsoft\IntuneManagementExtension\Logs\eventloghealth.log"
    #region :: functions
    function fLogContent () {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory = $true)]
            [string]$fLogContent,
            [Parameter(Mandatory = $false)]
            [string]$fLogContentComponent
        )
        begin {
            $fdate = $(Get-Date -Format "M-dd-yyyy")
            $ftime = $(Get-Date -Format "HH:mm:ss.fffffff")
        }
        process {
            if (!(Test-Path -Path "$(Split-Path -Path $fLogContentFile)")) {
                New-Item -itemType "Directory" -Path "$(Split-Path -Path $fLogContentFile)" | Out-Null
            }
            Add-Content -Path $fLogContentFile -Value "<![LOG[[$fLogContentpkg] $($fLogContent)]LOG]!><time=""$($ftime)"" date=""$($fdate)"" component=""$fLogContentComponent"" context="""" type="""" thread="""" file="""">" | Out-Null
        }
        end {}
    }
    #endregion
}
process {
    #region check conditions
    if ($runScriptIn64bitPowerShell -eq $true -and $([System.Environment]::Is64BitProcess) -eq $false) {
        Write-Error -Message "Windows PowerShell 64-bit is requered." -Category "ResourceUnavailable" -ErrorId "B001"
        exit 1
    }
    #endregion
    try {
        fLogContent -fLogContent "Windows Event log health check started" -fLogContentComponent "EventLogHealth"
        switch ($queryLevel) {
            1 {
                $WinEventLogs = Get-EventLog -List | Where-Object { $_.Entries.Count -gt 0 } | Select-Object -ExpandProperty "Log"
                fLogContent -fLogContent "Event logs ($queryLevel): $($WinEventLogs.Count) queried" -fLogContentComponent "EventLogHealth"
            }
            2 {
                $WinEventLogs = Get-WinEvent -ListLog * | Where-Object { $_.RecordCount -gt 0 } | Select-Object -ExpandProperty "LogName"
                fLogContent -fLogContent "Event logs ($queryLevel): $($WinEventLogs.Count) queried" -fLogContentComponent "EventLogHealth"
            }
            Default {
                Write-Error -Message "Invalid query level" -Category "InvalidArgument" -ErrorId "A001"
                fLogContent -fLogContent "Invalid query level" -fLogContentComponent "EventLogHealth"
                exit 1
            }
        }
        foreach ($WinEventLog in $WinEventLogs) {
            Write-Verbose -Message "$WinEventLog log"
            $logInfo = Get-WinEvent -LogName $WinEventLog -MaxEvents 1 -Oldest
            $logRetentionDays = ((Get-Date) - ($logInfo.TimeCreated)).Days
            $logFileSize = [math]::Round((Get-WinEvent -ListLog $WinEventLog).FileSize / 1048576, 2)
            $logMaximumSize = [math]::Round((Get-WinEvent -ListLog $WinEventLog).MaximumSizeInBytes / 1048576, 2)
            if ($logRetentionDays -gt $logRetentionThreshold) {
                Write-Verbose -Message "> log is healthy [$logRetentionDays days]"
                fLogContent -fLogContent "$WinEventLog log is healthy ($logRetentionDays days)" -fLogContentComponent "EventLogHealth"
                Write-Verbose -Message "> starting event timestamp: $($logInfo.TimeCreated)"
                fLogContent -fLogContent "$WinEventLog log starting event timestamp: $($logInfo.TimeCreated)" -fLogContentComponent "EventLogHealth"
                Write-Verbose -Message "> log size: $logFileSize MB [$([math]::Round(($logFileSize / $logMaximumSize) * 100, 2))% used]"
                fLogContent -fLogContent "$WinEventLog log size: $logFileSize MB ($([math]::Round(($logFileSize / $logMaximumSize) * 100, 2))% used)" -fLogContentComponent "EventLogHealth"
                $healthyLogs = $healthyLogs + 1
            } else {
                Write-Verbose -Message "> log is below the threshold [$logRetentionDays days]"
                fLogContent -fLogContent "$WinEventLog log is below the threshold ($logRetentionDays days)" -fLogContentComponent "EventLogHealth"
                Write-Verbose -Message "> first event time stamp: $($logInfo.TimeCreated)"
                fLogContent -fLogContent "$WinEventLog log first event time stamp: $($logInfo.TimeCreated)" -fLogContentComponent "EventLogHealth"
                Write-Verbose -Message "> log size: $logFileSize MB [$([math]::Round(($logFileSize / $logMaximumSize) * 100, 2))% used]"
                fLogContent -fLogContent "$WinEventLog log size: $logFileSize MB ($([math]::Round(($logFileSize / $logMaximumSize) * 100, 2))% used)" -fLogContentComponent "EventLogHealth"
                $unhealthyLogs = $unhealthyLogs +1
            }
        }
        fLogContent -fLogContent "Healthy logs: $healthyLogs" -fLogContentComponent "EventLogHealth"
        fLogContent -fLogContent "Unhealthy logs: $unhealthyLogs" -fLogContentComponent "EventLogHealth"
        if ($unhealthyLogs -eq 0) {
            Write-Output -InputObject "All logs are healthy"
            exit 0
        }
        else {
            Write-Output -InputObject "Healthy logs: $healthyLogs | Unhealthy logs: $unhealthyLogs"
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
