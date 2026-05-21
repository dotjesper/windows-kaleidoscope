<#
.SYNOPSIS
    Monitor PowerShell Execution Policy

.DESCRIPTION
    Monitor whether the PowerShell Execution Policy is configured to the required value (Restricted) for
    both 64-bit and 32-bit PowerShell environments. The execution policy is read directly from the registry
    at the machine scope. A non-compliant state triggers remediation.

.EXAMPLE
    .\detect.ps1

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
        [bool]$isCompliant = $true

        # Read 64-bit PowerShell Execution Policy from registry
        [string]$executionPolicy64 = 'Undefined'
        if (Test-Path -Path $($regRoot + ':\' + $regPath64)) {
            $regResult64 = Get-ItemProperty -Path "Registry::$regRoot\$regPath64" -Name 'ExecutionPolicy' -ErrorAction SilentlyContinue
            if ($null -ne $regResult64) {
                [string]$executionPolicy64 = $regResult64.ExecutionPolicy
            }
        }

        # Read 32-bit PowerShell Execution Policy from registry
        [string]$executionPolicy32 = 'Undefined'
        if (Test-Path -Path $($regRoot + ':\' + $regPath32)) {
            $regResult32 = Get-ItemProperty -Path "Registry::$regRoot\$regPath32" -Name 'ExecutionPolicy' -ErrorAction SilentlyContinue
            if ($null -ne $regResult32) {
                [string]$executionPolicy32 = $regResult32.ExecutionPolicy
            }
        }

        # Evaluate compliance
        if ($executionPolicy64 -ne $requiredExecutionPolicy) {
            [bool]$isCompliant = $false
        }
        if ($executionPolicy32 -ne $requiredExecutionPolicy) {
            [bool]$isCompliant = $false
        }

        [string]$elapsedTime = ('{0:00.000}' -f ((Get-Date).ToUniversalTime() - $scriptStartTime).TotalSeconds) -replace ',', '.'
        if ($isCompliant -eq $true) {
            Write-Output -InputObject "[$elapsedTime] PowerShell Execution Policy compliant (64-bit: $executionPolicy64, 32-bit: $executionPolicy32)"
            exit 0
        }
        else {
            Write-Output -InputObject "[$elapsedTime] PowerShell Execution Policy non-compliant (64-bit: $executionPolicy64, 32-bit: $executionPolicy32)"
            exit 1
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
