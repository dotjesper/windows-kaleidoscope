#requires -Version 5.1
<#
.SYNOPSIS
    Custom compliance policy script for Windows Hypervisor.
.DESCRIPTION
    This script will return if hypervisor is present.
.EXAMPLE
    .\discovery.ps1
.EXAMPLE
    .\discovery.ps1 -verbose
.NOTES
    version: 1.0
    author: Jesper Nielsen
    date: June 14, 2024
#>
[CmdletBinding()]
param ()
begin {
    #variables :: conditions
    [bool]$runScriptIn64bitPowerShell = $true
    #variables :: environment
}
process {
    #region check conditions
    if ($runScriptIn64bitPowerShell -eq $true -and $([System.Environment]::Is64BitProcess) -eq $false) {
        Write-Error -Message "Windows PowerShell 64-bit is requered." -Category "ResourceUnavailable" -ErrorId "B001"
        exit 1
    }
    #endregion
    try {
        #region Check Virtualization is present
        [bool]$VMMonitorModeExtensions = $(Get-CimInstance -ClassName Win32_processor).VMMonitorModeExtensions
        [bool]$VirtualizationFirmwareEnabled = $(Get-CimInstance -ClassName Win32_processor).VirtualizationFirmwareEnabled
        [bool]$HypervisorPresent = (Get-CimInstance -Class Win32_ComputerSystem).HypervisorPresent
        #success if either processor supports and enabled or if hyper-v is present
        if (($VMMonitorModeExtensions -and $VirtualizationFirmwareEnabled) -or $HypervisorPresent) {
            Write-Verbose -Message "Virtualization is present."
            [bool]$Virtualization = $true
        }
        else {
            Write-Verbose -Message "Virtualization is not present."
            [bool]$Virtualization = $false
        }
        #endregion
    }
    catch {
        $errMsg = $_.Exception.Message
        Write-Error -Message $errMsg
        exit 1
    }
    finally {}
}
end {
    $hash = @{ Virtualization = $Virtualization }
    return $hash | ConvertTo-Json -Compress
}
