#requires -Version 5.1
<#
.SYNOPSIS
    Monitor Interactive Logon Message
.DESCRIPTION
    Monitor Interactive Logon Message is often used i secure environments, but can also be used as a Prototype Information for e.g., pilot users or alike.
    The configuration is configured using Local Policies: Security Options, using
    - Interactive Logon Message Title For Users Attempting To Log On
    - Interactive Logon Message Text For Users Attempting To Log On
    Removing the policy might fail to remove the tatooed settings, and this solution will attempt to clear the two configurations.
        [HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System]
        LegalNoticeCaption=""
        LegalNoticeText=""
.EXAMPLE
    .\remediate.ps1
.NOTES
    version: 1.0.0.0
    date: October 9, 2021
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
        [string]$regRoot = "HKLM"
        [string]$regPath = "SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
        if (Test-Path -Path $($regRoot + ":\" + $regPath)) {
            [array]$regValues = Get-ItemProperty -Path "Registry::$regRoot\$regPath"
            if (($regValues.LegalNoticeCaption.Length -gt 0) -or ($regValues.LegalNoticeText.Length -gt 0)) {
                Write-Verbose -Message "Interactive Logon Message configurations found."
                Write-Verbose -Message "Interactive Logon Message Title For Users Attempting To Log On: $($regValues.LegalNoticeCaption)."
                Write-Verbose -Message "Interactive Logon Message Text For Users Attempting To Log On: $($regValues.LegalNoticeText)."
                if ($regValues.LegalNoticeCaption.Length -gt 0) {
                    Write-Verbose -Message "Clering LegalNoticeCaption value."
                    Clear-ItemProperty -Path $($regRoot + ":\" + $regPath) -Name "LegalNoticeCaption"
                }
                if ($regValues.LegalNoticeText.Length -gt 0) {
                    Write-Verbose -Message "Clering LegalNoticeText value."
                    Clear-ItemProperty -Path $($regRoot + ":\" + $regPath) -Name "LegalNoticeText"
                }
                [array]$regValues = Get-ItemProperty -Path "Registry::$regRoot\$regPath"
                if (($regValues.LegalNoticeCaption.Length -gt 0) -or ($regValues.LegalNoticeText.Length -gt 0)) {
                    Write-Output -InputObject "Interactive Logon Message configurations clear failed."
                    exit 1

                }
                else {
                    Write-Output -InputObject "Interactive Logon Message configurations cleared."
                    exit 0
                }
            }
            else {
                Write-Output -InputObject "Interactive Logon Message values empty."
                exit 0
            }
        }
        else {
            Write-Output -InputObject "Interactive Logon Message values not found."
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