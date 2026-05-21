<#
.SYNOPSIS
    Hello Intune sample script for exploring platform script functionality.

.DESCRIPTION
    Sample platform script demonstrating key patterns for Microsoft Intune platform scripts,
    including CMTrace-compatible logging, registry operations, CimInstance queries, file system
    checks, condition flags, and standardized error handling.

.PARAMETER doFail
    If set to $true, the script will exit with code 1 to simulate a failed execution.

.EXAMPLE
    .\helloIntune.ps1

    Run the script with default parameters.

.EXAMPLE
    .\helloIntune.ps1 -doFail $true

    Run the script and simulate a failure.

.NOTES
    version: 1.7.0
    date: April 10, 2026
    license: MIT License

.LINK
    https://github.com/dotjesper/windows-kaleidoscope
#>

#requires -Version 5.1
#requires -RunAsAdministrator

[CmdletBinding()]
param (
    [Parameter (Mandatory = $False, HelpMessage = 'Choose to fail the script') ]
    [bool]$doFail = $false
)
begin {
    Set-StrictMode -Version Latest

    # variables :: Conditions
    [bool]$runScriptIn64bitPowerShell = $false
    [bool]$runScriptAsUser = $false

    # variables :: Environment
    [string]$logFilePath = "$($Env:ProgramData)\Microsoft\IntuneManagementExtension\Logs\helloIntune.log"
    [string]$logPackageName = 'helloIntune'

    # Start time for runtime calculation in log summary
    [datetime]$script:startTime = (Get-Date).ToUniversalTime()

    #region :: Check conditions
    if ($runScriptIn64bitPowerShell -eq $true -and $([System.Environment]::Is64BitProcess) -eq $false) {
        Write-Error -Message 'Windows PowerShell 64-bit is required.' -Category 'ResourceUnavailable' -ErrorId 'B001'
        exit 1
    }

    # Check if script must be run in user context but is currently running under SYSTEM account
    if ($runScriptAsUser -eq $true -and $env:USERNAME -eq 'SYSTEM') {
        Write-Error -Message 'Script must be run in user context.' -Category 'ResourceUnavailable' -ErrorId 'B002'
        exit 1
    }
    #endregion

    #region :: Functions
    function Write-Log {
        <#
        .SYNOPSIS
            Write formatted log entries to a CMTrace/Intune-compatible log file.

        .DESCRIPTION
            Writes log entries with CMTrace and Microsoft Intune Management Extension compatible formatting.
            Supports different log levels (Info, Warning, Error) and component-based logging.

        .PARAMETER Message
            The log message to write.

        .PARAMETER Component
            The component or section of the script generating the log entry.

        .PARAMETER Severity
            The severity level of the log entry:
            1: Information (Default)
            2: Warning
            3: Error
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
            [string]$Message,

            [Parameter(Mandatory = $false)]
            [string]$Component = '',

            [Parameter(Mandatory = $false)]
            [ValidateSet(1, 2, 3)]
            [int]$Severity = 1
        )
        process {
            try {
                [datetime]$timestamp = Get-Date

                # Compute UTC offset in minutes for CMTrace-compatible time field
                [timespan]$utcOffset = $timestamp - $timestamp.ToUniversalTime()
                [int]$utcOffsetMinutes = $utcOffset.TotalMinutes
                [string]$utcOffsetStr = if ($utcOffsetMinutes -ge 0) { "+$utcOffsetMinutes" } else { "$utcOffsetMinutes" }

                # Build CMTrace-compatible log entry
                [string]$logEntry = "<![LOG[[$logPackageName] $Message]LOG]!>" +
                "<time=""$($timestamp.ToString('HH:mm:ss.fffffff'))$utcOffsetStr"" " +
                "date=""$($timestamp.ToString('MM-dd-yyyy'))"" " +
                "component=""$Component"" context="""" " +
                "type=""$Severity"" thread=""$PID"" file="""">"

                # Ensure log directory exists
                if (-not (Test-Path -Path "$(Split-Path -Path $logFilePath)")) {
                    New-Item -ItemType 'Directory' -Path "$(Split-Path -Path $logFilePath)" | Out-Null
                }

                # Write to log file
                Add-Content -Path $logFilePath -Value $logEntry -Encoding 'UTF8' -ErrorAction 'Stop'

                # Output to verbose stream
                Write-Verbose -Message $Message
            }
            catch {
                Write-Warning "Failed to write to log file: $($_.Exception.Message)"
            }
        }
    }
    #endregion
}
process {
    #region :: Environment logging
    try {
        Write-Log -Message "Log file: $($logFilePath)" -Component 'environment'
        Write-Log -Message "Script name: $($MyInvocation.MyCommand.Name)" -Component 'environment'
        Write-Log -Message "Running 64 bit PowerShell: $([System.Environment]::Is64BitProcess)" -Component 'environment'
        if ($($ExecutionContext.SessionState.LanguageMode) -eq 'FullLanguage') {
            Write-Log -Message "Running elevated: $(([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))" -Component 'environment'
            Write-Log -Message "Detected user: $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)" -Component 'environment'
        }
        else {
            Write-Log -Message "Detected user: $($Env:USERNAME)" -Component 'environment'
        }
        Write-Log -Message "Detected language mode: $($ExecutionContext.SessionState.LanguageMode)" -Component 'environment'
        Write-Log -Message "Detected culture name: $((Get-Culture).Name)" -Component 'environment'
        Write-Log -Message "Detected computer name: $env:COMPUTERNAME" -Component 'environment'
        Write-Log -Message "Detected OS version: $($([environment]::OSVersion.Version))" -Component 'environment'
    }
    catch {
        $errMsg = $_.Exception.Message
        Write-Log -Message "ERROR: $errMsg" -Component 'environment' -Severity 3
    }
    finally {}
    #endregion

    #region :: Sample: Registry read operation
    try {
        [string]$regRoot = 'HKLM'
        [string]$regPath = 'SOFTWARE\Microsoft\Windows NT\CurrentVersion'

        Write-Log -Message 'Reading Windows version from registry...' -Component 'registry'

        if (Test-Path -Path $($regRoot + ':\' + $regPath)) {
            [array]$regValues = Get-ItemProperty -Path "Registry::$regRoot\$regPath"
            Write-Log -Message "Product name: $($regValues.ProductName)" -Component 'registry'
            Write-Log -Message "Display version: $($regValues.DisplayVersion)" -Component 'registry'
            Write-Log -Message "Current build: $($regValues.CurrentBuildNumber)" -Component 'registry'
            Write-Log -Message "Windows version: $($regValues.ProductName) ($($regValues.DisplayVersion))" -Component 'registry'
        }
        else {
            Write-Log -Message 'Registry path not found, skipping registry read sample.' -Component 'registry' -Severity 2
        }
    }
    catch {
        $errMsg = $_.Exception.Message
        Write-Error -Message $errMsg -Category 'SyntaxError' -ErrorId 'C001'
        Write-Log -Message "ERROR: $errMsg" -Component 'registry' -Severity 3
        exit 1
    }
    finally {}
    #endregion

    #region :: Sample: OS information via CimInstance
    try {
        Write-Log -Message 'Querying operating system information...' -Component 'osinfo'

        [string]$osCaption = (Get-CimInstance -ClassName 'Win32_OperatingSystem').Caption
        [int]$osSku = (Get-CimInstance -ClassName 'Win32_OperatingSystem').OperatingSystemSKU
        [string]$osArchitecture = (Get-CimInstance -ClassName 'Win32_OperatingSystem').OSArchitecture

        Write-Log -Message "OS caption: $osCaption" -Component 'osinfo'
        Write-Log -Message "OS SKU: $osSku" -Component 'osinfo'
        Write-Log -Message "OS architecture: $osArchitecture" -Component 'osinfo'
        Write-Log -Message "OS: $osCaption (SKU $osSku, $osArchitecture)" -Component 'osinfo'
    }
    catch {
        $errMsg = $_.Exception.Message
        Write-Error -Message $errMsg -Category 'SyntaxError' -ErrorId 'C001'
        Write-Log -Message "ERROR: $errMsg" -Component 'osinfo' -Severity 3
        exit 1
    }
    finally {}
    #endregion

    #region :: Sample: File system check
    try {
        [string]$samplePath = "$($Env:ProgramData)\Microsoft\IntuneManagementExtension\Logs"

        Write-Log -Message "Checking path: $samplePath" -Component 'filesystem'

        if (Test-Path -Path $samplePath) {
            [array]$logFiles = Get-ChildItem -Path $samplePath -Filter '*.log'
            Write-Log -Message "Found $($logFiles.Count) log file(s) in IME Logs folder." -Component 'filesystem'
            Write-Log -Message "IME log files found: $($logFiles.Count)" -Component 'filesystem'
        }
        else {
            Write-Log -Message 'IME Logs folder not found.' -Component 'filesystem' -Severity 2
        }
    }
    catch {
        $errMsg = $_.Exception.Message
        Write-Error -Message $errMsg -Category 'SyntaxError' -ErrorId 'C001'
        Write-Log -Message "ERROR: $errMsg" -Component 'filesystem' -Severity 3
        exit 1
    }
    finally {}
    #endregion

    #region :: Sample: Log severity levels
    Write-Log -Message 'This is an informational message (severity 1).' -Component 'severity'
    Write-Log -Message 'This is a warning message (severity 2).' -Component 'severity' -Severity 2
    Write-Log -Message 'This is an error message (severity 3).' -Component 'severity' -Severity 3
    #endregion
}
end {
    Write-Log -Message "Total execution time: $((New-TimeSpan -Start $script:startTime -End (Get-Date).ToUniversalTime()).ToString('hh\:mm\:ss\.fff'))" -Component 'end'

    #region :: Exit code
    if ($doFail -eq $true) {
        exit 1
    }
    else {
        exit 0
    }
    #endregion
}
