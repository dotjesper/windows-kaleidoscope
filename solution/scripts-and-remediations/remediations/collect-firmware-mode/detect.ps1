<#
.SYNOPSIS
    Collect firmware mode (UEFI or BIOS).

.DESCRIPTION
    This PowerShell script determines the underlying system firmware (BIOS) mode - either UEFI or Legacy BIOS.
    1: Legacy BIOS
    2: UEFI

    The script uses Add-Type with inline C# to call the GetFirmwareType Windows API. This approach is
    incompatible with PowerShell Constrained Language Mode. If CLM is detected, the script exits with
    an error.

.PARAMETER RequiredBiosMode
    Choose required BIOS mode [1] BIOS, [2] UEFI. Default is UEFI.

.EXAMPLE
    .\detect.ps1

    Detect firmware mode using the default required mode (UEFI).

.EXAMPLE
    .\detect.ps1 -RequiredBiosMode 1

    Detect firmware mode with Legacy BIOS as the required mode.

.OUTPUTS
    Detected BIOS mode: Legacy BIOS (1) | TPM: 2.0
    Detected BIOS mode: UEFI (2) with Secure Boot | TPM: 2.0
    Detected BIOS mode: UEFI (2) without Secure Boot | TPM: 2.0
    Detected BIOS mode: Unknown (0) | TPM: TPM not found

.NOTES
    version: 1.2.0
    date: May 16, 2023
    license: MIT License

.LINK
    https://github.com/dotjesper/windows-kaleidoscope
#>

#requires -Version 5.1
#requires -RunAsAdministrator

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false, HelpMessage = 'Choose required BIOS mode [1] BIOS, [2] UEFI')]
    [ValidateRange(1, 2)]
    [int]$RequiredBiosMode = 2
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

    # Check for Constrained Language Mode (CLM) which is incompatible with Add-Type and inline C#
    if ($ExecutionContext.SessionState.LanguageMode -eq 'ConstrainedLanguage') {
        Write-Error -Message 'Constrained Language Mode is not supported. Add-Type requires Full Language Mode.' -Category 'ResourceUnavailable' -ErrorId 'B003'
        exit 1
    }
    #endregion

    try {
        # Detect BIOS mode using GetFirmwareType Windows API
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
        [string]$tpmSpecVersion = (Get-CimInstance -Namespace 'root/cimv2/Security/MicrosoftTpm' -ClassName 'Win32_Tpm' -ErrorAction SilentlyContinue).SpecVersion
        if ($null -eq $tpmSpecVersion) {
            [string]$tpmSpecVersion = 'TPM not found'
        }
        #endregion

        #region :: validate BIOS mode
        [int]$detectedBiosMode = [FirmwareType]::GetFirmwareType()
        [string]$elapsedTime = ('{0:00.000}' -f ((Get-Date).ToUniversalTime() - $scriptStartTime).TotalSeconds) -replace ',', '.'
        switch ($detectedBiosMode) {
            1 {
                Write-Output -InputObject "[$elapsedTime] Detected BIOS mode: Legacy BIOS ($detectedBiosMode) | TPM: $tpmSpecVersion"
            }
            2 {
                [bool]$secureBootEnabled = $false
                try {
                    $secureBootEnabled = Confirm-SecureBootUEFI
                }
                catch {
                    Write-Verbose -Message "Confirm-SecureBootUEFI failed: $($_.Exception.Message)"
                }
                if ($secureBootEnabled) {
                    [string]$setupMode = ''
                    try {
                        $setupMode = " | $((Get-SecureBootUEFI -Name SetupMode).Name)"
                    }
                    catch {
                        Write-Verbose -Message "Get-SecureBootUEFI failed: $($_.Exception.Message)"
                    }
                    Write-Output -InputObject "[$elapsedTime] Detected BIOS mode: UEFI ($detectedBiosMode) with Secure Boot | TPM: $tpmSpecVersion$setupMode"
                }
                else {
                    Write-Output -InputObject "[$elapsedTime] Detected BIOS mode: UEFI ($detectedBiosMode) without Secure Boot | TPM: $tpmSpecVersion"
                }
            }
            default {
                Write-Output -InputObject "[$elapsedTime] Detected BIOS mode: Unknown ($detectedBiosMode) | TPM: $tpmSpecVersion"
            }
        }
        #endregion
        if ($detectedBiosMode -eq $RequiredBiosMode) {
            exit 0
        }
        else {
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
