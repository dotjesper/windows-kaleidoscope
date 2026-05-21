<#
.SYNOPSIS
    Collect system root

.DESCRIPTION
    Collect %SystemRoot%, fails if different from C:\Windows

.PARAMETER SystemRoot
    Choose System Root. Default is C:\WINDOWS.

.EXAMPLE
    .\detect.ps1

    Collects the system root and compares it with the default value of C:\WINDOWS. If the system root is different, the script will report 'failed'.

.NOTES
    version: 1.0.0
    date: November 30, 2021
    license: MIT License

.LINK
    https://github.com/dotjesper/windows-kaleidoscope
#>

#requires -Version 5.1

[CmdletBinding()]
param (
    [Parameter (Mandatory = $False, HelpMessage = "Choose System Root [C:\WINDOWS]") ]
    [string]$SystemRoot = "C:\WINDOWS"
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
        Write-Error -Message "Windows PowerShell 64-bit is required." -Category "ResourceUnavailable" -ErrorId "B001"
        exit 1
    }
    #endregion

    #region :: Main logic
    try {
        # Get the system root from the environment variable and compare it with the specified value
        [string]$elapsedTime = ('{0:00.000}' -f ((Get-Date).ToUniversalTime() - $scriptStartTime).TotalSeconds) -replace ',', '.'
        if ("$($env:SystemRoot)" -eq "$SystemRoot") {
            Write-Output -InputObject "[$elapsedTime] SystemRoot: $($env:SystemRoot) [0]"
            exit 0
        }
        else {
            Write-Output -InputObject "[$elapsedTime] SystemRoot: $($env:SystemRoot) [1]"
            exit 1
        }
    }
    catch {
        $errMsg = $_.Exception.Message
        Write-Error -Message $errMsg -Category "SyntaxError" -ErrorId "C001"
        exit 1
    }
    finally {}
    #endregion
}
end {}
