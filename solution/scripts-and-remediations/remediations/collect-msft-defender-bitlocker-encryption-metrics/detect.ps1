#requires -Version 5.1
<#
.SYNOPSIS
    Collect Microsoft Defender BitLocker metrics.
.DESCRIPTION
    Script will collect Microsoft Defender BitLocker metrics. This script will return the Windows disk encryption values.
    Script is a companien script to the custom compliance policy script for Windows encryption.
.PARAMETER ProtectionStatus
    Choose Protection Status. Default is On.
.PARAMETER EncryptionMethod
    Choose Encryption Method. Default is XtsAes128.
.PARAMETER KeyProtectorType
    Choose Key Protector Type. Default is Tpm.
.EXAMPLE
    .\detect.ps1
.NOTES
    version: 1.0.0.0
    date: August 7, 2024
    license: MIT License
.LINK
    [Jesper on Bluesky](https://bsky.app/profile/dotjesper.bsky.social "Jesper on Bluesky")
    [Jesper on GitHub](https://github.com/dotjesper/ "Jesper on GitHub")
#>
[CmdletBinding()]
param (
    #variables
    [Parameter (Mandatory = $False, HelpMessage = "Choose Protection Status") ]
    [ValidateSet("On","Off")]
    [string]$ProtectionStatus = "On",
    [Parameter (Mandatory = $False, HelpMessage = "Choose Encryption Method") ]
    [ValidateSet("Aes128","Aes256","XtsAes128","XtsAes256")]
    [string]$EncryptionMethod = "XtsAes128",
    [Parameter (Mandatory = $False, HelpMessage = "Choose Key Protector Type") ]
    [ValidateSet("Tpm","TpmAndPin")]
    [string]$KeyProtectorType = "Tpm",
    [Parameter (Mandatory = $False, HelpMessage = "Choose Volume Status") ]
    [ValidateSet("FullyEncrypted","FullyDecrypted")]
    [string]$VolumeStatus = "FullyEncrypted"
)
begin {
    #variables :: conditions
    [bool]$runScriptIn64bitPowerShell = $false
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
        [string]$qProtectionStatus = ($(Get-BitLockerVolume -MountPoint "$env:SystemDrive").ProtectionStatus)
        [string]$qEncryptionMethod = ($(Get-BitLockerVolume -MountPoint "$env:SystemDrive").EncryptionMethod)
        [string]$qKeyProtectorType = ($(Get-BitLockerVolume -MountPoint "$env:SystemDrive").KeyProtector | Where-Object { $_.KeyProtectorType -like "Tpm*" }).KeyProtectorType
        [string]$qVolumeStatus = ($(Get-BitLockerVolume -MountPoint "$env:SystemDrive").VolumeStatus)
        if ($ProtectionStatus -eq $qProtectionStatus -and $EncryptionMethod -eq $qEncryptionMethod -and $KeyProtectorType -eq $qKeyProtectorType -and $VolumeStatus -eq $qVolumeStatus) {
            Write-Output -InputObject "Device is Compliant | Protection Status: $qProtectionStatus | Key Protector Type: $qKeyProtectorType | Encryption Method: $qEncryptionMethod | Volume Status: $qVolumeStatus"
            exit 0
        }
        else {
            Write-Output -InputObject "Device is Non-Compliant | Protection Status: $qProtectionStatus | Key Protector Type: $qKeyProtectorType | Encryption Method: $qEncryptionMethod"
            exit 1
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
