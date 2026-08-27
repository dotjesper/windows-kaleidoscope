<#
.SYNOPSIS
    This script ensures Microsoft Defender Antivirus is updated during Windows Autopilot device preparation.

.DESCRIPTION
    This script forces a Microsoft Defender Antivirus security intelligence update during Out-of-Box
    Experience (OOBE) and device preparation, and logs the versions detected before and after the update.

    The script is intended for scenarios where the built-in mechanisms do not deliver the expected result:
    - The "Oobe EnableRtpAndSignatureUpdate" CSP, or the "Oobe Enable Rtp And Sig Update" Settings Catalog
      policy, is not applied or does not work as expected.
    - Windows 365 Cloud PC provisioning, where the setting is not applied to the Windows 365 Cloud PC, but
      Microsoft Defender Antivirus still needs to be current to produce clean compliance signals.

    MICROSOFT DEFENDER ANTIVIRUS SERVICE VALIDATION:
    - Waits for the Microsoft Defender Antivirus service (WinDefend) to reach a running state
    - Verifies that the Defender PowerShell module is available in the current session

    PRE-UPDATE STATE:
    - Logs product, engine, and service versions
    - Logs antivirus, antispyware, and network inspection signature versions
    - Logs signature age, last update time, running mode, and real-time protection state

    SECURITY INTELLIGENCE UPDATE:
    - Runs Update-MpSignature against the configured update source, with configurable retries
    - Falls back to MpCmdRun.exe when the Defender PowerShell module is unavailable or the cmdlet fails
    - Prefers the current Microsoft Defender Antivirus platform copy of MpCmdRun.exe over the inbox copy

    POST-UPDATE STATE:
    - Logs the same values again after the update completes
    - Compares pre-update and post-update versions and reports whether the signature version changed

.PARAMETER UpdateSource
    Specifies the update source used by Update-MpSignature. Default is MicrosoftUpdateServer.
    Valid values: InternalDefinitionUpdateServer, MicrosoftUpdateServer, MMPC, FileShares

.PARAMETER InitialDelaySeconds
    Number of seconds to wait before the update is attempted. Allows networking and the Microsoft Defender
    Antivirus service to settle during OOBE. Default is 30.

.PARAMETER ServiceTimeoutSeconds
    Maximum number of seconds to wait for the Microsoft Defender Antivirus service to reach a running
    state. Default is 300.

.PARAMETER RetryCount
    Number of update attempts before the update is considered failed. Default is 3.

.PARAMETER RetryDelaySeconds
    Number of seconds to wait between update attempts. Default is 30.

.PARAMETER PostUpdateDelaySeconds
    Number of seconds to wait after the update before the resulting versions are read. Default is 30.

.PARAMETER logFilePath
    Specifies a custom log file path. Alias: logFile.

.EXAMPLE
    .\defender-update.ps1

    Updates Microsoft Defender Antivirus using the default settings and logs to DefenderUpdate.log.

.EXAMPLE
    .\defender-update.ps1 -UpdateSource "MMPC" -RetryCount 5

    Updates Microsoft Defender Antivirus directly from the Microsoft Malware Protection Center, retrying
    up to five times.

.EXAMPLE
    .\defender-update.ps1 -InitialDelaySeconds 0 -PostUpdateDelaySeconds 5 -Verbose

    Runs the update without an initial delay, useful when testing the script interactively.

.NOTES
    version: 1.0.0
    date: August 27, 2026
    license: MIT License
    --------------------------------------------------------------------------------
    LEGAL DISCLAIMER

    This PowerShell script is provided "as-is" without warranty of any kind, either
    expressed or implied, including but not limited to the implied warranties of
    merchantability and fitness for a particular purpose. The author(s) and
    contributor(s) do not warrant that the functions contained in the script will
    meet your requirements or that the operation of the script will be uninterrupted
    or error-free.

    In no event shall the author(s) or contributor(s) be held liable for any direct,
    indirect, incidental, special, exemplary, or consequential damages (including,
    but not limited to, procurement of substitute goods or services; loss of use,
    data, or profits; or business interruption) however caused and on any theory of
    liability, whether in contract, strict liability, or tort (including negligence
    or otherwise) arising in any way out of the use of this script, even if advised
    of the possibility of such damage.

    IMPORTANT: It is strongly recommended to thoroughly test this script in a
    non-production environment before deploying to production systems. The script
    may require modification to fit your specific environment and requirements.
    By using this script, you acknowledge that you have read this disclaimer,
    understand it, and agree to be bound by its terms. You assume all risks and
    responsibilities associated with the use of this script.
    --------------------------------------------------------------------------------

