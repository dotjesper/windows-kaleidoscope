#requires -Version 5.1
<#
.SYNOPSIS
    Monitor orphaned Windows Update (WSUS) settings.
.DESCRIPTION
    Monitor orphaned Windows Update (WSUS) settings.
    Solution based on information from Windows Autopatch conflicting configurations
    https://learn.microsoft.com/windows/deployment/windows-autopatch/references/windows-autopatch-conflicting-configurations
.EXAMPLE
    .\remediate.ps1
.NOTES
    version: 1.2.5.8
    date: October 19, 2023
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
        [string]$regPath = "Software\Policies\Microsoft\Windows\WindowsUpdate"
        if (Test-Path -Path $($regRoot + ":\" + $regPath)) {
            [array]$regValues = Get-ItemProperty -Path "Registry::$regRoot\$regPath"
            if ($regValues.Length -gt 0) {
                $wuauservStatus = $((Get-Service -Name "wuauserv").Status)
                if ($wuauservStatus -eq "Running") {
                    Stop-Service -Name "wuauserv" -Force
                }
                $wuauservStartType = $((Get-Service -Name "wuauserv").StartType)
                if ($wuauservStartType -eq "Disabled") {
                    Set-Service -Name "wuauserv" -StartupType "Manual"
                }
                Remove-Item -Path "Registry::$regRoot\$regPath" -Recurse -Force
                Start-Service -Name "wuauserv"
                if (Test-Path -Path $($regRoot + ":\" + $regPath)) {
                    Write-Output -InputObject "Windows Update (WSUS) policy settings reset failed."
                    exit 1
                }
                else {
                    Write-Output -InputObject "Windows Update (WSUS) policy settings reset successful."
                    exit 0
                }
            }
            else {
                Write-Output -InputObject "Windows Update (WSUS) policy settings is empty."
                exit 0
            }
        }
        else {
            Write-Output -InputObject "Windows Update (WSUS) policy settings not found."
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