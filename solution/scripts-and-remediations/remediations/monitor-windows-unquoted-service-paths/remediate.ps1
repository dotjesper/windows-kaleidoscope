#requires -Version 5.1
<#
.SYNOPSIS
    Monitor "Unquoted Service Path Enumeration" vulnerability in Services and Uninstall strings.
.DESCRIPTION
    When a service is created whose executable path contains spaces and isn’t enclosed within quotes, leads to a vulnerability known as Unquoted Service Path
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
.NOTES
    version: 1.0.0.0
    date: December 6, 2021
    license: MIT License
.LINK
    [Jesper on Bluesky](https://bsky.app/profile/dotjesper.bsky.social "Jesper on Bluesky")
    [Jesper on GitHub](https://github.com/dotjesper/ "Jesper on GitHub")
#>
[CmdletBinding()]
param (
    #variables
    [Parameter(Mandatory = $false)]
    [bool]$servicePathEnumeration = $true,
    [Parameter(Mandatory = $false)]
    [bool]$uninstallStringEnumeration = $true,
    [Parameter(Mandatory = $false)]
    [bool]$resolveEnvironmentVariables = $true
)
begin {
    #variables :: conditions
    [bool]$runScriptIn64bitPowerShell = $true
    #variables :: environment
    [array]$enumerationItems = @()
    [int]$vulnerabilityCounter = 0
    [int]$remediationCounter = 0
    #variables :: logfile
    [string]$fLogContentpkg = "prUnquotedServicePaths"
    [string]$fLogContentFile = "$($Env:ProgramData)\Microsoft\IntuneManagementExtension\Logs\$fLogContentpkg.log"
    #region :: functions
    function fLogContent () {
        <#
        .SYNOPSIS
        .DESCRIPTION
        .PARAMETER fLogContent
        .PARAMETER fLogContentComponent
        .EXAMPLE
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory = $true)]
            [string]$fLogContent,
            [Parameter(Mandatory = $false)]
            [string]$fLogContentComponent
        )
        begin {
            [string]$fdate = $(Get-Date -Format "M-dd-yyyy")
            [string]$ftime = $(Get-Date -Format "HH:mm:ss.fffffff")
        }
        process {
            try {
                if (!(Test-Path -Path "$(Split-Path -Path $fLogContentFile)")) {
                    $null = New-Item -itemType "Directory" -Path "$(Split-Path -Path $fLogContentFile)"
                }
                $null = Add-Content -Path $fLogContentFile -Value "<![LOG[[$fLogContentpkg] $($fLogContent)]LOG]!><time=""$($ftime)"" date=""$($fdate)"" component=""$fLogContentComponent"" context="""" type="""" thread="""" file="""">"
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
    #region check conditions
    if ($runScriptIn64bitPowerShell -eq $true -and $([System.Environment]::Is64BitProcess) -eq $false) {
        Write-Error -Message "Windows PowerShell 64-bit is requered." -Category "ResourceUnavailable" -ErrorId "B001"
        exit 1
    }
    #endregion
    try {
        #region check conditions
        if ($runScriptIn64bitPowerShell -eq $true -and $([System.Environment]::Is64BitProcess) -eq $false) {
            Write-Output -InputObject "Script must be run using 64-bit PowerShell."
            exit 1
        }
        #endregion
        fLogContent -fLogContent "UNQUOTED SERVICE PATH ENUMERATION." -fLogContentComponent "remediation script"
        #read service Image Paths
        if ($servicePathEnumeration) {
            fLogContent -fLogContent "Service Path Enumeration enabled" -fLogContentComponent "remediation script"
            $enumerationItems += @{"Path" = "HKLM:\SYSTEM\CurrentControlSet\Services" ; "Description" = "Service" ; "ParamName" = "ImagePath" }
        }
        #read Uninstall Strings
        if ($uninstallStringEnumeration) {
            fLogContent -fLogContent "Uninstall String Enumeration enabled" -fLogContentComponent "remediation script"
            $enumerationItems += @{"Path" = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" ; "Description" = "Uninstall string" ; "ParamName" = "UninstallString" }
            #if OS x64 - adding paths for x86 programs
            if ([Environment]::Is64BitOperatingSystem) {
                $enumerationItems += @{"Path" = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" ; "Description" = "Uninstall string [WOW6432Node]" ; "ParamName" = "UninstallString" }
            }
        }
        foreach ($enumerationItem in $enumerationItems) {
            fLogContent -fLogContent "Processing $($enumerationItem.Description) vulnerability, reading [$($enumerationItem.ParamName)] values." -fLogContentComponent "remediation script - item enumeration"
            [array]$enumerationItemPaths = Get-ChildItem $enumerationItem.Path -ErrorAction SilentlyContinue
            fLogContent -fLogContent "Found $($enumerationItemPaths.Count) [$($enumerationItem.ParamName)] values." -fLogContentComponent "remediation script - item enumeration"
            foreach ($enumerationItemPath in $enumerationItemPaths) {
                [string]$RegistryPath = $enumerationItemPath.Name -Replace "HKEY_LOCAL_MACHINE", "HKLM:" -replace "([\[\]])", "`$1"
                [array]$OriginalPath = (Get-ItemProperty "$RegistryPath")
                [string]$paramName = $OriginalPath.$($enumerationItem.ParamName)
                #region :: resolve environment variables
                if ($resolveEnvironmentVariables) {
                    if ($($OriginalPath.$($enumerationItem.ParamName)) -match '%(?''environmentVarName''[^%]+)%') {
                        [string]$environmentVarName = $Matches['environmentVarName']
                        [string]$environmentVarValue = (Get-ChildItem env: | Where-Object { $_.Name -eq $environmentVarName }).value
                        [string]$paramName = $OriginalPath.$($enumerationItem.ParamName) -replace "%$environmentVarName%", $environmentVarValue
                        Clear-Variable Matches
                    }
                }
                #endreion
                #region :: find vulnerable strings
                if (($paramName -like "* *") -and ($paramName -notLike """*""*") -and ($paramName -like "*.exe*")) {
                    #skip msiexec.exe in uninstall strings
                    if ((($enumerationItem.ParamName -eq "UninstallString") -and ($paramName -NotMatch "MsiExec(\.exe)?") -and ($paramName -Match '^((\w\:)|(%[-\w_()]+%))\\')) -or ($enumerationItem.ParamName -eq 'ImagePath')) {
                        [string]$newPath = ($paramName -split ".exe ")[0]
                        [string]$key = ($paramName -split ".exe ")[1]
                        $trigger = ($paramName -split ".exe ")[2]
                        #get strings with vulnerability with key
                        if (-not ($trigger | Measure-Object).count -ge 1) {
                            if (($newPath -like "* *") -and ($newPath -notLike "*.exe")) {
                                [string]$newValue = """$newPath.exe"" $key"
                            }
                            #get strings with vulnerability without key
                            elseif (($newPath -like "* *") -and ($newPath -like "*.exe")) {
                                [string]$newValue = """$newPath"""
                            }
                            else {
                                [string]$newValue = ""
                            }
                            if ((-not ([string]::IsNullOrEmpty($newValue))) -and ($newPath -like "* *")) {
                                fLogContent -fLogContent "Vulnerable string found: $paramName [$($OriginalPath.$($enumerationItem.ParamName))]" -fLogContentComponent "remediation script - vulnerablility check"

                                [int]$vulnerabilityCounter = $vulnerabilityCounter + 1
                                [string]$OriginalPSPathOptimized = $OriginalPath.PSPath -replace "([\[\]])", "`$1"

                                fLogContent -fLogContent "$($enumerationItem.Description.ToUpper()): current value: $($OriginalPath.PSChildName) [$($enumerationItem.ParamName)]: $($OriginalPath.$($enumerationItem.ParamName))" -fLogContentComponent "remediation script - vulnerablility check"
                                fLogContent -fLogContent "$($enumerationItem.Description.ToUpper()): revised value: $($OriginalPath.PSChildName) [$($enumerationItem.ParamName)]: $NewValue" -fLogContentComponent "remediation script - vulnerablility check"

                                Set-ItemProperty -Path $OriginalPSPathOptimized -Name $($enumerationItem.ParamName) -Value $newValue -ErrorAction Stop

                                #region :: validate update
                                [array]$keyTmp = (Get-ItemProperty -Path $OriginalPSPathOptimized)

                                if ($keyTmp.$($enumerationItem.ParamName) -eq $NewValue) {
                                    fLogContent -fLogContent "SUCCESS: Path value was changed for ""$($OriginalPath.PSChildName)"" $($enumerationItem.ParamName)." -fLogContentComponent "remediation script - vulnerablility check"
                                    $remediationCounter = $remediationCounter + 1
                                }
                                else {
                                    fLogContent -fLogContent "ERROR: Something went wrong, path was not changed for ""$($OriginalPath.PSChildName)"" $($enumerationItem.ParamName)." -fLogContentComponent "remediation script - vulnerablility check"
                                }
                                #endregion
                            }
                        }
                    }
                }
                #endregion
            }
        }
        #endregion
        #region :: setting exit value
        fLogContent -fLogContent "Cleaning up..." -fLogContentComponent "Clean-up"
        if ($vulnerabilityCounter -eq 0) {
            fLogContent -fLogContent "No vulnerabilities found." -fLogContentComponent "remediation script - clean-up"
            Write-Output -InputObject "No vulnerabilities found, see [$($Env:COMPUTERNAME)] $($fLogContentFile) for further information."
            exit 0
        }
        else {
            fLogContent -fLogContent "$remediationCounter of $vulnerabilityCounter vulnerable strings remediated." -fLogContentComponent "remediation script - clean-up"
            Write-Output -InputObject "$remediationCounter of $vulnerabilityCounter vulnerable strings remediated, see [$($Env:COMPUTERNAME)] $($fLogContentFile) for further information."
            if ($vulnerabilityCounter -eq $remediationCounter) {
                exit 0
            }
            else {
                exit 1
            }
        }
        #endregion
    }
    catch {
        $errMsg = $_.Exception.Message
        Write-Error -Message $errMsg -Category "SyntaxError" -ErrorId "C001"
        exit 1
    }
    finally {}
}
end {}
