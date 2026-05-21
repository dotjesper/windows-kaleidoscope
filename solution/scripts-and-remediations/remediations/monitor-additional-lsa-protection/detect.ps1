<#
.SYNOPSIS
    Monitor Additional LSA Protection settings

.DESCRIPTION
    Monitor whether Additional LSA Protection is configured.
    The LSA, which includes the Local Security Authority Server Service (LSASS) process, validates users for local and remote sign-ins and enforces local security policies.
    https://learn.microsoft.com/windows-server/security/credentials-protection-and-management/configuring-additional-lsa-protection.

.EXAMPLE
    .\detect.ps1

    Run the script with default parameters.

.NOTES
    version: 1.3.0
    date: May 4, 2021
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
    [string]$regRoot = "HKLM"
    [string]$regPath = "SYSTEM\CurrentControlSet\Control\Lsa"
    [datetime]$scriptStartTime = (Get-Date).ToUniversalTime()
}
process {
    #region :: Check conditions
    if ($runScriptIn64bitPowerShell -eq $true -and $([System.Environment]::Is64BitProcess) -eq $false) {
        Write-Error -Message "Windows PowerShell 64-bit is required." -Category "ResourceUnavailable" -ErrorId "B001"
        exit 1
    }
    #endregion

    #region :: Main logic
    try {
        # Check if registry path exists and get values
        if (Test-Path -Path $($regRoot + ":\" + $regPath)) {
            [array]$regValues = Get-ItemProperty -Path "Registry::$regRoot\$regPath"
            [string]$elapsedTime = ('{0:00.000}' -f ((Get-Date).ToUniversalTime() - $scriptStartTime).TotalSeconds) -replace ',', '.'
            if (($regValues.RunAsPPL -eq 1) -and ($regValues.DisableDomainCreds -eq 1)) {
                # Additional LSA Protection properly configured
                Write-Output -InputObject "[$elapsedTime] Additional LSA Protection properly configured ($($regValues.RunAsPPL)$($regValues.DisableDomainCreds))"
                exit 0
            }
            else {
                # Additional LSA Protection  misconfigured
                Write-Output -InputObject "[$elapsedTime] Additional LSA Protection misconfigured ($($regValues.RunAsPPL)$($regValues.DisableDomainCreds))"
                exit 1
            }
        }
        else {
            # Additional LSA Protection not available
            [string]$elapsedTime = ('{0:00.000}' -f ((Get-Date).ToUniversalTime() - $scriptStartTime).TotalSeconds) -replace ',', '.'
            Write-Output -InputObject "[$elapsedTime] Additional LSA Protection not available ($((Get-CimInstance -ClassName Win32_OperatingSystem).OSArchitecture))"
            exit 0
        }
    }
    catch {
        $errMsg = $_.Exception.Message
        Write-Error -Message $errMsg -Category "SyntaxError" -ErrorId "C001"
        exit 1
    }
    finally {}
    #endregion
}
end {}
