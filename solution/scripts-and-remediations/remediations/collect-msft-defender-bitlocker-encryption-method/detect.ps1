<#
.SYNOPSIS
    Collect Microsoft Defender BitLocker encryption method for System drive.

.DESCRIPTION
    Collect Microsoft Defender BitLocker encryption method for System drive, fails if encryption differs from requirements.
    Ref.: https://learn.microsoft.com/powershell/module/bitlocker/enable-bitlocker/
    Ref.: https://devblogs.microsoft.com/scripting/powershell-and-bitlocker-part-2/

.PARAMETER requiredEncryptionMethod
    Choose required encryption method:
    3: AES-CBC 128-bit
    4: AES-CBC 256-bit
    6: XTS-AES 128-bit (default)
    7: XTS-AES 256-bit

.EXAMPLE
    .\detect.ps1

.NOTES
    version: 1.4.5
    date: June 3, 2024
    license: MIT License

.LINK
    https://github.com/dotjesper/windows-kaleidoscope
#>

#requires -Version 5.1
#requires -RunAsAdministrator

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false, HelpMessage = 'Choose required encryption method')]
    [ValidateSet(3, 4, 6, 7)]
    [int]$requiredEncryptionMethod = 6
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
        [array]$volumeEncryption = Get-CimInstance -Namespace 'Root\cimv2\security\MicrosoftVolumeEncryption' -ClassName 'Win32_Encryptablevolume' -Filter "DriveLetter = '$($env:SystemDrive)'"
        [string]$elapsedTime = ('{0:00.000}' -f ((Get-Date).ToUniversalTime() - $scriptStartTime).TotalSeconds) -replace ',', '.'
        if ($($volumeEncryption.EncryptionMethod) -eq $requiredEncryptionMethod) {
            Write-Output -InputObject "[$elapsedTime] Microsoft Defender BitLocker Drive encryption method for System drive compliant ($($volumeEncryption.EncryptionMethod))"
            exit 0
        }
        else {
            Write-Output -InputObject "[$elapsedTime] Microsoft Defender BitLocker Drive encryption method for System drive non-compliant ($($volumeEncryption.EncryptionMethod))"
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
