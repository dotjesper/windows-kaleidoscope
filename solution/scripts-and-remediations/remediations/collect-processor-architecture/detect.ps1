#requires -Version 5.1
<#
.SYNOPSIS
    Collects the processor architecture of the current system.
.DESCRIPTION
    Collects the processor architecture of the current system.
    - The script uses the Win32_Processor class to retrieve the processor architecture.
    - The script returns the processor name, architecture, and the environment variable PROCESSOR_ARCHITECTURE.
    - The script also returns the architecture in a human-readable format.
.EXAMPLE
    .\detect.ps1
.NOTES
    version: 1.0.0.0
    date: June 12, 2024
    license: MIT License
.LINK
    [Jesper on Bluesky](https://bsky.app/profile/dotjesper.bsky.social "Jesper on Bluesky")
    [Jesper on GitHub](https://github.com/dotjesper/ "Jesper on GitHub")
#>
[CmdletBinding()]
param (
    #variables
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
    #region :: retrieve CPU architecture
    try {
        #CPU Architectures :: https://learn.microsoft.com/windows/win32/cimwin32prov/win32-processor#properties
        $CPUArchitectures = @{0="x86";1="MIPS";2="Alpha";3="PowerPC";5="ARM";6="ia64";9="x64";12="ARM64"}
        #retrieve CPU Object and CPU Architecture
        $CPUObject = Get-CimInstance -ClassName "Win32_Processor" -Namespace "ROOT/CIMV2" -Verbose:$false | Select-Object -Property "Name","Architecture"
        $CPUArchitecture = $CPUArchitectures[[int]$CPUObject.Architecture]
        #return CPU Architecture information
        if ($CPUArchitecture) {
            Write-Output -InputObject "$($CPUObject.Name) | $CPUArchitecture | $($env:PROCESSOR_ARCHITECTURE)"
        }
        else {
            Write-Output -InputObject "$($CPUObject.Name) | Unknown ($($CPUObject.Architecture)) | $($env:PROCESSOR_ARCHITECTURE)"
        }
        exit 0
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
