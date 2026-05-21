<#
.SYNOPSIS
    Monitor the status of Microsoft OneDrive for Business Known Folder Move (KFM).

.DESCRIPTION
    Today, organizations can benefit from monitoring the use of Microsoft OneDrive for Business, and in particular the status of Known Folder Move (KFM), enabling OneDrive Health monitoring using https://config.office.com/officeSettings/onedrive/.
    However, in the case where devices have issues moving one or more folders to Microsoft OneDrive for Business, this script will monitor and remediate (re-initialize) the Known Folder Move (KFM) process.

.EXAMPLE
    .\detect.ps1

    This will check the status of OneDrive for Business Known Folder Move (KFM) for the user running the script.

.NOTES
    version: 1.3.2
    date: July 3, 2024
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
    [bool]$runUsingLoggedOnCredentials = $true

    # variables :: Environment
    [datetime]$scriptStartTime = (Get-Date).ToUniversalTime()
}
process {
    #region :: Check conditions
    if ($runScriptIn64bitPowerShell -eq $true -and $([System.Environment]::Is64BitProcess) -eq $false) {
        Write-Error -Message 'Windows PowerShell 64-bit is required.' -Category 'ResourceUnavailable' -ErrorId 'B001'
        exit 1
    }
    if ($runUsingLoggedOnCredentials -eq $true -and $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name -eq 'NT AUTHORITY\SYSTEM')) {
        Write-Error -Message 'Script is running as SYSTEM. Please run the script as user.' -Category 'ResourceUnavailable' -ErrorId 'B002'
        exit 1
    }
    #endregion

    #region :: Main logic
    try {
        # Check if the registry path for OneDrive KFM exists
        [string]$regRoot = 'HKCU'
        [string]$regPath = 'SOFTWARE\Microsoft\OneDrive\Accounts\Business1'

        # Check if the registry path for OneDrive KFM exists
        if (-not (Test-Path -Path $($regRoot + ":\" + $regPath))) {
            [string]$elapsedTime = ('{0:00.000}' -f ((Get-Date).ToUniversalTime() - $scriptStartTime).TotalSeconds) -replace ',', '.'
            Write-Output -InputObject "[$elapsedTime] OneDrive Known Folder Move for Business1 registry path not found."
            exit 1
        }

        # Check the values of KfmFoldersProtectedNow and KfmFoldersProtectedOnce
        [array]$regValues = Get-ItemProperty -Path "Registry::$regRoot\$regPath"
        [string]$elapsedTime = ('{0:00.000}' -f ((Get-Date).ToUniversalTime() - $scriptStartTime).TotalSeconds) -replace ',', '.'
        if ($regValues.KfmFoldersProtectedNow -eq $regValues.KfmFoldersProtectedOnce) {
            Write-Output -InputObject "[$elapsedTime] OneDrive Known Folder Move for Business1 has moved all folders correctly [$($regValues.KfmFoldersProtectedNow) | $($regValues.KfmFoldersProtectedOnce)]."
            exit 0
        }
        else {
            if ($null -eq $regValues.KfmFoldersProtectedOnce -or $regValues.KfmFoldersProtectedOnce -eq '') {
                Write-Output -InputObject "[$elapsedTime] OneDrive Known Folder Move for Business1 (KfmFoldersProtectedOnce) is empty."
                exit 0
            }
            else {
                Write-Output -InputObject "[$elapsedTime] OneDrive Known Folder Move for Business1 folder has failed [$($regValues.KfmFoldersProtectedNow) | $($regValues.KfmFoldersProtectedOnce)]."
                exit 1
            }
        }
    }
    catch {
        $errMsg = $_.Exception.Message
        Write-Error -Message $errMsg -Category 'SyntaxError' -ErrorId 'C001'
        exit 1
    }
    finally {}
    #endregion
}
end {}
