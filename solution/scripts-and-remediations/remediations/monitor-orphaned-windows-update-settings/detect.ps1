#requires -Version 5.1
<#
.SYNOPSIS
    Monitor orphaned Windows Update (WSUS) settings.
.DESCRIPTION
    Monitor orphaned Windows Update (WSUS) settings.
    Solution based on information from Windows Autopatch conflicting configurations
    https://learn.microsoft.com/windows/deployment/windows-autopatch/references/windows-autopatch-conflicting-configurations
.EXAMPLE
    .\detect.ps1
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
            #Get WindowsUpdate values
            [array]$regValues = Get-ItemProperty -Path "Registry::$regRoot\$regPath"
            if ($regValues.Length -gt 0) {
                $txt = "Windows Update (WSUS) policy settings"
                if ($null -ne $regValues.TargetReleaseVersionInfo) {
                    $txt = "$txt | TRVI: $($regValues.TargetReleaseVersionInfo)"
                }
                if ($null -ne $regValues.DoNotConnectToWindowsUpdateInternetLocations) {
                    $txt = "$txt | DNCTWUIL: $($regValues.DoNotConnectToWindowsUpdateInternetLocations)"
                }
                if ($null -ne $regValues.DisableWindowsUpdateAccess) {
                    $txt = "$txt | DWUA: $($regValues.DisableWindowsUpdateAccess)"
                }
                if ($null -ne $regValues.WUServer) {
                    $txt = "$txt | WUS: $($regValues.WUServer)"
                }
                if ($null -ne $regValues.WUStatusServer) {
                    $txt = "$txt | WUSS: $($regValues.WUStatusServer)"
                }
                #Get AU values
                if (Test-Path -Path $($regRoot + ":\" + $regPath + "\AU")) {
                    [array]$regValues = Get-ItemProperty -Path "Registry::$regRoot\$regPath\AU"
                    if ($null -ne $regValues.UseWUServer) {
                        $txt = "$txt | UseWUS: $($regValues.UseWUServer)"
                    }
                    if ($null -ne $regValues.NoAutoUpdate) {
                        $txt = "$txt | NAU: $($regValues.NoAutoUpdate)"
                    }
                }
                Write-Output -InputObject $("$txt"[0..500] -join "")
                exit 1
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