<#
.SYNOPSIS
    Remediate PowerShell Execution Policy

.DESCRIPTION
    Remediate the PowerShell Execution Policy by setting it to the required value (Restricted) for both
    64-bit and 32-bit PowerShell environments. The execution policy is written directly to the registry
    at the machine scope.

.EXAMPLE
    .\remediate.ps1

    Run the script with default parameters.

.NOTES
    version: 2.0.0
    date: April 10, 2026
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
    [bool]$runScriptIn64bitPowerShell = $false

    # variables :: Environment
    [string]$requiredExecutionPolicy = 'Restricted'
    [string]$regRoot = 'HKLM'
    [string]$regPath64 = 'SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell'
    [string]$regPath32 = 'SOFTWARE\WOW6432Node\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell'
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
        # Remediate 64-bit PowerShell Execution Policy
        if (Test-Path -Path $($regRoot + ':\' + $regPath64)) {
            $regResult64 = Get-ItemProperty -Path "Registry::$regRoot\$regPath64" -Name 'ExecutionPolicy' -ErrorAction SilentlyContinue
            [string]$currentPolicy64 = if ($null -ne $regResult64) { $regResult64.ExecutionPolicy } else { 'Undefined' }
            if ($currentPolicy64 -ne $requiredExecutionPolicy) {
                $null = New-ItemProperty -Path "Registry::$regRoot\$regPath64" -Name 'ExecutionPolicy' -Value $requiredExecutionPolicy -PropertyType 'String' -Force
            }
        }

        # Remediate 32-bit PowerShell Execution Policy
        if (Test-Path -Path $($regRoot + ':\' + $regPath32)) {
            $regResult32 = Get-ItemProperty -Path "Registry::$regRoot\$regPath32" -Name 'ExecutionPolicy' -ErrorAction SilentlyContinue
            [string]$currentPolicy32 = if ($null -ne $regResult32) { $regResult32.ExecutionPolicy } else { 'Undefined' }
            if ($currentPolicy32 -ne $requiredExecutionPolicy) {
                $null = New-ItemProperty -Path "Registry::$regRoot\$regPath32" -Name 'ExecutionPolicy' -Value $requiredExecutionPolicy -PropertyType 'String' -Force
            }
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
