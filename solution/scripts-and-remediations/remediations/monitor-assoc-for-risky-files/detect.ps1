#requires -Version 5.1
<#
.SYNOPSIS
    Monitor Windows default action for list of potentially Malicious file types.
.DESCRIPTION
    Monitor Windows default action for list of potentially Malicious file types.
    When looking at file names in Explorer, be aware Windows might hide the file extension for known file types.
    Please notice, changing default bahaviour to EDIT will cause scripts to open on e.g. Notepad if not properly prefixed with target executable.
    Potentially dangerous extensions: JSEFile, JSFile, regfile, VBEFile, VBSFile, WSFFile, batfile, cmdfile, htafile
.PARAMETER fileTypes
    Choose file types to monitor. Default is JSEFile, JSFile, regfile, VBEFile, VBSFile, WSFFile, batfile, cmdfile, htafile.
.PARAMETER fileAction
    Choose file action to monitor. Default is edit.
.EXAMPLE
    .\detect.ps1
.NOTES
    version: 1.0.0.0
    date: December 21, 2020
    license: MIT License
.LINK
    [Jesper on Bluesky](https://bsky.app/profile/dotjesper.bsky.social "Jesper on Bluesky")
    [Jesper on GitHub](https://github.com/dotjesper/ "Jesper on GitHub")
#>
[CmdletBinding()]
param (
    #variables
    [array]$fileTypes = @('JSEFile', 'JSFile', 'regfile', 'VBEFile', 'VBSFile', 'WSFFile', 'batfile', 'cmdfile', 'htafile'),
    [string]$fileAction = "edit"
)
begin {
    #variables :: conditions
    [bool]$runScriptIn64bitPowerShell = $false
    #variables :: environment
    [string]$regRoot = "HKLM"
    [string]$regPath = "SOFTWARE\Classes"
    [int]$scriptCounter = 0
    [string]$scriptOutput = "Output"
}
process {
    #region check conditions
    if ($runScriptIn64bitPowerShell -eq $true -and $([System.Environment]::Is64BitProcess) -eq $false) {
        Write-Error -Message "Windows PowerShell 64-bit is requered." -Category "ResourceUnavailable" -ErrorId "B001"
        exit 1
    }
    #endregion
    try {
        foreach ($fileType in $fileTypes) {
            if (Test-Path -LiteralPath $($regRoot + ":\" + $regPath + "\" + $fileType)) {
                [string]$regValue = (Get-ItemProperty -LiteralPath "Registry::$regRoot\$regPath\$fileType\Shell")."(default)"

                if ($regValue -eq $fileAction) {
                    $scriptOutput = "$scriptOutput $fileType;$regValue"
                }
                elseif ([string]::IsNullOrEmpty($regValue)) {
                    $regValue = "null"
                    $scriptOutput = "$scriptOutput $fileType;$regValue"
                    [int]$scriptCounter = $scriptCounter + 1
                }
                else {
                    $scriptOutput = "$scriptOutput $fileType;$regValue"
                    [int]$scriptCounter = $scriptCounter + 1
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
}
end {
    if ($scriptCounter -eq 0) {
        Write-Output -InputObject "File extension properly configured ($scriptOutput)"
        exit 0
    }
    else {
        Write-Output -InputObject "$scriptCounter file extension misconfigured ($scriptOutput)"
        exit 1
    }
}