<#
.SYNOPSIS
    Collect Microsoft Defender BitLocker metrics.

.DESCRIPTION
    Script will collect Microsoft Defender BitLocker metrics. This script will return the Windows disk encryption values.
    Script is a companion script to the custom compliance policy script for Windows encryption.

.PARAMETER ProtectionStatus
    Choose Protection Status. Default is On.

.PARAMETER EncryptionMethod
    Choose Encryption Method. Default is XtsAes128.

.PARAMETER KeyProtectorType
    Choose Key Protector Type. Default is Tpm.

.PARAMETER VolumeStatus
    Choose Volume Status. Default is FullyEncrypted.

.EXAMPLE
    .\detect.ps1

.NOTES
    version: 1.0.0
    date: August 7, 2024
    license: MIT License

.LINK
    https://github.com/dotjesper/windows-kaleidoscope
#>

#requires -Version 5.1
#requires -RunAsAdministrator

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false, HelpMessage = 'Choose Protection Status')]
    [ValidateSet('On', 'Off')]
    [string]$ProtectionStatus = 'On',

    [Parameter(Mandatory = $false, HelpMessage = 'Choose Encryption Method')]
    [ValidateSet('Aes128', 'Aes256', 'XtsAes128', 'XtsAes256')]
    [string]$EncryptionMethod = 'XtsAes128',

    [Parameter(Mandatory = $false, HelpMessage = 'Choose Key Protector Type')]
    [ValidateSet('Tpm', 'TpmAndPin')]
    [string]$KeyProtectorType = 'Tpm',

    [Parameter(Mandatory = $false, HelpMessage = 'Choose Volume Status')]
    [ValidateSet('FullyEncrypted', 'FullyDecrypted')]
    [string]$VolumeStatus = 'FullyEncrypted'
)

begin {
    Set-StrictMode -Version Latest

    # variables :: Conditions
    [bool]$runScriptIn64bitPowerShell = $false

    # variables :: Environment
    [datetime]$scriptStartTime = (Get-Date).ToUniversalTime()
}
process {
    #region :: Check conditions
    if ($runScriptIn64bitPowerShell -eq $true -and $([System.Environment]::Is64BitProcess) -eq $false) {
        Write-Error -Message 'Windows PowerShell 64-bit is required.' -Category 'ResourceUnavailable' -ErrorId 'B001'
        exit 1
    }
    #endregion
    try {
        $bitLockerVolume = Get-BitLockerVolume -MountPoint "$env:SystemDrive"
        [string]$currentProtectionStatus = $bitLockerVolume.ProtectionStatus
        [string]$currentEncryptionMethod = $bitLockerVolume.EncryptionMethod
        [string]$currentKeyProtectorType = ($bitLockerVolume.KeyProtector | Where-Object { $_.KeyProtectorType -like 'Tpm*' }).KeyProtectorType
        [string]$currentVolumeStatus = $bitLockerVolume.VolumeStatus
        [string]$elapsedTime = ('{0:00.000}' -f ((Get-Date).ToUniversalTime() - $scriptStartTime).TotalSeconds) -replace ',', '.'
        if ($ProtectionStatus -eq $currentProtectionStatus -and $EncryptionMethod -eq $currentEncryptionMethod -and $KeyProtectorType -eq $currentKeyProtectorType -and $VolumeStatus -eq $currentVolumeStatus) {
            Write-Output -InputObject "[$elapsedTime] Device is Compliant | Protection Status: $currentProtectionStatus | Key Protector Type: $currentKeyProtectorType | Encryption Method: $currentEncryptionMethod | Volume Status: $currentVolumeStatus"
            exit 0
        }
        else {
            Write-Output -InputObject "[$elapsedTime] Device is Non-Compliant | Protection Status: $currentProtectionStatus | Key Protector Type: $currentKeyProtectorType | Encryption Method: $currentEncryptionMethod | Volume Status: $currentVolumeStatus"
            exit 1
        }
    }
    catch {
        $errorMessage = $_.Exception.Message
        Write-Error -Message $errorMessage -Category 'SyntaxError' -ErrorId 'C001'
        exit 1
    }
    finally {}
}
end {}
