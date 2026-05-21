<#
.SYNOPSIS
    Monitor Windows default action for list of potentially malicious file types.

.DESCRIPTION
    Monitor Windows default action for list of potentially malicious file types.
    When looking at file names in Explorer, be aware Windows might hide the file extension for known file types.
    Please notice, changing default behaviour to EDIT will cause scripts to open on e.g. Notepad if not properly prefixed with target executable.
    Potentially dangerous extensions: JSEFile, JSFile, regfile, VBEFile, VBSFile, WSFFile, batfile, cmdfile, htafile

.EXAMPLE
    .\remediate.ps1

.NOTES
    version: 1.1.0
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
    [string]$regRoot = "HKLM"
    [string]$regPath = "SOFTWARE\Classes"
    [array]$fileTypes = @('JSEFile', 'JSFile', 'regfile', 'VBEFile', 'VBSFile', 'WSFFile', 'batfile', 'cmdfile', 'htafile')
    [string]$fileAction = "edit"
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
        foreach ($fileType in $fileTypes) {
            if (Test-Path -LiteralPath $($regRoot + ":\" + $regPath + "\" + $fileType)) {
                [string]$regValue = (Get-ItemProperty -LiteralPath "Registry::$regRoot\$regPath\$fileType\Shell")."(default)"
                if ($regValue -eq $fileAction) {
                    continue
                }
                elseif ($null -eq $regValue -or $regValue -eq '') {
                    $null = New-ItemProperty -LiteralPath "Registry::$regRoot\$regPath\$fileType\Shell" -Name "(default)" -Value $fileAction -PropertyType "String" -Force
                }
                else {
                    $null = New-ItemProperty -LiteralPath "Registry::$regRoot\$regPath\$fileType\Shell" -Name "(default)" -Value $fileAction -PropertyType "String" -Force
                }
            }
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
end {
    exit 0
}
