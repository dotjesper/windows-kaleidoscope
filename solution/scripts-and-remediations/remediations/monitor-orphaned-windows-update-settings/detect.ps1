<#
.SYNOPSIS
    Monitor orphaned Windows Update (WSUS) settings.

.DESCRIPTION
    Monitor orphaned Windows Update (WSUS) settings.
    Solution based on information from Windows Autopatch conflicting configurations
    https://learn.microsoft.com/windows/deployment/windows-autopatch/references/windows-autopatch-conflicting-configurations

.EXAMPLE
    .\detect.ps1

    Run the script with default parameters.

.NOTES
    version: 1.2.5
    date: October 19, 2023
    license: MIT License

.LINK
    https://github.com/dotjesper/windows-kaleidoscope
#>

#requires -Version 5.1

[CmdletBinding()]
param ()

begin {
    Set-StrictMode -Version Latest

    # variables :: Conditions
    [bool]$runScriptIn64bitPowerShell = $true

    # variables :: Environment
    [string]$regRoot = 'HKLM'
    [string]$regPath = 'Software\Policies\Microsoft\Windows\WindowsUpdate'
    [datetime]$scriptStartTime = (Get-Date).ToUniversalTime()
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
        if (Test-Path -Path $($regRoot + ':\' + $regPath)) {
            #Get WindowsUpdate values
            [array]$regValues = Get-ItemProperty -Path "Registry::$regRoot\$regPath"
            if ($regValues.Length -gt 0) {
                [string]$outputMessage = 'Windows Update (WSUS) policy settings'
                if ($null -ne $regValues.TargetReleaseVersionInfo) {
                    $outputMessage = "$outputMessage | TRVI: $($regValues.TargetReleaseVersionInfo)"
                }
                if ($null -ne $regValues.DoNotConnectToWindowsUpdateInternetLocations) {
                    $outputMessage = "$outputMessage | DNCTWUIL: $($regValues.DoNotConnectToWindowsUpdateInternetLocations)"
                }
                if ($null -ne $regValues.DisableWindowsUpdateAccess) {
                    $outputMessage = "$outputMessage | DWUA: $($regValues.DisableWindowsUpdateAccess)"
                }
                if ($null -ne $regValues.WUServer) {
                    $outputMessage = "$outputMessage | WUS: $($regValues.WUServer)"
                }
                if ($null -ne $regValues.WUStatusServer) {
                    $outputMessage = "$outputMessage | WUSS: $($regValues.WUStatusServer)"
                }
                #Get AU values
                if (Test-Path -Path $($regRoot + ':\' + $regPath + '\AU')) {
                    [array]$regValues = Get-ItemProperty -Path "Registry::$regRoot\$regPath\AU"
                    if ($null -ne $regValues.UseWUServer) {
                        $outputMessage = "$outputMessage | UseWUS: $($regValues.UseWUServer)"
                    }
                    if ($null -ne $regValues.NoAutoUpdate) {
                        $outputMessage = "$outputMessage | NAU: $($regValues.NoAutoUpdate)"
                    }
                }
                [string]$elapsedTime = ('{0:00.000}' -f ((Get-Date).ToUniversalTime() - $scriptStartTime).TotalSeconds) -replace ',', '.'
                Write-Output -InputObject $("[$elapsedTime] " + $($outputMessage[0..2048] -join ''))
                exit 1
            }
            else {
                [string]$elapsedTime = ('{0:00.000}' -f ((Get-Date).ToUniversalTime() - $scriptStartTime).TotalSeconds) -replace ',', '.'
                Write-Output -InputObject "[$elapsedTime] Windows Update (WSUS) policy settings is empty."
                exit 0
            }
        }
        else {
            [string]$elapsedTime = ('{0:00.000}' -f ((Get-Date).ToUniversalTime() - $scriptStartTime).TotalSeconds) -replace ',', '.'
            Write-Output -InputObject "[$elapsedTime] Windows Update (WSUS) policy settings not found."
            exit 0
        }
    }
    catch {
        $errorMessage = $_.Exception.Message
        Write-Error -Message $errorMessage -Category 'SyntaxError' -ErrorId 'C001'
        exit 1
    }
    finally {}
    #endregion
}
end {}
