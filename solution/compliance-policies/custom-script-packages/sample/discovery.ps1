#requires -Version 5.1
<#
.SYNOPSIS
    Hello world sample script for exploring custom compliance polices.
.DESCRIPTION
    Hello world sample script for exploring custom compliance polices.
    This script will return the Manufacturer, BIOS version and if a TPM chip is present.
.EXAMPLE
    .\discovery.ps1
.NOTES
    version: 1.0
    author: Jesper Nielsen
    date: May 16, 2024
    source: https://learn.microsoft.com/mem/intune/protect/compliance-custom-script/
#>
$WMI_ComputerSystem = Get-WMIObject -class Win32_ComputerSystem
$WMI_BIOS = Get-WMIObject -class Win32_BIOS
$TPM = Get-Tpm

$hash = @{ Manufacturer = $WMI_ComputerSystem.Manufacturer; BiosVersion = $WMI_BIOS.SMBIOSBIOSVersion; TPMChipPresent = $TPM.TPMPresent}
return $hash | ConvertTo-Json -Compress
