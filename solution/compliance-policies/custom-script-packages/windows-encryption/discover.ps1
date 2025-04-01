#requires -Version 5.1
<#
.SYNOPSIS
    Custom compliance policy script for Windows encryption.
.DESCRIPTION
    This script will return the Windows disk encryption values.
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
        [string]$ProtectionStatus = ($(Get-BitLockerVolume -MountPoint "$env:SystemDrive").ProtectionStatus)
        [string]$EncryptionMethod = ($(Get-BitLockerVolume -MountPoint "$env:SystemDrive").EncryptionMethod)
        [string]$KeyProtectorType = ($(Get-BitLockerVolume -MountPoint "$env:SystemDrive").KeyProtector | Where-Object { $_.KeyProtectorType -like "Tpm*" }).KeyProtectorType
        [string]$VolumeStatus = ($(Get-BitLockerVolume -MountPoint "$env:SystemDrive").VolumeStatus)
    }
    catch {
        $errMsg = $_.Exception.Message
        Write-Error -Message $errMsg
        exit 1
    }
    finally {}
}
end {
    $hash = @{ ProtectionStatus = $ProtectionStatus; KeyProtectorType = $KeyProtectorType; EncryptionMethod = $EncryptionMethod; $VolumeStatus = $VolumeStatus}
    return $hash | ConvertTo-Json -Compress
}
