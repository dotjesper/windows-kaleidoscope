<#
.SYNOPSIS
    Hello world sample script for exploring remediation.

.DESCRIPTION
    Hello world sample script for exploring remediation functionality.

    Microsoft Intune remediation scripts do not support passing parameters at runtime.
    To change the test or enable DoFail, edit the default values below before uploading to Microsoft Intune.

    The script includes a configurable timeout threshold (default: 30 seconds). If the script
    execution exceeds the threshold, the script exits with code 1 and reports the timeout.

.PARAMETER DoTest
    Select the test to run (1-12):
    1  - Multiple Write-Output lines
    2  - Write-Output with carriage return and new line
    3  - Multiple Write-Information lines
    4  - Write-Information with carriage return and new line
    5  - Multiple Write-Information with carriage return and new line
    6  - Write-Error
    7  - Write-Verbose
    8  - Multiple Write-Verbose
    9  - Write-Output and Write-Error
    10 - Write-Output with environment details
    11 - Write-Output with Write-Log to log file
    12 - Read protected CIM class (Win32_Tpm, requires elevation)

.PARAMETER DoFail
    If specified, the script will exit with 1, causing the detection script to fail.

.EXAMPLE
    .\detect.ps1

    Runs the default test (test 1).

.EXAMPLE
    .\detect.ps1 -DoTest 11

    Runs test 11 (Write-Output with Write-Log to log file).

.EXAMPLE
    .\detect.ps1 -DoTest 12

    Runs test 12 (read protected CIM class Win32_Tpm, requires elevation).

.EXAMPLE
    .\detect.ps1 -DoTest 1 -DoFail $true

    Runs test 1 and forces the detection script to exit with code 1.

.NOTES
    version: 2.1.0
    date: April 8, 2026
    license: MIT License

.LINK
    https://github.com/dotjesper/windows-kaleidoscope
#>

#requires -Version 5.1
#requires -RunAsAdministrator

<#
NOTE: Add '#requires -RunAsAdministrator' if the script requires elevated privileges. Without it, the script can run in user context.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false, HelpMessage = 'Choose test number.')]
    [ValidateRange(1, 12)]
    [int]$DoTest = 1,

    [Parameter(Mandatory = $false, HelpMessage = 'Force the detection script to fail.')]
    [bool]$DoFail = $false
)

