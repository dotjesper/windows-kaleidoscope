#requires -Version 5.1
<#
.SYNOPSIS
    Collect the availability of virtualization
.DESCRIPTION
    Collect the availability of virtualization, and succeed if either the processor supports virtualization and has virtualization enabled, or if Hyper-V is present.
.EXAMPLE
    .\detect.ps1
.NOTES
    version: 1.2.0.2
    date: November 25, 2023
    license: MIT License
.LINK
    [Jesper on Bluesky](https://bsky.app/profile/dotjesper.bsky.social "Jesper on Bluesky")
    [Jesper on GitHub](https://github.com/dotjesper/ "Jesper on GitHub")
#>
[CmdletBinding()]
param (
    #variables
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
    #endregion
    try {
        #region Check Virtualization is present
        [bool]$VMMonitorModeExtensions = $(Get-CimInstance -ClassName Win32_processor).VMMonitorModeExtensions
        [bool]$VirtualizationFirmwareEnabled = $(Get-CimInstance -ClassName Win32_processor).VirtualizationFirmwareEnabled
        [bool]$HypervisorPresent = (Get-CimInstance -Class Win32_ComputerSystem).HypervisorPresent
        #success if either processor supports and enabled or if hyper-v is present
        if (($VMMonitorModeExtensions -and $VirtualizationFirmwareEnabled) -or $HypervisorPresent) {
            Write-Output -InputObject "Virtualization firmware check passed."
            exit 0
        }
        else {
            Write-Output -InputObject "Virtualization firmware check failed."
            exit 1
        }
        #endregion
    }
    catch {
        $errMsg = $_.Exception.Message
        Write-Error -Message $errMsg -Category "SyntaxError" -ErrorId "C001"
        exit 1
    }
    finally {}
}
end {}
