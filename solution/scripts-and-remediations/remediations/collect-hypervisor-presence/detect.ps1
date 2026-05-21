<#
.SYNOPSIS
    Detect virtualization support.

.DESCRIPTION
    Detect the availability of virtualization, and succeed if either the processor supports
    virtualization and has virtualization enabled, or if a hypervisor is present.

.EXAMPLE
    .\detect.ps1

    Detect virtualization support on the current device.

.NOTES
    version: 1.3.0
    date: November 25, 2023
    license: MIT License

.LINK
    https://github.com/dotjesper/windows-kaleidoscope
#>

#requires -Version 5.1

[CmdletBinding()]
param ()

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
    try {
        #region :: check virtualization support
        $processorInfo = Get-CimInstance -ClassName Win32_Processor -Verbose:$false
        [bool]$vmMonitorModeExtensions = $processorInfo.VMMonitorModeExtensions
        [bool]$virtualizationFirmwareEnabled = $processorInfo.VirtualizationFirmwareEnabled
        [bool]$hypervisorPresent = (Get-CimInstance -ClassName Win32_ComputerSystem -Verbose:$false).HypervisorPresent
        Write-Verbose -Message "VMMonitorModeExtensions: $vmMonitorModeExtensions | VirtualizationFirmwareEnabled: $virtualizationFirmwareEnabled | HypervisorPresent: $hypervisorPresent"
        # Success if either processor supports and enabled or if hypervisor is present
        [string]$elapsedTime = ('{0:00.000}' -f ((Get-Date).ToUniversalTime() - $scriptStartTime).TotalSeconds) -replace ',', '.'
        if (($vmMonitorModeExtensions -and $virtualizationFirmwareEnabled) -or $hypervisorPresent) {
            Write-Output -InputObject "[$elapsedTime] Virtualization firmware check passed [VMMonitorModeExtensions: $vmMonitorModeExtensions | VirtualizationFirmwareEnabled: $virtualizationFirmwareEnabled | HypervisorPresent: $hypervisorPresent]."
            exit 0
        }
        else {
            Write-Output -InputObject "[$elapsedTime] Virtualization firmware check failed [VMMonitorModeExtensions: $vmMonitorModeExtensions | VirtualizationFirmwareEnabled: $virtualizationFirmwareEnabled | HypervisorPresent: $hypervisorPresent]."
            exit 1
        }
        #endregion
    }
    catch {
        $errorMessage = $_.Exception.Message
        Write-Error -Message $errorMessage -Category 'SyntaxError' -ErrorId 'C001'
        exit 1
    }
    finally {}
}
end {}
