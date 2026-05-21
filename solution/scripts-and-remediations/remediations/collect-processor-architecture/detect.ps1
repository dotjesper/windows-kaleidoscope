<#
.SYNOPSIS
    Collect the processor architecture of the current system.

.DESCRIPTION
    Collect the processor architecture of the current system.
    - The script uses the Win32_Processor class to retrieve the processor architecture.
    - The script returns the processor name, architecture, and the environment variable PROCESSOR_ARCHITECTURE.
    - The script also returns the architecture in a human-readable format.

.EXAMPLE
    .\detect.ps1

    Collect and report the processor architecture of the current device.

.NOTES
    version: 1.0.0
    date: June 12, 2024
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
    [bool]$runScriptIn64bitPowerShell = $false

    # variables :: Environment
    # CPU Architectures :: https://learn.microsoft.com/windows/win32/cimwin32prov/win32-processor#properties
    [hashtable]$cpuArchitectures = @{
        0  = 'x86'
        1  = 'MIPS'
        2  = 'Alpha'
        3  = 'PowerPC'
        5  = 'ARM'
        6  = 'ia64'
        9  = 'x64'
        12 = 'ARM64'
    }
    [datetime]$scriptStartTime = (Get-Date).ToUniversalTime()
}
process {
    #region :: Check conditions
    if ($runScriptIn64bitPowerShell -eq $true -and $([System.Environment]::Is64BitProcess) -eq $false) {
        Write-Error -Message 'Windows PowerShell 64-bit is required.' -Category 'ResourceUnavailable' -ErrorId 'B001'
        exit 1
    }
    #endregion
    try {
        #region :: retrieve CPU architecture
        # Retrieve CPU object and CPU architecture
        $cpuObject = Get-CimInstance -ClassName 'Win32_Processor' -Namespace 'ROOT/CIMV2' -Verbose:$false | Select-Object -Property 'Name', 'Architecture'
        [string]$cpuArchitecture = $cpuArchitectures[[int]$cpuObject.Architecture]

        # Return CPU architecture information
        [string]$elapsedTime = ('{0:00.000}' -f ((Get-Date).ToUniversalTime() - $scriptStartTime).TotalSeconds) -replace ',', '.'
        if ($cpuArchitecture) {
            Write-Output -InputObject "[$elapsedTime] $($cpuObject.Name) | $cpuArchitecture | $($env:PROCESSOR_ARCHITECTURE)"
        }
        else {
            Write-Output -InputObject "[$elapsedTime] $($cpuObject.Name) | Unknown ($($cpuObject.Architecture)) | $($env:PROCESSOR_ARCHITECTURE)"
        }
        exit 0
        #endregion
    }
    catch {
        $errorMessage = $_.Exception.Message
        Write-Error -Message $errorMessage -Category 'SyntaxError' -ErrorId 'C001'
        exit 1
    }
    finally {}
}
end {}
