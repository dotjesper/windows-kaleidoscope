#requires -Version 5.1
<#
.SYNOPSIS
    Custom compliance policy script for Windows Edition.
.DESCRIPTION
    This script will return the Windows Edition (SKU) and Windows Architecture.
.EXAMPLE
    .\discovery.ps1
.EXAMPLE
    .\discovery.ps1 -verbose
.NOTES
    version: 1.0
    author: Jesper Nielsen
    date: June 12, 2024
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
        [int]$WindowsEdition = (Get-CimInstance Win32_OperatingSystem).OperatingSystemSKU
        [string]$OSArchitecture = (Get-CimInstance Win32_OperatingSystem).OSArchitecture
    }
    catch {
        $errMsg = $_.Exception.Message
        Write-Error -Message $errMsg
        exit 1
    }
    finally {}
}
end {
    $hash = @{ WindowsEdition = $WindowsEdition; OSArchitecture = $OSArchitecture }
    return $hash | ConvertTo-Json -Compress
}
