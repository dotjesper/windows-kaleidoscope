<#
.SYNOPSIS
    Custom compliance discovery script for Windows disk encryption validation.

.DESCRIPTION
    Collects BitLocker Drive Encryption status from the system drive, including protection
    status, encryption method, key protector type, volume status, and PIN protector presence.
    Returns the values as compressed JSON for evaluation by Microsoft Intune custom compliance rules.

.EXAMPLE
    .\discovery.ps1

    Run the script with default parameters.

.EXAMPLE
    .\discovery.ps1 -Verbose

    Run the script with verbose output.

.NOTES
    version: 1.0.0
    date: June 12, 2024
    license: MIT License

.LINK
    https://github.com/dotjesper/windows-kaleidoscope
#>

#requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding()]
param ()
begin {
    Set-StrictMode -Version Latest

    # variables :: Conditions
    [bool]$runScriptIn64bitPowerShell = $true

    # variables :: Environment
}
process {
    #region :: Check conditions
    if ($runScriptIn64bitPowerShell -eq $true -and $([System.Environment]::Is64BitProcess) -eq $false) {
        Write-Error -Message 'Windows PowerShell 64-bit is required.' -Category 'ResourceUnavailable' -ErrorId 'B001'
        exit 1
    }
    #endregion

    #region :: Main logic
    try {
        $bitLockerVolume = Get-BitLockerVolume -MountPoint "$env:SystemDrive"
        [string]$ProtectionStatus = $bitLockerVolume.ProtectionStatus
        [string]$EncryptionMethod = $bitLockerVolume.EncryptionMethod
        [string]$KeyProtectorType = ($bitLockerVolume.KeyProtector | Where-Object { $_.KeyProtectorType -like 'Tpm*' }).KeyProtectorType
        [string]$VolumeStatus = $bitLockerVolume.VolumeStatus
        [string]$PinProtectorEnabled = if ($bitLockerVolume.KeyProtector | Where-Object { $_.KeyProtectorType -eq 'TpmPin' }) { 'True' } else { 'False' }
    }
    catch {
        $errMsg = $_.Exception.Message
        Write-Error -Message $errMsg
        exit 1
    }
    finally {}
    #endregion
}
end {
    $hash = @{ ProtectionStatus = $ProtectionStatus; KeyProtectorType = $KeyProtectorType; EncryptionMethod = $EncryptionMethod; VolumeStatus = $VolumeStatus; PinProtectorEnabled = $PinProtectorEnabled }
    return $hash | ConvertTo-Json -Compress
}
