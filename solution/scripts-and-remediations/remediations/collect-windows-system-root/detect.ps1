#requires -Version 5.1
<#
.SYNOPSIS
    Collect system root
.DESCRIPTION
    Collect %SystemRoot%, fails if different from C:\Windows
.PARAMETER computerMaximumUptimeThreshold
    Choose System Root. Default is C:\WINDOWS.
.EXAMPLE
    .\detect.ps1
.NOTES
    version: 1.0.0.0
    date: November 30, 2021
    license: MIT License
.LINK
    [Jesper on Bluesky](https://bsky.app/profile/dotjesper.bsky.social "Jesper on Bluesky")
    [Jesper on GitHub](https://github.com/dotjesper/ "Jesper on GitHub")
#>
[CmdletBinding()]
param (
    #variables
    [Parameter (Mandatory = $False, HelpMessage = "Choose System Root [C:\WINDOWS]") ]
    [string]$SystemRoot = "C:\WINDOWS"
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
        if ("$($env:SystemRoot)" -eq "$SystemRoot") {
            Write-Output -InputObject "SystemRoot: $($env:SystemRoot) [0]"
            exit 0
        }
        else {
            Write-Output -InputObject "SystemRoot: $($env:SystemRoot) [1]"
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
