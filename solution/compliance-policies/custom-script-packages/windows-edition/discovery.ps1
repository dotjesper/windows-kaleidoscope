<#
.SYNOPSIS
    Custom compliance discovery script for Windows edition validation.

.DESCRIPTION
    Collects the Windows edition (operating system SKU) and OS architecture from the device
    and returns the values as compressed JSON for evaluation by Microsoft Intune custom
    compliance rules.

.EXAMPLE
    .\discovery.ps1

    Run the script with default parameters.

.EXAMPLE
    .\discovery.ps1 -Verbose

    Run the script with verbose output.

.NOTES
    version: 1.0.0
    date: June 12, 2024
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
        # Get Windows Edition and Architecture
        [int]$WindowsEdition = (Get-CimInstance -ClassName 'Win32_OperatingSystem').OperatingSystemSKU
        [string]$OSArchitecture = (Get-CimInstance -ClassName 'Win32_OperatingSystem').OSArchitecture
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
    $hash = @{ WindowsEdition = $WindowsEdition; OSArchitecture = $OSArchitecture }
    return $hash | ConvertTo-Json -Compress
}
