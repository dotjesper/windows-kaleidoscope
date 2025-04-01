#requires -Version 5.1
<#
.SYNOPSIS
    Check Powershell Execution Policy
.DESCRIPTION
    Check Powershell Execution Policy, validating Powershell Execution Policy is configured to Restricted
    Default: Restricted for Windows clients or RemoteSigned for Windows servers.
.PARAMETER requiredExecutionPolicy

.EXAMPLE
    .\remediate.ps1
.NOTES
    version: 1.2.0.2
    date: April 15, 2021
    license: MIT License
.LINK
    [Jesper on Bluesky](https://bsky.app/profile/dotjesper.bsky.social "Jesper on Bluesky")
    [Jesper on GitHub](https://github.com/dotjesper/ "Jesper on GitHub")
#>
[CmdletBinding()]
param (
    #variables
    [Parameter (Mandatory = $False, HelpMessage = "Choose required execution policy") ]
    [ValidateSet("AllSigned","Bypass","Default","RemoteSigned","Restricted","Undefined","Unrestricted")]
    [string]$requiredExecutionPolicy = "Restricted"
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
    try {
        if ([Environment]::Is64BitOperatingSystem) {
            #Windows PowerShell (x64) Execution Policy
            #[string]$64BitExecutionPolicy = Invoke-Expression -Command "$($env:SystemRoot)\System32\WindowsPowerShell\v1.0\powershell.exe -Command 'Get-ExecutionPolicy -Scope 'LocalMachine''"
            #Windows PowerShell (x86) Execution Policy
            #[string]$32BitExecutionPolicy = Invoke-Expression -Command "$($env:SystemRoot)\Syswow64\WindowsPowerShell\v1.0\powershell.exe -Command 'Get-ExecutionPolicy -Scope 'LocalMachine''"
            #
            if (($64BitExecutionPolicy -eq $requiredExecutionPolicy) -and ($32BitExecutionPolicy -eq $requiredExecutionPolicy)) {
                Write-Output -InputObject "Powershell Execution Policy $requiredExecutionPolicy (64-bit $64BitExecutionPolicy, 32-bit $32BitExecutionPolicy)"
                exit 0
            }
            else {
                Write-Output -InputObject "Powershell Execution Policy not $requiredExecutionPolicy (64-bit $64BitExecutionPolicy, 32-bit $32BitExecutionPolicy)"
                #$null = Invoke-Expression -Command "$($env:SystemRoot)\System32\WindowsPowerShell\v1.0\powershell.exe -Command 'Set-ExecutionPolicy -ExecutionPolicy $requiredExecutionPolicy -Scope 'LocalMachine' -Force'"
                #$null = Invoke-Expression -Command "$($env:SystemRoot)\Syswow64\WindowsPowerShell\v1.0\powershell.exe -Command 'Set-ExecutionPolicy -ExecutionPolicy $requiredExecutionPolicy -Scope 'LocalMachine' -Force'"
                exit 0
            }
        }
        else {
            #Windows PowerShell (x86) Execution Policy
            #[string]$32BitExecutionPolicy = Invoke-Expression -Command "$($env:SystemRoot)\System32\WindowsPowerShell\v1.0\powershell.exe -Command 'Get-ExecutionPolicy -Scope 'LocalMachine''"
            #
            if ([string]$32BitExecutionPolicy -eq $requiredExecutionPolicy) {
                Write-Output -InputObject "Powershell Execution Policy $requiredExecutionPolicy (32-bit $32BitExecutionPolicy)"
                exit 0
            }
            else {
                Write-Output -InputObject "Powershell Execution Policy not $requiredExecutionPolicy (32-bit $32BitExecutionPolicy)"
                #$null = Invoke-Expression -Command "$($env:SystemRoot)\System32\WindowsPowerShell\v1.0\powershell.exe -Command 'Set-ExecutionPolicy -ExecutionPolicy $requiredExecutionPolicy -Scope 'LocalMachine' -Force'"
                exit 0
            }
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