begin {
    Set-StrictMode -Version Latest

    # variables :: Conditions
    [bool]$runScriptIn64bitPowerShell = $false

    #variables :: script timeout (seconds, 0 to disable)
    [int]$scriptTimeoutSeconds = 30
    [datetime]$scriptStartTime = (Get-Date).ToUniversalTime()

    #variables :: exit
    [int]$exitCode = 0

    # variables :: Environment
    [string]$logFilePath = "$($Env:ProgramData)\Microsoft\IntuneManagementExtension\Logs\helloWorld-$($DoTest).log"
    [string]$logPackageName = 'helloWorld'

    #region :: functions
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
    Write-Verbose -Message "Content log file: $($logFilePath)"
    #region :: Check conditions
    if ($runScriptIn64bitPowerShell -eq $true -and $([System.Environment]::Is64BitProcess) -eq $false) {
        Write-Error -Message 'Windows PowerShell 64-bit is required.' -Category 'ResourceUnavailable' -ErrorId 'B001'
        exit 1
    }
    #endregion
    try {
        #region :: doTest
        switch ($DoTest) {
            1 {
                # Multiple Write-Output lines
                Write-Output -InputObject "($DoTest) Hello world: Write-Output line 1"
                Write-Output -InputObject "($DoTest) Hello world: Write-Output line 2"
            }
            2 {
                # Write-Output with carriage return and new line (`r`n)
                Write-Output -InputObject "($DoTest) Hello world: Write-Output line 1`r`nHello world: Write-Output line 2"
            }
            3 {
                # Multiple Write-Information lines
                Write-Information -MessageData "($DoTest) Hello world: Write-Information line 1" -InformationAction Continue
                Write-Information -MessageData "($DoTest) Hello world: Write-Information line 2" -InformationAction Continue
            }
            4 {
                # Write-Information with carriage return and new line (`r`n)
                Write-Information -MessageData "($DoTest) Hello world: Write-Information line 1`r`nHello world: Write-Information line 2" -InformationAction Continue
            }
            5 {
                # Multiple Write-Information with carriage return and new line (`r`n)
                Write-Information -MessageData "($DoTest) Hello world: Write-Information line 1" -InformationAction Continue
                Write-Information -MessageData "`r`n($DoTest) Hello world: Write-Information line 2" -InformationAction Continue
            }
            6 {
                # Write-Error
                Write-Error -Message "($DoTest) Error message" -Category 'NotSpecified'
            }
            7 {
                # Write-Verbose
                Write-Verbose -Message "($DoTest) Verbose message"
            }
            8 {
                # Multiple Write-Verbose
                Write-Verbose -Message "($DoTest) Verbose message 1"
                Write-Verbose -Message "($DoTest) Verbose message 2"
            }
            9 {
                # Write-Output and Write-Error
                Write-Output -InputObject "($DoTest) Hello world: Write-Output line 1"
                Write-Error -Message "($DoTest) Error message" -Category 'NotSpecified'
            }
            10 {
                # Write-Output
                Write-Output -InputObject "($DoTest) Hello world | $((Get-Culture).KeyboardLayoutId) | $($ExecutionContext.SessionState.LanguageMode) | $((Get-Culture).Name) | $($Env:USERNAME)"
            }
            11 {
                # Write-Output and add to log file
                Write-Output -InputObject "($DoTest) Hello world: Write-Output line 1"
                #region :: logfile environment entries
                try {
                    Write-Log -Message '## Hello world sample script for exploring remediation scripts' -Component ''
                    Write-Log -Message 'Description: Hello world sample script for exploring remediation functionality' -Component ''
                    Write-Log -Message "Log file: $($logFilePath)" -Component ''
                    Write-Log -Message "Script name: $($MyInvocation.MyCommand.Name)" -Component ''
                    Write-Log -Message "Script folder: $(Split-Path -Parent -Path $MyInvocation.MyCommand.Path)" -Component ''
                    Write-Log -Message "Command line: $($MyInvocation.Line)" -Component ''
                    Write-Log -Message "Run script in 64 bit PowerShell: $runScriptIn64bitPowerShell" -Component ''
                    Write-Log -Message "Running 64 bit PowerShell: $([System.Environment]::Is64BitProcess)" -Component ''
                    if ($($ExecutionContext.SessionState.LanguageMode) -eq 'FullLanguage') {
                        Write-Log -Message "Running elevated: $(([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))" -Component ''
                        Write-Log -Message "Detected user: $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)" -Component ''
                    }
                    else {
                        Write-Log -Message "Detected user: $($Env:USERNAME)" -Component ''
                    }
                    Write-Log -Message "Detected keyboard layout Id: $((Get-Culture).KeyboardLayoutId)" -Component ''
                    Write-Log -Message "Detected language mode: $($ExecutionContext.SessionState.LanguageMode)" -Component ''
                    Write-Log -Message "Detected culture name: $((Get-Culture).Name)" -Component ''
                    Write-Log -Message "Detected OS build: $($([environment]::OSVersion.Version).Build)" -Component ''
                    Write-Log -Message "($DoTest) Hello world: Write-Output line 1." -Component 'helloWorld'
                    Write-Log -Message "($DoTest) Hello world: Write-Output line 2." -Component 'helloWorld'
                    Write-Log -Message "($DoTest) Hello world: Write-Output line 3." -Component 'helloWorld'
                    Write-Log -Message "($DoTest) Hello world: Write-Output line 4." -Component 'helloWorld'
                }
                catch {
                    $errMsg = $_.Exception.Message
                    Write-Error -Message $errMsg
                    Write-Log -Message "ERROR: $errMsg" -Component '' -Severity 3
                    $exitCode = 1
                }
                finally {}
                #endregion
            }
            12 {
                # Read protected CIM class (requires elevation)
                [array]$tpmInfo = Get-CimInstance -Namespace 'Root\CIMv2\Security\MicrosoftTpm' -ClassName 'Win32_Tpm' -ErrorAction Stop
                if ($tpmInfo) {
                    Write-Output -InputObject "($DoTest) TPM present: $($tpmInfo[0].IsActivated_InitialValue) | TPM version: $($tpmInfo[0].SpecVersion)"
                }
                else {
                    Write-Output -InputObject "($DoTest) No TPM detected."
                }
            }
            Default {
                Write-Output -InputObject "($DoTest) No or undefined test selected."
            }
        }
        #endregion
        #region :: exit code
        if ($DoFail) {
            $exitCode = 1
        }
        #endregion
    }
    catch {
        $errMsg = $_.Exception.Message
        Write-Error -Message $errMsg -Category 'SyntaxError' -ErrorId 'C001'
        $exitCode = 1
    }
    finally {}
}
end {
    #region :: script timeout check
    [int]$scriptElapsedSeconds = ((Get-Date).ToUniversalTime() - $scriptStartTime).TotalSeconds
    if ($scriptTimeoutSeconds -gt 0 -and $scriptElapsedSeconds -gt $scriptTimeoutSeconds) {
        $exitCode = 1
        Write-Output -InputObject "Script exceeded timeout threshold of $scriptTimeoutSeconds seconds (elapsed: $scriptElapsedSeconds seconds)."
    }
    #endregion

    #region :: exit
    exit $exitCode
    #endregion
}
