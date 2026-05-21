<#
.SYNOPSIS
    Custom compliance discovery script for Windows hypervisor validation.

.DESCRIPTION
    Checks whether hardware virtualization is available on the device by evaluating
    processor VM monitor mode extensions, firmware-level virtualization, and hypervisor
    presence. Returns a computed boolean result as compressed JSON for evaluation by
    Microsoft Intune custom compliance rules.

.EXAMPLE
    .\discovery.ps1

    Run the script with default parameters.

.EXAMPLE
    .\discovery.ps1 -Verbose

    Run the script with verbose output.

.NOTES
    version: 1.0.0
    date: June 14, 2024
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
    [bool]$runScriptIn64bitPowerShell = $true

    # variables :: Environment
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
        # Check processor and system information for virtualization capabilities
        [bool]$VMMonitorModeExtensions = (Get-CimInstance -ClassName 'Win32_Processor').VMMonitorModeExtensions
        [bool]$VirtualizationFirmwareEnabled = (Get-CimInstance -ClassName 'Win32_Processor').VirtualizationFirmwareEnabled
        [bool]$HypervisorPresent = (Get-CimInstance -ClassName 'Win32_ComputerSystem').HypervisorPresent

        # Determine if virtualization is present based on the collected information
        if (($VMMonitorModeExtensions -and $VirtualizationFirmwareEnabled) -or $HypervisorPresent) {
            Write-Verbose -Message 'Virtualization is present.'
            [bool]$Virtualization = $true
        }
        else {
            Write-Verbose -Message 'Virtualization is not present.'
            [bool]$Virtualization = $false
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
    $hash = @{ Virtualization = $Virtualization }
    return $hash | ConvertTo-Json -Compress
}
