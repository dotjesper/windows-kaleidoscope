<#
.SYNOPSIS
    Monitor "Unquoted Service Path Enumeration" vulnerability in Services and Uninstall strings.

.DESCRIPTION
    When a service is created whose executable path contains spaces and is not enclosed within quotes, leads to a vulnerability known as Unquoted Service Path
    which allows a user to gain SYSTEM privileges (only if the vulnerable service is running with SYSTEM privilege level which most of the time it is).
    In Windows, if the service is not enclosed within quotes and is having spaces, it would handle the space as a break and pass the rest of the service path as an argument.

.PARAMETER servicePathEnumeration
    Enable or disable service path enumeration.

.PARAMETER uninstallStringEnumeration
    Enable or disable uninstall string enumeration.

.PARAMETER resolveEnvironmentVariables
    Enable or disable environment variable resolution.

.EXAMPLE
    .\detect.ps1

    Monitor "Unquoted Service Path Enumeration" vulnerability in Services and Uninstall strings with default settings.

.NOTES
    version: 1.2.0
    date: December 6, 2021
    license: MIT License

.LINK
    https://github.com/dotjesper/windows-kaleidoscope
#>

#requires -Version 5.1
#requires -RunAsAdministrator

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false, HelpMessage = 'Enable or disable service path enumeration.')]
    [bool]$servicePathEnumeration = $true,

    [Parameter(Mandatory = $false, HelpMessage = 'Enable or disable uninstall string enumeration.')]
    [bool]$uninstallStringEnumeration = $true,

    [Parameter(Mandatory = $false, HelpMessage = 'Enable or disable environment variable resolution.')]
    [bool]$resolveEnvironmentVariables = $true
)

