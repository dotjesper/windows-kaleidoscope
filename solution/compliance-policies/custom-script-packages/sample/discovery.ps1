<#
.SYNOPSIS
    Sample custom compliance discovery script for exploring custom compliance policies.

.DESCRIPTION
    Sample discovery script that collects device manufacturer, BIOS version, and TPM chip
    presence. Returns the values as compressed JSON for evaluation by Microsoft Intune
    custom compliance rules.

.EXAMPLE
    .\discovery.ps1

    Run the script with default parameters.

.EXAMPLE
    .\discovery.ps1 -Verbose

    Run the script with verbose output.

.NOTES
    version: 1.1.0
    date: April 10, 2026
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
        # Collect device information for compliance evaluation
        [string]$Manufacturer = (Get-CimInstance -ClassName 'Win32_ComputerSystem').Manufacturer
        [string]$BiosVersion = (Get-CimInstance -ClassName 'Win32_BIOS').SMBIOSBIOSVersion
        [bool]$TPMChipPresent = (Get-Tpm).TpmPresent
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
    # Prepare the collected information as a hashtable and convert to compressed JSON for Intune evaluation
    $hash = @{ Manufacturer = $Manufacturer; BiosVersion = $BiosVersion; TPMChipPresent = $TPMChipPresent }
    return $hash | ConvertTo-Json -Compress
}
