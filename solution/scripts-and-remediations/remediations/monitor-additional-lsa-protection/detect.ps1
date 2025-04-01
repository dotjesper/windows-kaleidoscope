#requires -Version 5.1
<#
.SYNOPSIS
    Monitor Additional LSA Protection settings
.DESCRIPTION
    Monitor whatever Additional LSA Protection is configured.
    The LSA, which includes the Local Security Authority Server Service (LSASS) process, validates users for local and remote sign-ins and enforces local security policies.
    https://docs.microsoft.com/en-us/windows-server/security/credentials-protection-and-management/configuring-additional-lsa-protection.
.EXAMPLE
    .\detect.ps1
.NOTES
    version: 1.3.0.2
    date: May 4, 2021
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
    [string]$regRoot = "HKLM"
    [string]$regPath = "SYSTEM\CurrentControlSet\Control\Lsa"
}
process {
    #region check conditions
    if ($runScriptIn64bitPowerShell -eq $true -and $([System.Environment]::Is64BitProcess) -eq $false) {
        Write-Error -Message "Windows PowerShell 64-bit is requered." -Category "ResourceUnavailable" -ErrorId "B001"
        exit 1
    }
    try {
        if (Test-Path -Path $($regRoot + ":\" + $regPath)) {
            [array]$regValues = Get-ItemProperty -Path "Registry::$regRoot\$regPath"
            if (($regValues.RunAsPPL -eq 1) -and ($regValues.DisableDomainCreds -eq 1)) {
                Write-Output -InputObject "Additional LSA Protection proberly configured ($($regValues.RunAsPPL)$($regValues.DisableDomainCreds))"
                exit 0
            }
            else {
                Write-Output -InputObject "Additional LSA Protection misconfigured ($($regValues.RunAsPPL)$($regValues.DisableDomainCreds))"
                exit 1
            }
        }
        else {
            Write-Output -InputObject "Additional LSA Protection not avaliable ($((Get-CimInstance -ClassName WIn32_OperatingSystem).OSArchitecture))"
            exit 0
        }
    }
    catch {
        $errMsg = $_.Exception.Message
       Write-Error -Message $errMsg -Category "SyntaxError" -ErrorId "C001"
        exit 1
    }
    finally {}
}
end {}