begin {
    Set-StrictMode -Version Latest

    # variables :: Conditions
    [bool]$runScriptIn64bitPowerShell = $true

    # variables :: Environment
    [array]$enumerationItems = @()
    [int]$vulnerabilityCounter = 0
    [datetime]$scriptStartTime = (Get-Date).ToUniversalTime()

    #variables :: logfile
    [string]$logName = 'UnquotedServicePaths.log'
    [string]$logFilePath = "$($Env:ProgramData)\Microsoft\IntuneManagementExtension\Logs\$logName"

    #region :: functions
    function Write-Log {
        <#
        .SYNOPSIS
            Write log entry to log file.

        .DESCRIPTION
            Write log entry to log file, with defined message and component.

        .PARAMETER Message
            The message to be logged.

        .PARAMETER Component
            The component associated with the log entry.

        .EXAMPLE
            Write-Log -Message "This is a log message." -Component "Example Component"
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory = $true, HelpMessage = 'The message to be logged.')]
            [string]$Message,

            [Parameter(Mandatory = $false, HelpMessage = 'The component associated with the log entry.')]
            [string]$Component
        )
        begin {
            [string]$fdate = $(Get-Date -Format 'M-dd-yyyy')
            [string]$ftime = $(Get-Date -Format 'HH:mm:ss.fffffff')
        }
        process {
            try {
                if (-not (Test-Path -Path "$(Split-Path -Path $logFilePath)")) {
                    $null = New-Item -ItemType 'Directory' -Path "$(Split-Path -Path $logFilePath)"
                }
                $null = Add-Content -Path $logFilePath -Value "<![LOG[[$logName] $($Message)]LOG]!><time=""$($ftime)"" date=""$($fdate)"" component=""$Component"" context="""" type="""" thread="""" file="""">"
            }
            catch {
                throw $_.Exception.Message
                exit 1
            }
            finally {}
        }
        end {}
    }
}
process {
    #region :: Check conditions
    if ($runScriptIn64bitPowerShell -eq $true -and $([System.Environment]::Is64BitProcess) -eq $false) {
        Write-Error -Message 'Windows PowerShell 64-bit is required.' -Category 'ResourceUnavailable' -ErrorId 'B001'
        exit 1
    }
    #endregion

    #region :: Main logic
    try {
        Write-Log -Message 'UNQUOTED SERVICE PATH ENUMERATION.' -Component 'detection script'
        # read service Image Paths
        if ($servicePathEnumeration) {
            Write-Log -Message 'Service Path Enumeration enabled' -Component 'detection script'
            $enumerationItems += @{'Path' = 'HKLM:\SYSTEM\CurrentControlSet\Services' ; 'Description' = 'Services' ; 'ParamName' = 'ImagePath' }
        }
        # read Uninstall Strings
        if ($uninstallStringEnumeration) {
            Write-Log -Message 'Uninstall String Enumeration enabled' -Component 'detection script'
            $enumerationItems += @{'Path' = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall' ; 'Description' = 'Uninstall string' ; 'ParamName' = 'UninstallString' }
            #if OS x64 - adding paths for x86 programs
            if ([System.Environment]::Is64BitOperatingSystem) {
                $enumerationItems += @{'Path' = 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall' ; 'Description' = 'Uninstall string [WOW6432Node]' ; 'ParamName' = 'UninstallString' }
            }
        }
        # enumerate items
        foreach ($enumerationItem in $enumerationItems) {
            Write-Log -Message "Processing $($enumerationItem.Description) vulnerability, reading [$($enumerationItem.ParamName)] values." -Component 'detection script - item enumeration'
            [array]$enumerationItemPaths = Get-ChildItem $enumerationItem.Path -ErrorAction SilentlyContinue
            Write-Log -Message "Found $($enumerationItemPaths.Count) [$($enumerationItem.ParamName)] values." -Component 'detection script - item enumeration'
            foreach ($enumerationItemPath in $enumerationItemPaths) {
                [string]$RegistryPath = $enumerationItemPath.Name -replace 'HKEY_LOCAL_MACHINE', 'HKLM:' -replace '([\[\]])', '`$1'
                [array]$OriginalPath = (Get-ItemProperty "$RegistryPath" -ErrorAction SilentlyContinue)

                # Skip if the target property does not exist on this registry key
                [string]$paramName = $OriginalPath | Select-Object -ExpandProperty $enumerationItem.ParamName -ErrorAction SilentlyContinue
                if (-not $paramName) {
                    continue
                }

                # resolve environment variables
                if ($resolveEnvironmentVariables) {
                    if ($($OriginalPath.$($enumerationItem.ParamName)) -match '%(?''environmentVarName''[^%]+)%') {
                        [string]$environmentVarName = $Matches['environmentVarName']
                        [string]$environmentVarValue = (Get-ChildItem env: | Where-Object { $_.Name -eq $environmentVarName }).value
                        [string]$paramName = $OriginalPath.$($enumerationItem.ParamName) -replace "%$environmentVarName%", $environmentVarValue
                        Clear-Variable Matches
                    }
                }

                # find vulnerable strings
                if (($paramName -like '* *') -and ($paramName -notlike '"*"' ) -and ($paramName -like '*.exe*')) {
                    #skip msiexec.exe in uninstall strings
                    if ((($enumerationItem.ParamName -eq 'UninstallString') -and ($paramName -notmatch 'MsiExec(\.exe)?') -and ($paramName -match '^((\w\:)|(%[-\w_()]+%))\\')) -or ($enumerationItem.ParamName -eq 'ImagePath')) {
                        [array]$splitResult = $paramName -split '\.exe '
                        [string]$newPath = $splitResult[0]
                        [string]$key = if ($splitResult.Count -gt 1) { $splitResult[1] } else { '' }
                        [string]$trigger = if ($splitResult.Count -gt 2) { $splitResult[2] } else { '' }

                        # get strings with vulnerability with key
                        if ([string]::IsNullOrEmpty($trigger)) {
                            if (($newPath -like '* *') -and ($newPath -notlike '*.exe')) {
                                [string]$newValue = """$newPath.exe"" $key"
                            }

                            # get strings with vulnerability without key
                            elseif (($newPath -like '* *') -and ($newPath -like '*.exe')) {
                                [string]$newValue = """$newPath"""
                            }
                            else {
                                [string]$newValue = ''
                            }

                            # log vulnerable strings with recommended change
                            if ((-not ([string]::IsNullOrEmpty($newValue))) -and ($newPath -like '* *')) {
                                Write-Log -Message "Vulnerable string found: $paramName [$($OriginalPath.$($enumerationItem.ParamName))]" -Component 'detection script - vulnerability check'
                                Write-Log -Message "Recommended change: $($OriginalPath.$($enumerationItem.ParamName)) -> $newValue" -Component 'detection script - vulnerability check'
                                Write-Log -Message "Source Key: $RegistryPath [$($enumerationItem.ParamName)]" -Component 'detection script - vulnerability check'
                                [int]$vulnerabilityCounter = $vulnerabilityCounter + 1
                            }
                        }
                    }
                }
                #endregion
            }
        }
        #endregion

        #region :: setting exit value
        Write-Log -Message 'Cleaning up...' -Component 'detection script - clean-up'
        if ($vulnerabilityCounter -eq 0) {
            Write-Log -Message 'No vulnerabilities found.' -Component 'detection script - clean-up'
            [string]$elapsedTime = ('{0:00.000}' -f ((Get-Date).ToUniversalTime() - $scriptStartTime).TotalSeconds) -replace ',', '.'
            Write-Output -InputObject "[$elapsedTime] No vulnerabilities found, see [$($Env:COMPUTERNAME)] $($logFilePath) for further information."
            exit 0
        }
        else {
            Write-Log -Message "Found $vulnerabilityCounter vulnerabilities." -Component 'detection script - clean-up'
            [string]$elapsedTime = ('{0:00.000}' -f ((Get-Date).ToUniversalTime() - $scriptStartTime).TotalSeconds) -replace ',', '.'
            Write-Output -InputObject "[$elapsedTime] Found $vulnerabilityCounter vulnerabilities, see [$($Env:COMPUTERNAME)] $($logFilePath) for further information."
            exit 1
        }
        #endregion
    }
    catch {
        $errMsg = $_.Exception.Message
        Write-Error -Message $errMsg -Category 'SyntaxError' -ErrorId 'C001'
        exit 1
    }
    finally {}
    #endregion
}
end {}
