<#

.SYNOPSIS
    Monitor orphaned Windows Update (WSUS) settings.

.DESCRIPTION
    Monitor orphaned Windows Update (WSUS) settings.
    Solution based on information from Windows Autopatch conflicting configurations
    https://learn.microsoft.com/windows/deployment/windows-autopatch/references/windows-autopatch-conflicting-configurations

.EXAMPLE
    .\remediate.ps1

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
            # Get WindowsUpdate values
            [array]$regValues = Get-ItemProperty -Path "Registry::$regRoot\$regPath"
            if ($regValues.Length -gt 0) {
                $wuauservStatus = $((Get-Service -Name 'wuauserv').Status)
                if ($wuauservStatus -eq 'Running') {
                    Stop-Service -Name 'wuauserv' -Force
                }
                $wuauservStartType = $((Get-Service -Name 'wuauserv').StartType)
                if ($wuauservStartType -eq 'Disabled') {
                    Set-Service -Name 'wuauserv' -StartupType 'Manual'
                }
                Remove-Item -Path "Registry::$regRoot\$regPath" -Recurse -Force
                Start-Service -Name 'wuauserv'
                if (Test-Path -Path $($regRoot + ':\' + $regPath)) {
                    Write-Error -Message 'Windows Update (WSUS) policy settings reset failed.' -Category 'SyntaxError' -ErrorId 'C001'
                    exit 1
                }
                else {
                    [string]$elapsedTime = ('{0:00.000}' -f ((Get-Date).ToUniversalTime() - $scriptStartTime).TotalSeconds) -replace ',', '.'
                    Write-Output -InputObject "[$elapsedTime] Windows Update (WSUS) policy settings reset successful."
                    exit 0
                }
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
