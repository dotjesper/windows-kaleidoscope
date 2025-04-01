#requires -Version 5.1
<#
.SYNOPSIS
    Collect firmware mode (UEFI ir BIOS)
.DESCRIPTION
    This PowerShell script determine the underlying system firmware (BIOS) mode - either UEFI or Legacy BIOS.
    1: Legacy BIOS
    2: UEFI
.PARAMETER requiredBIOSmode
    Choose required BIOS mode [1] BIOS, [2] UEFI. Default is UEFI.
.EXAMPLE
    .\detect.ps1
.OUTPUTS
    Detected BIOS mode: Legacy BIOS (1) | TPM: 2.0
    Detected BIOS mode: UEFI (2) with Secure Boot | TPM: 2.0
    Detected BIOS mode: UEFI (2) without Secure Boot | TPM: 2.0
    Detected BIOS mode: Unknown (0) | TPM: TPM not found
.NOTES
    version: 1.1.0.8
    date: May 16, 2023
    license: MIT License
.LINK
    [Jesper on Bluesky](https://bsky.app/profile/dotjesper.bsky.social "Jesper on Bluesky")
    [Jesper on GitHub](https://github.com/dotjesper/ "Jesper on GitHub")
#>
[CmdletBinding()]
param (
    #variables
    [Parameter (Mandatory = $False, HelpMessage = "Choose required BIOS mode [1] BIOS, [2] UEFI") ]
    [ValidateRange(1,2)]
    [int]$requiredBIOSmode = 2
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
        # detected BIOS mode
        Add-Type -Language CSharp -TypeDefinition @'
        using System;
        using System.Runtime.InteropServices;

        public class FirmwareType
        {
            [DllImport("kernel32.dll")]
            static extern bool GetFirmwareType(ref uint FirmwareType);

            public static uint GetFirmwareType()
            {
                uint firmwaretype = 0;
                if (GetFirmwareType(ref firmwaretype))
                    return firmwaretype;
                else
                    return 0;   // API call failed, just return 'unknown'
            }
        }
'@
        #region :: validate TPM Spec Version
        [string]$TPMSpecVersion = (Get-CimInstance -Namespace "root/cimv2/Security/MicrosoftTpm" -ClassName "Win32_Tpm").SpecVersion
        if ($null -eq $TPMSpecVersion) {
            $TPMSpecVersion = "TPM not found"
        }
        #endregion
        #region :: validate BIOS mode
        [int]$detectedBIOSmode = [FirmwareType]::GetFirmwareType()
        switch ($detectedBIOSmode) {
            1 {
                Write-Output -InputObject "Detected BIOS mode: Legacy BIOS ($detectedBIOSmode) | TPM: $TPMSpecVersion"
            }
            2 {
                if (Confirm-SecureBootUEFI) {
                    Write-Output -InputObject "Detected BIOS mode: UEFI ($detectedBIOSmode) with Secure Boot | TPM: $TPMSpecVersion | $((Get-SecureBootUEFI -Name SetupMode).Name)"
                }
                else {
                    Write-Output -InputObject "Detected BIOS mode: UEFI ($detectedBIOSmode) without Secure Boot | TPM: $TPMSpecVersion"
                }
            }
            default {
                Write-Output -InputObject "Detected BIOS mode: Unknown ($detectedBIOSmode) | TPM: $TPMSpecVersion"
            }
        }
        #endregion
        if ($detectedBIOSmode -eq $requiredBIOSmode) {
            exit 0
        }
        else {
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
