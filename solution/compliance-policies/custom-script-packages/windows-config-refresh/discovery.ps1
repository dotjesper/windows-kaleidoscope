<#
.SYNOPSIS
    Custom compliance discovery script for Windows Config Refresh status.

.DESCRIPTION
    Collects the Config Refresh feature status from the device registry and validates
    the associated scheduled task. Returns the enabled state, paused state, and task
    readiness as compressed JSON for evaluation by Microsoft Intune custom compliance rules.

.EXAMPLE
    .\discovery.ps1

    Run the script with default parameters.

.EXAMPLE
    .\discovery.ps1 -Verbose

    Run the script with verbose output.

.NOTES
    version: 1.0.0
    date: March 21, 2025
    license: MIT License

.LINK
    https://github.com/dotjesper/windows-kaleidoscope
#>

#requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding()]
param ()
begin {
    Set-StrictMode -Version Latest

    # variables :: Conditions
    [bool]$runScriptIn64bitPowerShell = $true

    # variables :: Environment
    [bool]$configRefreshEnabled = $false
    [bool]$configRefreshPaused = $false
    [bool]$scheduledTaskReady = $false
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
        # Check registry for Config Refresh status
        $enrollmentPath = 'HKLM:\SOFTWARE\Microsoft\Enrollments'
        if (Test-Path $enrollmentPath) {
            # Get all enrollment subkeys and check for Config Refresh settings
            [array]$enrollmentItems = Get-ChildItem -Path $enrollmentPath -ErrorAction SilentlyContinue

            # If multiple enrollments exist, Config Refresh is expected to be enabled if at least one enrollment has it enabled and not paused
            foreach ($enrollmentItem in $enrollmentItems) {
                $configRefreshPath = Join-Path $enrollmentItem.PSPath 'ConfigRefresh'
                if (Test-Path $configRefreshPath) {
                    # Check if Config Refresh is enabled
                    $enabledResult = Get-ItemProperty -Path $configRefreshPath -Name 'Enabled' -ErrorAction SilentlyContinue
                    if ($null -ne $enabledResult -and $enabledResult.Enabled -eq 1) { $configRefreshEnabled = $true }

                    # Check if Config Refresh is paused
                    $pauseResult = Get-ItemProperty -Path $configRefreshPath -Name 'PausePeriod' -ErrorAction SilentlyContinue
                    if ($null -ne $pauseResult -and $pauseResult.PausePeriod -gt 0) { $configRefreshPaused = $true }
                }
            }
        }

        # Check scheduled task status (skip if Config Refresh is paused)
        if (-not $configRefreshPaused) {
            $task = Get-ScheduledTask -TaskPath '\Microsoft\Windows\EnterpriseMgmtNonCritical\*' -TaskName '*refresh settings*' -ErrorAction SilentlyContinue
            if ($task -and $task.State -eq 'Ready') { $scheduledTaskReady = $true }
        }
        else {
            # When paused, scheduled task state is expected to be different
            $scheduledTaskReady = $true
        }
    }
    catch {
        $errMsg = $_.Exception.Message
        Write-Error -Message $errMsg
        exit 1
    }
    finally {}
    #endregion
}
end {
    # return results
    $hash = @{ ConfigRefreshEnabled = $configRefreshEnabled; ConfigRefreshPaused = $configRefreshPaused; ScheduledTaskReady = $scheduledTaskReady }
    return $hash | ConvertTo-Json -Compress
}
