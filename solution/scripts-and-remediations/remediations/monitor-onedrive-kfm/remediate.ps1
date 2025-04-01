#requires -Version 5.1
<#
.SYNOPSIS
    Monitor the status of Microsoft OneDrive for Business Known Folder Move (KFM).
.DESCRIPTION
    Today, organizations, can benefit from monitoring the use of Microsoft OneDrive for Business, and in particular the status of Known Folder Move (KFM), enabling OneDrive Health monitoring using https://config.office.com/officeSettings/onedrive/.
    However; in the case where a devices have issues, moving one or more folder to Microsoft OneDrive for Business, this script will monitor and remidiate (re-initilize) the Known Folder Move (KFM) process.
.EXAMPLE
    .\remidiate.ps1
.NOTES
    version: 1.3.2.5
    date: July 3, 2024
    license: MIT License
.LINK
    [Jesper on Bluesky](https://bsky.app/profile/dotjesper.bsky.social "Jesper on Bluesky")
    [Jesper on GitHub](https://github.com/dotjesper/ "Jesper on GitHub")
#>
[CmdletBinding()]
param (
    #variables
    [bool]$stopProcess = $false
)
begin {
    #variables :: conditions
    [bool]$runScriptIn64bitPowerShell = $true
    [bool]$runUsingLoggedOnCredentials = $true
    #variables :: environment
}
process {
    #region check conditions
    if ($runScriptIn64bitPowerShell -eq $true -and $([System.Environment]::Is64BitProcess) -eq $false) {
        Write-Error -Message "Windows PowerShell 64-bit is requered." -Category "ResourceUnavailable" -ErrorId "B001"
        exit 1
    }
    if ($runUsingLoggedOnCredentials -eq $true -and $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name -eq "NT AUTHORITY\SYSTEM")) {
        Write-Error -Message "Script is running as SYSTEM. Please run the script as user." -Category "ResourceUnavailable" -ErrorId "B002"
        exit 1
    }
    #endregion
    try {
        [string]$regRoot = "HKCU"
        [string]$regPath = "SOFTWARE\Microsoft\OneDrive\Accounts\Business1"
        [array]$regValues = Get-ItemProperty -Path "Registry::$regRoot\$regPath"
        if ($regValues.KfmFoldersProtectedNow -eq $regValues.KfmFoldersProtectedOnce) {
            Write-Output -InputObject "OneDrive Known Folder Move for Business1 has moved all folders correctly [ $($regValues.KfmFoldersProtectedNow) | $($regValues.KfmFoldersProtectedOnce) ]."
            exit 0
        }
        else {
            Remove-ItemProperty -Path "Registry::$regRoot\$regPath" -Name "KfmFoldersProtectedOnce"
            if ($stopProcess) {
                $onedriveProcesses = Get-Process -Name "OneDrive"
                foreach ($onedriveProcess in $onedriveProcesses) {
                    Stop-Process -Id $($onedriveProcess.Id) -Force
                }
            }
            Write-Output -InputObject "OneDrive Known Folder Move for Business1 folder move has been reinitiated."
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
