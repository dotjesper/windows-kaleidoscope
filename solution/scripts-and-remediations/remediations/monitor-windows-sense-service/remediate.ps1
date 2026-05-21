<#
.SYNOPSIS
    Monitor Windows Sense service.

.DESCRIPTION
    New Windows 11, version 24H2 devices that are intended to be onboarded to Microsoft Defender for Endpoint might require administrators to enable the prerequisite feature.
    This affects all supported architectures.

    If the service does not exist, the script will attempt to add Windows Sense Client Capability feature.
    - Defender for Endpoint has been removed from the base image for Windows 11, version 24H2 and needs to be manually installed
      See https://support.microsoft.com/topic/kb5043950-windows-11-version-24h2-support-2fd719b6-8c26-469f-99fe-832eb1b702d7

.EXAMPLE
    .\remediate.ps1

.NOTES
    version: 1.0.2
    date: October 18, 2024
    license: MIT License

.LINK
    https://github.com/dotjesper/windows-kaleidoscope
#>

#requires -Version 5.1
#requires -RunAsAdministrator

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
        $WindowsSenseService = Get-Service -Name 'Sense' -ErrorAction SilentlyContinue
        if ($WindowsSenseService) {
            Write-Verbose -Message "Windows Sense service is present [$($WindowsSenseService.Status)]"
            exit 0
        }
        else {
            # Reboot values for tracking pending reboot
            [string]$regRoot = 'HKLM'
            [string]$regPath = 'SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired'
            [string]$rebootReason = 'Pending changes for Microsoft.Windows.Sense.Client'
            [string]$rebootReasonId = '42213B79-8E7B-4D8D-BF6C-8FBEE33079EA'

            # Check if the registry key for a required reboot exists
            if (Test-Path -Path $($regRoot + ':\' + $regPath)) {
                $getRebootReasonId = $(Get-ItemProperty -Path "Registry::$regRoot\$regPath" -Name 'RebootReasonId' -ErrorAction SilentlyContinue).RebootReasonId
                if ($getRebootReasonId -eq $rebootReasonId) {
                    Write-Verbose -Message "Windows Sense service not found - $rebootReason"
                    exit 0
                }
            }
            Write-Verbose -Message 'Windows Sense service not found.'

            # Add Windows Sense Client Capability feature
            Write-Verbose -Message 'Attempting to add Windows Sense Client Capability feature'
            $WindowsCapabilityStatus = Add-WindowsCapability -Online -Name 'Microsoft.Windows.Sense.Client~~~~' -Verbose:$false
            Write-Verbose -Message 'Windows Sense Client Capability feature added'

            # Add reboot reason to the registry to track the pending reboot
            if ($WindowsCapabilityStatus.RestartNeeded) {
                Write-Verbose -Message 'Reboot is required to complete the installation of Windows Sense Client Capability feature'
                if (-not (Test-Path -Path $($regRoot + ':\' + $regPath))) {
                    $null = New-Item -Path "Registry::$regRoot\$regPath" -Force
                }
                $null = New-ItemProperty -Path "Registry::$regRoot\$regPath" -Name 'RebootReason' -Value $rebootReason -PropertyType 'String' -Force
                $null = New-ItemProperty -Path "Registry::$regRoot\$regPath" -Name 'RebootReasonId' -Value $rebootReasonId -PropertyType 'String' -Force
                Write-Verbose -Message "Pending reboot has been set with reason: $rebootReason [$rebootReasonId]"
            }
            exit 0
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
