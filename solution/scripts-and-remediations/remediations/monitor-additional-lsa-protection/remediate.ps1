<#
.SYNOPSIS
    Monitor Additional LSA Protection settings

.DESCRIPTION
    Monitor whether Additional LSA Protection is configured.
    The LSA, which includes the Local Security Authority Server Service (LSASS) process, validates users for local and remote sign-ins and enforces local security policies.
    https://learn.microsoft.com/windows-server/security/credentials-protection-and-management/configuring-additional-lsa-protection.

.EXAMPLE
    .\remediate.ps1

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
        # Read current values, defaulting to $null if not present
        $regRunAsPPL = Get-ItemProperty -Path "Registry::$regRoot\$regPath" -Name 'RunAsPPL' -ErrorAction SilentlyContinue
        [int]$currentRunAsPPL = if ($null -ne $regRunAsPPL) { $regRunAsPPL.RunAsPPL } else { -1 }

        $regDisableDomainCreds = Get-ItemProperty -Path "Registry::$regRoot\$regPath" -Name 'DisableDomainCreds' -ErrorAction SilentlyContinue
        [int]$currentDisableDomainCreds = if ($null -ne $regDisableDomainCreds) { $regDisableDomainCreds.DisableDomainCreds } else { -1 }

        if (($currentRunAsPPL -eq 1) -and ($currentDisableDomainCreds -eq 1)) {
            # Additional LSA Protection properly configured
            [string]$elapsedTime = ('{0:00.000}' -f ((Get-Date).ToUniversalTime() - $scriptStartTime).TotalSeconds) -replace ',', '.'
            Write-Output -InputObject "[$elapsedTime] Additional LSA Protection properly configured ($currentRunAsPPL$currentDisableDomainCreds)"
        }
        else {
            # Configure Additional LSA Protection settings
            [string]$elapsedTime = ('{0:00.000}' -f ((Get-Date).ToUniversalTime() - $scriptStartTime).TotalSeconds) -replace ',', '.'
            Write-Output -InputObject "[$elapsedTime] Configuring Additional LSA Protection settings ($currentRunAsPPL$currentDisableDomainCreds)"
            if ($currentRunAsPPL -ne 1) {
                $null = New-ItemProperty -Path "Registry::$regRoot\$regPath" -Name 'RunAsPPL' -Value 1 -PropertyType 'DWORD' -Force
            }
            if ($currentDisableDomainCreds -ne 1) {
                $null = New-ItemProperty -Path "Registry::$regRoot\$regPath" -Name 'DisableDomainCreds' -Value 1 -PropertyType 'DWORD' -Force
            }
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
