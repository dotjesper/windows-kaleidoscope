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
        fLogContent -fLogContent "UNQUOTED SERVICE PATH ENUMERATION." -fLogContentComponent "detection script"
        #read service Image Paths
        if ($servicePathEnumeration) {
            fLogContent -fLogContent "Service Path Enumeration enabled" -fLogContentComponent "detection script"
            $enumerationItems += @{"Path" = "HKLM:\SYSTEM\CurrentControlSet\Services" ; "Description" = "Services" ; "ParamName" = "ImagePath" }
        }
        #read Uninstall Strings
        if ($uninstallStringEnumeration) {
            fLogContent -fLogContent "Uninstall String Enumeration enabled" -fLogContentComponent "detection script"
            $enumerationItems += @{"Path" = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" ; "Description" = "Uninstall string" ; "ParamName" = "UninstallString" }
            #if OS x64 - adding paths for x86 programs
            if ([Environment]::Is64BitOperatingSystem) {
                $enumerationItems += @{"Path" = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" ; "Description" = "Uninstall string [WOW6432Node]" ; "ParamName" = "UninstallString" }
            }
        }
        foreach ($enumerationItem in $enumerationItems) {
            fLogContent -fLogContent "Processing $($enumerationItem.Description) vulnerability, reading [$($enumerationItem.ParamName)] values." -fLogContentComponent "detection script - item enumeration"
            [array]$enumerationItemPaths = Get-ChildItem $enumerationItem.Path -ErrorAction SilentlyContinue
            fLogContent -fLogContent "Found $($enumerationItemPaths.Count) [$($enumerationItem.ParamName)] values." -fLogContentComponent "detection script - item enumeration"
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
                                fLogContent -fLogContent "Vulnerable string found: $paramName [$($OriginalPath.$($enumerationItem.ParamName))]" -fLogContentComponent "detection script - vulnerablility check"
                                fLogContent -fLogContent "Recomendend change: $($OriginalPath.$($enumerationItem.ParamName)) -> $newValue" -fLogContentComponent "detection script - vulnerablility check"
                                fLogContent -fLogContent "Source Key: $RegistryPath [$($enumerationItem.ParamName)]" -fLogContentComponent "detection script - vulnerablility check"
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
        fLogContent -fLogContent "Cleaning up..." -fLogContentComponent "detection script - Clean-up"
        if ($vulnerabilityCounter -eq 0) {
            fLogContent -fLogContent "No vulnerabilities found." -fLogContentComponent "detection script - Clean-up"
            Write-Output -InputObject "No vulnerabilities found, see [$($Env:COMPUTERNAME)] $($fLogContentFile) for further information."
            exit 0
        }
        else {
            fLogContent -fLogContent "Found $vulnerabilityCounter vulnerabilities." -fLogContentComponent "detection script - Clean-up"
            Write-Output -InputObject "Found $vulnerabilityCounter vulnerabilities, see [$($Env:COMPUTERNAME)] $($fLogContentFile) for further information."
            exit 1
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