.LINK
    https://github.com/dotjesper/windows-kaleidoscope
#>

#requires -Version 5.1
#requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess)]
param (
    [Parameter(Mandatory = $false, HelpMessage = 'Specify the Microsoft Defender Antivirus update source')]
    [ValidateSet('InternalDefinitionUpdateServer', 'MicrosoftUpdateServer', 'MMPC', 'FileShares')]
    [Alias('source')]
    [string]$UpdateSource = 'MicrosoftUpdateServer',

    [Parameter(Mandatory = $false, HelpMessage = 'Seconds to wait before the update is attempted')]
    [ValidateRange(0, 900)]
    [int]$InitialDelaySeconds = 30,

    [Parameter(Mandatory = $false, HelpMessage = 'Maximum seconds to wait for the Microsoft Defender Antivirus service')]
    [ValidateRange(0, 900)]
    [int]$ServiceTimeoutSeconds = 300,

    [Parameter(Mandatory = $false, HelpMessage = 'Number of update attempts before the update is considered failed')]
    [ValidateRange(1, 10)]
    [int]$RetryCount = 3,

    [Parameter(Mandatory = $false, HelpMessage = 'Seconds to wait between update attempts')]
    [ValidateRange(0, 300)]
    [int]$RetryDelaySeconds = 30,

    [Parameter(Mandatory = $false, HelpMessage = 'Seconds to wait after the update before the resulting versions are read')]
    [ValidateRange(0, 300)]
    [int]$PostUpdateDelaySeconds = 30,

    [Parameter(Mandatory = $false, HelpMessage = 'Enter a custom log file path (e.g., C:\Temp\log.txt)')]
    [Alias('log', 'logFile')]
    [string]$logFilePath = "$($Env:ProgramData)\Microsoft\IntuneManagementExtension\Logs\DefenderUpdate.log"
)
begin {
    Set-StrictMode -Version Latest

    #region :: Environment
    # Start time for runtime calculation in log summary
    [datetime]$script:startTime = (Get-Date).ToUniversalTime()

    # Log package name for CMTrace log entries
    [string]$logPackageName = 'defender-update'

    # Internal variables
    [bool]$defenderModuleAvailable = $false
    $preUpdateStatus = $null
    $postUpdateStatus = $null

    # Summary tracking
    [hashtable]$summary = @{
        ServiceRunning          = $false
        StatusRetrieved         = $false
        UpdateAttempted         = $false
        UpdateSucceeded         = $false
        SignatureVersionChanged = $false
        PreUpdateSignature      = 'Unknown'
        PostUpdateSignature     = 'Unknown'
        Errors                  = [System.Collections.ArrayList]::new()
        Warnings                = [System.Collections.ArrayList]::new()
    }
    #endregion

    #region :: Environment configurations
    [String]$title = 'Microsoft Defender Antivirus update'
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

    function Get-DefenderStatus {
        <#
        .SYNOPSIS
            Retrieve a normalized snapshot of the current Microsoft Defender Antivirus state.

        .DESCRIPTION
            Returns a hashtable holding product, engine, and signature version information. Values that
            cannot be retrieved are returned as 'Unknown', allowing the caller to log a complete set of
            values regardless of the Microsoft Defender Antivirus state.
        #>
        [CmdletBinding()]
        [OutputType([System.Collections.Specialized.OrderedDictionary])]
        param ()
        process {
            $status = [ordered]@{
                Available                     = $false
                AMProductVersion              = 'Unknown'
                AMEngineVersion               = 'Unknown'
                AMServiceVersion              = 'Unknown'
                AntivirusSignatureVersion     = 'Unknown'
                AntispywareSignatureVersion   = 'Unknown'
                NISSignatureVersion           = 'Unknown'
                AntivirusSignatureAge         = 'Unknown'
                AntivirusSignatureLastUpdated = 'Unknown'
                AMRunningMode                 = 'Unknown'
                RealTimeProtectionEnabled     = 'Unknown'
            }
            try {
                $mpStatus = Get-MpComputerStatus -ErrorAction 'Stop'
                [array]$mpProperties = @($mpStatus.PSObject.Properties.Name)
                foreach ($key in @($status.Keys)) {
                    if ($key -eq 'Available') {
                        continue
                    }
                    if ($mpProperties -contains $key) {
                        $value = $mpStatus.$key
                        if ($null -ne $value -and "$value".Length -gt 0) {
                            $status[$key] = "$value"
                        }
                    }
                }
                $status['Available'] = $true
            }
            catch {
                Write-Verbose -Message "Get-MpComputerStatus failed: $($_.Exception.Message)"
            }
            return $status
        }
    }

    function Write-DefenderStatus {
        <#
        .SYNOPSIS
            Write a Microsoft Defender Antivirus status snapshot to the log file.

        .PARAMETER Status
            The status object returned by Get-DefenderStatus.

        .PARAMETER Component
            The component or section of the script generating the log entries.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory = $true)]
            $Status,

            [Parameter(Mandatory = $true)]
            [string]$Component
        )
        process {
            Write-Log -Message "Detected Microsoft Defender product version: $($Status.AMProductVersion)" -Component "$Component"
            Write-Log -Message "Detected Microsoft Defender engine version: $($Status.AMEngineVersion)" -Component "$Component"
            Write-Log -Message "Detected Microsoft Defender service version: $($Status.AMServiceVersion)" -Component "$Component"
            Write-Log -Message "Detected antivirus signature version: $($Status.AntivirusSignatureVersion)" -Component "$Component"
            Write-Log -Message "Detected antispyware signature version: $($Status.AntispywareSignatureVersion)" -Component "$Component"
            Write-Log -Message "Detected network inspection signature version: $($Status.NISSignatureVersion)" -Component "$Component"
            Write-Log -Message "Detected antivirus signature age (days): $($Status.AntivirusSignatureAge)" -Component "$Component"
            Write-Log -Message "Detected antivirus signature last updated: $($Status.AntivirusSignatureLastUpdated)" -Component "$Component"
            Write-Log -Message "Detected Microsoft Defender running mode: $($Status.AMRunningMode)" -Component "$Component"
            Write-Log -Message "Detected real-time protection enabled: $($Status.RealTimeProtectionEnabled)" -Component "$Component"
        }
    }

    function Get-MpCmdRunPath {
        <#
        .SYNOPSIS
            Resolve the path to MpCmdRun.exe.

        .DESCRIPTION
            Returns the path to the current Microsoft Defender Antivirus platform copy of MpCmdRun.exe when
            available, otherwise the inbox copy. Returns an empty string when no copy is found.
        #>
        [CmdletBinding()]
        [OutputType([string])]
        param ()
        process {
            [string]$platformRoot = "$($Env:ProgramData)\Microsoft\Windows Defender\Platform"
            if (Test-Path -Path $platformRoot) {
                $platformFolders = @(Get-ChildItem -Path $platformRoot -Directory -ErrorAction 'SilentlyContinue' | Sort-Object -Property 'Name' -Descending)
                if ($platformFolders.Count -gt 0) {
                    $platformFolder = $platformFolders[0]
                    [string]$platformPath = "$($platformFolder.FullName)\MpCmdRun.exe"
                    if (Test-Path -Path $platformPath) {
                        return $platformPath
                    }
                }
            }
            [string]$inboxPath = "$($Env:ProgramFiles)\Windows Defender\MpCmdRun.exe"
            if (Test-Path -Path $inboxPath) {
                return $inboxPath
            }
            return ''
        }
    }
    #endregion

    #region :: Logfile environment entries
    $region = 'environment'
    try {
        Write-Log -Message "## $title" -Component "$region"
        Write-Log -Message "Log file: $($logFilePath)" -Component "$region"
        Write-Log -Message "Script name: $($MyInvocation.MyCommand.Name)" -Component "$region"
        [string]$argsString = ''
        foreach ($key in $MyInvocation.BoundParameters.keys) {
            switch ($MyInvocation.BoundParameters[$key].GetType().Name) {
                'Boolean' {
                    $argsString += "-$key `$$($MyInvocation.BoundParameters[$key]) "
                }
                'Int32' {
                    $argsString += "-$key $($MyInvocation.BoundParameters[$key]) "
                }
                'String' {
                    $argsString += "-$key `"$($MyInvocation.BoundParameters[$key])`" "
                }
                'SwitchParameter' {
                    if ($MyInvocation.BoundParameters[$key].IsPresent) {
                        $argsString += "-$key "
                    }
                }
                Default {}
            }
        }
        Write-Log -Message "Command line: .\$($myInvocation.myCommand.name) $($argsString)" -Component "$region"
        Write-Log -Message "Running 64 bit PowerShell: $([System.Environment]::Is64BitProcess)" -Component "$region"
        Write-Log -Message "Running elevated: $(([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))" -Component "$region"
        Write-Log -Message "Detected user: $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)" -Component "$region"
        Write-Log -Message "Detected language mode: $($ExecutionContext.SessionState.LanguageMode)" -Component "$region"
        Write-Log -Message "Detected computer name: $env:COMPUTERNAME" -Component "$region"
        Write-Log -Message "Detected OS version: $([environment]::OSVersion.Version)" -Component "$region"
        Write-Log -Message "Update source: $UpdateSource" -Component "$region"
        Write-Log -Message "Retry count: $RetryCount (retry delay: $RetryDelaySeconds seconds)" -Component "$region"
    }
    catch {
        $errMsg = $_.Exception.Message
        Write-Log -Message "ERROR: $errMsg" -Component "$region" -Severity 3
    }
    finally {}
    #endregion
}
process {
    #region :: Initial delay
    # ---------------------------------------------------------------------------
    # Waits before touching Microsoft Defender Antivirus, allowing networking and
    # the Microsoft Defender Antivirus service to settle during OOBE.
    # ---------------------------------------------------------------------------
    $region = 'initial-delay'
    if ($InitialDelaySeconds -gt 0) {
        Write-Log -Message "Waiting $InitialDelaySeconds seconds before starting the update process..." -Component "$region"
        Start-Sleep -Seconds $InitialDelaySeconds
    }
    else {
        Write-Log -Message 'Initial delay is disabled.' -Component "$region"
    }
    #endregion

    #region :: Microsoft Defender Antivirus service validation
    # ---------------------------------------------------------------------------
    # Waits for the Microsoft Defender Antivirus service (WinDefend) to reach a
    # running state and verifies that the Defender PowerShell module is available.
    # ---------------------------------------------------------------------------
    $region = 'defender-service'
    Write-Log -Message 'Starting Microsoft Defender Antivirus service validation...' -Component "$region"
    try {
        [int]$waited = 0
        while ($true) {
            $defenderService = Get-Service -Name 'WinDefend' -ErrorAction 'SilentlyContinue'
            if ($defenderService -and $defenderService.Status -eq 'Running') {
                Write-Log -Message 'Microsoft Defender Antivirus service is running.' -Component "$region"
                $summary.ServiceRunning = $true
                break
            }
            if ($waited -ge $ServiceTimeoutSeconds) {
                break
            }
            Write-Log -Message "Microsoft Defender Antivirus service is not running yet. Waited $waited of $ServiceTimeoutSeconds seconds..." -Component "$region"
            Start-Sleep -Seconds 10
            $waited += 10
        }

        if (-not $summary.ServiceRunning) {
            Write-Log -Message "Warning: Microsoft Defender Antivirus service did not reach a running state within $ServiceTimeoutSeconds seconds." -Component "$region" -Severity 2
            $null = $summary.Warnings.Add('Microsoft Defender Antivirus service did not reach a running state')
        }
    }
    catch {
        $errMsg = $_.Exception.Message
        Write-Log -Message "ERROR: $errMsg" -Component "$region" -Severity 3
        $null = $summary.Errors.Add("Microsoft Defender Antivirus service validation: $errMsg")
    }
    finally {}

    $defenderModuleAvailable = [bool](Get-Command -Name 'Update-MpSignature' -ErrorAction 'SilentlyContinue')
    Write-Log -Message "Detected Defender PowerShell module available: $defenderModuleAvailable" -Component "$region"
    if (-not $defenderModuleAvailable) {
        Write-Log -Message 'Warning: The Defender PowerShell module is unavailable. MpCmdRun.exe is used instead.' -Component "$region" -Severity 2
        $null = $summary.Warnings.Add('Defender PowerShell module unavailable')
    }
    Write-Log -Message 'Microsoft Defender Antivirus service validation completed.' -Component "$region"
    #endregion

    #region :: Pre-update state
    # ---------------------------------------------------------------------------
    # Reads and logs the Microsoft Defender Antivirus product, engine, and
    # signature versions detected before the update is attempted.
    # ---------------------------------------------------------------------------
    $region = 'defender-status: pre-update'
    Write-Log -Message 'Retrieving Microsoft Defender Antivirus status before update...' -Component "$region"
    $preUpdateStatus = Get-DefenderStatus
    if ($preUpdateStatus.Available) {
        Write-Log -Message 'Microsoft Defender Antivirus status retrieved successfully.' -Component "$region"
        Write-DefenderStatus -Status $preUpdateStatus -Component "$region"
        $summary.StatusRetrieved = $true
        $summary.PreUpdateSignature = $preUpdateStatus.AntivirusSignatureVersion
    }
    else {
        Write-Log -Message 'Warning: Microsoft Defender Antivirus status could not be retrieved before the update.' -Component "$region" -Severity 2
        $null = $summary.Warnings.Add('Microsoft Defender Antivirus status unavailable before update')
    }
    #endregion

    #region :: Security intelligence update
    # ---------------------------------------------------------------------------
    # Forces a Microsoft Defender Antivirus security intelligence update using
    # Update-MpSignature, falling back to MpCmdRun.exe when the cmdlet is
    # unavailable or fails.
    # ---------------------------------------------------------------------------
    $region = 'defender-update'
    if ($PSCmdlet.ShouldProcess('Microsoft Defender Antivirus', 'Update security intelligence')) {
        Write-Log -Message 'Starting Microsoft Defender Antivirus update process...' -Component "$region"
        $summary.UpdateAttempted = $true
        for ([int]$attempt = 1; $attempt -le $RetryCount; $attempt++) {
            Write-Log -Message "Update attempt $attempt of $RetryCount..." -Component "$region"
            if ($defenderModuleAvailable) {
                try {
                    Update-MpSignature -UpdateSource $UpdateSource -ErrorAction 'Stop'
                    Write-Log -Message 'Update-MpSignature completed successfully.' -Component "$region"
                    $summary.UpdateSucceeded = $true
                }
                catch {
                    $errMsg = $_.Exception.Message
                    Write-Log -Message "Warning: Update-MpSignature failed: $errMsg" -Component "$region" -Severity 2
                }
                finally {}
            }

            if (-not $summary.UpdateSucceeded) {
                [string]$mpCmdRun = Get-MpCmdRunPath
                if ($mpCmdRun.Length -gt 0) {
                    Write-Log -Message "Falling back to MpCmdRun.exe: $mpCmdRun" -Component "$region"
                    try {
                        $mpCmdRunOutput = & "$mpCmdRun" -SignatureUpdate 2>&1
                        [int]$mpCmdRunExitCode = $LASTEXITCODE
                        Write-Log -Message "MpCmdRun.exe exit code: $mpCmdRunExitCode" -Component "$region"
                        foreach ($line in @($mpCmdRunOutput)) {
                            if ("$line".Trim().Length -gt 0) {
                                Write-Log -Message "MpCmdRun.exe: $("$line".Trim())" -Component "$region"
                            }
                        }
                        if ($mpCmdRunExitCode -eq 0) {
                            $summary.UpdateSucceeded = $true
                        }
                        else {
                            Write-Log -Message "Warning: MpCmdRun.exe returned a non-zero exit code: $mpCmdRunExitCode" -Component "$region" -Severity 2
                        }
                    }
                    catch {
                        $errMsg = $_.Exception.Message
                        Write-Log -Message "Warning: MpCmdRun.exe failed: $errMsg" -Component "$region" -Severity 2
                    }
                    finally {}
                }
                else {
                    Write-Log -Message 'Warning: MpCmdRun.exe was not found on this device.' -Component "$region" -Severity 2
                }
            }

            if ($summary.UpdateSucceeded) {
                break
            }
            if ($attempt -lt $RetryCount -and $RetryDelaySeconds -gt 0) {
                Write-Log -Message "Waiting $RetryDelaySeconds seconds before the next attempt..." -Component "$region"
                Start-Sleep -Seconds $RetryDelaySeconds
            }
        }

        if ($summary.UpdateSucceeded) {
            Write-Log -Message 'Microsoft Defender Antivirus update process completed.' -Component "$region"
        }
        else {
            Write-Log -Message "Error: Microsoft Defender Antivirus update failed after $RetryCount attempts." -Component "$region" -Severity 3
            $null = $summary.Errors.Add("Microsoft Defender Antivirus update failed after $RetryCount attempts")
        }
    }
    else {
        Write-Log -Message 'WhatIf: Would update Microsoft Defender Antivirus security intelligence' -Component "$region"
    }
    #endregion

    #region :: Post-update state
    # ---------------------------------------------------------------------------
    # Reads and logs the Microsoft Defender Antivirus product, engine, and
    # signature versions detected after the update, and compares them with the
    # versions detected before the update.
    # ---------------------------------------------------------------------------
    $region = 'defender-status: post-update'
    if ($summary.UpdateAttempted) {
        if ($PostUpdateDelaySeconds -gt 0) {
            Write-Log -Message "Waiting $PostUpdateDelaySeconds seconds before reading the resulting versions..." -Component "$region"
            Start-Sleep -Seconds $PostUpdateDelaySeconds
        }
        Write-Log -Message 'Retrieving Microsoft Defender Antivirus status after update...' -Component "$region"
        $postUpdateStatus = Get-DefenderStatus
        if ($postUpdateStatus.Available) {
            Write-Log -Message 'Microsoft Defender Antivirus status retrieved successfully.' -Component "$region"
            Write-DefenderStatus -Status $postUpdateStatus -Component "$region"
            $summary.PostUpdateSignature = $postUpdateStatus.AntivirusSignatureVersion

            if ($preUpdateStatus.Available) {
                if ($preUpdateStatus.AntivirusSignatureVersion -ne $postUpdateStatus.AntivirusSignatureVersion) {
                    Write-Log -Message "Antivirus signature version changed: $($preUpdateStatus.AntivirusSignatureVersion) -> $($postUpdateStatus.AntivirusSignatureVersion)" -Component "$region"
                    $summary.SignatureVersionChanged = $true
                }
                else {
                    Write-Log -Message "Antivirus signature version unchanged: $($postUpdateStatus.AntivirusSignatureVersion)" -Component "$region"
                }
                if ($preUpdateStatus.AMProductVersion -ne $postUpdateStatus.AMProductVersion) {
                    Write-Log -Message "Microsoft Defender product version changed: $($preUpdateStatus.AMProductVersion) -> $($postUpdateStatus.AMProductVersion)" -Component "$region"
                }
            }
        }
        else {
            Write-Log -Message 'Warning: Microsoft Defender Antivirus status could not be retrieved after the update.' -Component "$region" -Severity 2
            $null = $summary.Warnings.Add('Microsoft Defender Antivirus status unavailable after update')
        }
    }
    else {
        Write-Log -Message 'No update was attempted. Skipping post-update status.' -Component "$region"
    }
    #endregion
}
end {
    #region :: Summary
    $region = 'summary'
    Write-Log -Message 'Execution Summary' -Component "$region"
    Write-Log -Message "Microsoft Defender Antivirus service running: $($summary.ServiceRunning)" -Component "$region"
    Write-Log -Message "Microsoft Defender Antivirus status retrieved: $($summary.StatusRetrieved)" -Component "$region"
    Write-Log -Message "Update attempted: $($summary.UpdateAttempted)" -Component "$region"
    Write-Log -Message "Update succeeded: $($summary.UpdateSucceeded)" -Component "$region"
    Write-Log -Message "Signature version before update: $($summary.PreUpdateSignature)" -Component "$region"
    Write-Log -Message "Signature version after update: $($summary.PostUpdateSignature)" -Component "$region"
    Write-Log -Message "Signature version changed: $($summary.SignatureVersionChanged)" -Component "$region"

    # Log warnings and errors from the execution summary
    if ($summary.Warnings.Count -gt 0) {
        Write-Log -Message "Warnings ($($summary.Warnings.Count)):" -Component "$region" -Severity 2
        foreach ($warning in $summary.Warnings) {
            Write-Log -Message "$warning" -Component "$region" -Severity 2
        }
    }
    if ($summary.Errors.Count -gt 0) {
        Write-Log -Message "Errors ($($summary.Errors.Count)):" -Component "$region" -Severity 3
        foreach ($errorItem in $summary.Errors) {
            Write-Log -Message "$errorItem" -Component "$region" -Severity 3
        }
    }
    #endregion

    #region :: End of script
    $region = 'end'
    Write-Log -Message "Total execution time: $((New-TimeSpan -Start $script:startTime -End (Get-Date).ToUniversalTime()).ToString('hh\:mm\:ss\.fff'))" -Component "$region"
    Write-Log -Message 'Microsoft Defender Antivirus update script completed.' -Component "$region"

    # Exit code 1 allows the Intune management extension to retry the script on the next check-ins
    if ($summary.Errors.Count -gt 0) {
        exit 1
    }
    else {
        exit 0
    }
    #endregion
}
