#requires -Version 5.1
<#
.SYNOPSIS
    Collect Microsoft Defender BitLocker encryption method for System drive.
.DESCRIPTION
    Collect Microsoft Defender BitLocker encryption method for System drive, fails if encryption differ fom requerements.
    Ref.: https://docs.microsoft.com/en-us/powershell/module/bitlocker/enable-bitlocker/
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
    version: 1.4.0.2
    date: June 3, 2024
    license: MIT License
.LINK
    [Jesper on Bluesky](https://bsky.app/profile/dotjesper.bsky.social "Jesper on Bluesky")
    [Jesper on GitHub](https://github.com/dotjesper/ "Jesper on GitHub")
#>
[CmdletBinding()]
param (
    #variables
    [Parameter (Mandatory = $False, HelpMessage = "Choose required encryption method") ]
    [ValidateSet(3,4,6,7)]
    [int]$requiredEncryptionMethod = 6
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
        [array]$encryptionMethod = Get-CimInstance -namespace "Root\cimv2\security\MicrosoftVolumeEncryption" -ClassName "Win32_Encryptablevolume" -Filter "DriveLetter = '$($env:SystemDrive)'"
        if ($($encryptionMethod.EncryptionMethod) -eq $requiredEncryptionMethod) {
            Write-Output -InputObject "Microsoft Defender BitLocker Drive encryption method for System drive compliant ($($encryptionMethod.EncryptionMethod))"
            exit 0
        }
        else {
            Write-Output -InputObject "Microsoft Defender BitLocker Drive encryption method for System drive non-compliant ($($encryptionMethod.EncryptionMethod))"
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
