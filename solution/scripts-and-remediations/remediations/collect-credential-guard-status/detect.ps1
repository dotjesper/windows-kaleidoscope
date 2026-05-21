<#
.SYNOPSIS
    Detect Credential Guard status.

.DESCRIPTION
    Detect the Credential Guard configuration and runtime status by querying the
    Win32_DeviceGuard WMI class. Reports whether Virtualization Based Security is
    enabled, whether Credential Guard is configured, and whether Credential Guard
    is actively running.

.EXAMPLE
    .\detect.ps1

    Detect Credential Guard status on the current device.

.NOTES
    version: 1.0.0
    date: April 13, 2026
    license: MIT License

.LINK
    https://github.com/dotjesper/windows-kaleidoscope
#>

#requires -Version 5.1
#requires -RunAsAdministrator

[CmdletBinding()]
param ()

begin {
    Set-StrictMode -Version Latest

    #variables :: conditions
    [bool]$runScriptIn64bitPowerShell = $true

    #variables :: environment
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
        $deviceGuard = Get-CimInstance -ClassName Win32_DeviceGuard -Namespace 'root\Microsoft\Windows\DeviceGuard' -Verbose:$false

        #region :: evaluate Virtualization Based Security status
        # VirtualizationBasedSecurityStatus: 0 = not enabled, 1 = enabled but not running, 2 = enabled and running
        [int]$vbsStatus = $deviceGuard.VirtualizationBasedSecurityStatus

        switch ($vbsStatus) {
            0 { [string]$vbsStatusText = 'not enabled' }
            1 { [string]$vbsStatusText = 'enabled but not running' }
            2 { [string]$vbsStatusText = 'enabled and running' }
            default { [string]$vbsStatusText = 'unknown' }
        }
        #endregion

        #region :: evaluate Credential Guard status
        # SecurityServicesConfigured contains 1 = Credential Guard configured
        # SecurityServicesRunning contains 1 = Credential Guard running
        [bool]$credentialGuardConfigured = $deviceGuard.SecurityServicesConfigured -contains 1
        [bool]$credentialGuardRunning = $deviceGuard.SecurityServicesRunning -contains 1
        #endregion

        [string]$elapsedTime = ('{0:00.000}' -f ((Get-Date).ToUniversalTime() - $scriptStartTime).TotalSeconds) -replace ',', '.'
        if ($credentialGuardRunning) {
            Write-Output -InputObject "[$elapsedTime] Credential Guard running [VBS: $vbsStatusText | Configured: $credentialGuardConfigured | Running: $credentialGuardRunning]."
            exit 0
        }
        else {
            Write-Output -InputObject "[$elapsedTime] Credential Guard not running [VBS: $vbsStatusText | Configured: $credentialGuardConfigured | Running: $credentialGuardRunning]."
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
