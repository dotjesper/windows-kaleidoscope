#requires -Version 5.1
<#
.SYNOPSIS
    This script is for Windows Autopilot device preparation.
.DESCRIPTION
    This script performs the following actions:
    - Renames the computer based on the specified naming method (serial number or random digits).
    - Applies registry settings to optimize the enrollment experience.
    - Marks the system for a pending reboot without forcing an immediate restart.
.PARAMETER Prefix
    Defines a custom prefix for the computer name.
.PARAMETER NamingMethod
    Specify "%SERIAL%" to use the device serial number for naming.
    Specify "%RAND:x%" where x is the number of random digits to generate.
.PARAMETER Suffix
    Defines a custom suffix for the computer name.
.EXAMPLE
    .\device-preparation.ps1 -Prefix "WIN-" -Suffix "-01" -NamingMethod "%SERIAL%"
.NOTES
    Author: Jesper Nielsen
    Version: 1.4
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $false, HelpMessage = "Enter a custom prefix for the computer name (e.g., WIN-, PC-, LAP-)")]
    [string]$Prefix = "WSR5",

    [Parameter(Mandatory = $false, HelpMessage = "Create a location marker for language and region settings")]
    [string]$LocationMarker = "DEN",

    [Parameter(Mandatory = $false, HelpMessage = "Specify the registry path for the location marker")]
    [string]$LocationMarkerPath = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE",

    [Parameter(Mandatory = $false, HelpMessage = "Specify '%SERIAL%' for serial-based naming or '%RAND:x%' where x is the number of random digits")]
    [string]$NamingMethod = "",

    [Parameter(Mandatory = $false, HelpMessage = "Enter a custom suffix for the computer name (e.g., -01, -A)")]
    [string]$Suffix = "",

    [Parameter(Mandatory = $false, HelpMessage = "Enter a custom log file path (e.g., C:\Temp\log.txt)")]
    [string]$logFile = ""
)
begin {
    #region :: Environment
    #
    #endregion
    #region :: Environment configurations
    [String]$title = "Windows Autopilot device preparation"
    [string]$fLogContentFile = "$($Env:ProgramData)\Microsoft\IntuneManagementExtension\Logs\device-preparation.log"
    #endregion
    #region :: Functions
    function fLogContent () {
        <#
        .SYNOPSIS
           Log-file function.
        .DESCRIPTION
            Log-file function, write a single log line when called.
            Each line in the log can have various attributes, log text, information about the component from which the fumction is called and an option to specify log file name for each entry.
            Formatting adhere to the CMTrace and Microsoft Intune log format.
        .PARAMETER fLogContent
            Holds the string to write to the log file. If script is called with the -Verbose, this string will be sent to the console.
        .PARAMETER fLogContentComponent
            Information about the component from which the fumction is called, e.g. a specific section in the script.
        .PARAMETER fLogContentType
            Standard log types
			1: MessageTypeInfo - Informational Message (Default)
			2: MessageTypeWarning - Warning Message
			3: MessageTypeError - Error Message
        .PARAMETER fLogContentfn
            Option to specify log file name for each entry.
        .EXAMPLE
            fLogContent -fLogContent "This is the log string" -fLogContentComponent "If applicable, add section, or component for log entry"
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory = $true, HelpMessage = "Log string to be written to the log file.")]
            [string]$fLogContent,
            [Parameter(Mandatory = $false, HelpMessage = "If applicable, add section, or component for log entry")]
            [string]$fLogContentComponent,
            [Parameter(Mandatory = $false, HelpMessage = "Standard log types: 1: MessageTypeInfo - Informational Message (Default), 2: MessageTypeWarning - Warning Message, 3: MessageTypeError - Error Message")]
            [ValidateSet(1,2,3)]
            [int]$fLogContentType = 1,
            [Parameter(Mandatory = $false, HelpMessage = "Option to specify log file name for each entry.")]
            [string]$fLogContentfn = $fLogContentFile
        )
        begin {
            $fdate = $(Get-Date -Format "M-dd-yyyy")
            $ftime = $(Get-Date -Format "HH:mm:ss.fffffff")
        }
        process {
            try {
                if (-not (Test-Path -Path "$(Split-Path -Path $fLogContentfn)")) {
                    New-Item -itemType "Directory" -Path "$(Split-Path -Path $fLogContentfn)" | Out-Null
                }
                Add-Content -Path $fLogContentfn -Value "<![LOG[[$fLogContentpkg] $($fLogContent)]LOG]!><time=""$($ftime)"" date=""$($fdate)"" component=""$fLogContentComponent"" context="""" type=""$fLogContentType"" thread="""" file="""">" -Encoding "UTF8" | Out-Null
            }
            catch {
                throw $_.Exception.Message
                exit 1
            }
            finally {}
            Write-Verbose -Message "$($fLogContent)"
        }
        end {}
    }
    #endregion
    #region :: Logfile environment entries
    $region = "environment"
    try {
        fLogContent -fLogContent "## $title" -fLogContentComponent "$region"
        fLogContent -fLogContent "Log file: $($fLogContentFile)" -fLogContentComponent "$region"
        fLogContent -fLogContent "Script name: $($MyInvocation.MyCommand.Name)" -fLogContentComponent "$region"
        foreach ($key in $MyInvocation.BoundParameters.keys) {
            switch ($MyInvocation.BoundParameters[$key].GetType().Name) {
                "Boolean" {
                    $argsString += "-$key `$$($MyInvocation.BoundParameters[$key]) "
                }
                "Int32" {
                    $argsString += "-$key $($MyInvocation.BoundParameters[$key]) "
                }
                "String" {
                    $argsString += "-$key `"$($MyInvocation.BoundParameters[$key])`" "
                }
                "SwitchParameter" {
                    if ($MyInvocation.BoundParameters[$key].IsPresent) {
                        $argsString += "-$key "
                    }
                }
                Default {}
            }
        }
        fLogContent -fLogContent "Command line: .\$($myInvocation.myCommand.name) $($argsString)" -fLogContentComponent "$region"
        fLogContent -fLogContent "Running 64 bit PowerShell: $([System.Environment]::Is64BitProcess)" -fLogContentComponent "$region"
        if ($($ExecutionContext.SessionState.LanguageMode) -eq "FullLanguage") {
            fLogContent -fLogContent "Running elevated: $(([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))" -fLogContentComponent "$region"
            fLogContent -fLogContent "Detected user: $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)" -fLogContentComponent "$region"
        }
        else {
            fLogContent -fLogContent "Detected user: $($Env:USERNAME)" -fLogContentComponent "$region"
        }
        fLogContent -fLogContent "Detected language mode: $($ExecutionContext.SessionState.LanguageMode)" -fLogContentComponent "$region"
        fLogContent -fLogContent "Detected culture name: $((Get-Culture).Name)" -fLogContentComponent "$region"
        fLogContent -fLogContent "Detected keyboard layout Id: $((Get-Culture).KeyboardLayoutId)" -fLogContentComponent "$region"
        fLogContent -fLogContent "Detected computer name: $env:COMPUTERNAME" -fLogContentComponent "$region"
        fLogContent -fLogContent "Detected OS build: $($([environment]::OSVersion.Version).Build)" -fLogContentComponent "$region"
        fLogContent -fLogContent "Detected Windows UI culture name: $((Get-UICulture).Name)" -fLogContentComponent "$region"
    }
    catch {
        $errMsg = $_.Exception.Message
        fLogContent -fLogContent "ERROR: $errMsg" -fLogContentComponent "$region" -fLogContentType 3
        if ($exitOnError) {
            exit 1
        }
    }
    finally {}
    #endregion
    #region :: Check conditions
    #endregion
}
process {
    #region :: Determine naming method
    $region = "name-validation"
    if ($NamingMethod -match "%SERIAL%") {
        fLogContent -fLogContent "Using serial number for naming..." -fLogContentComponent "$region"
        try {
            $serialNumber = ((Get-WmiObject -Class Win32_BIOS).SerialNumber -replace "-", "")
        }
        catch {
            fLogContent -fLogContent "ERROR: $errMsg" -fLogContentComponent "$region" -fLogContentType 3
            exit 1
        }
        # Calculate maximum substring length based on prefix + suffix
        $maxSerialLength = 15 - ($Prefix.Length + $Suffix.Length)
        $newName = "$Prefix$($serialNumber.Substring(0,$maxSerialLength))$Suffix"
    }
    elseif ($NamingMethod -match "%RAND:(\d+)%") {
        fLogContent -fLogContent "Using random number for naming..." -fLogContentComponent "$region"
        # Extract the number of digits for random number generation
        [int]$randomDigits = [int]$matches[1]
        if ($randomDigits -gt (15 - ($Prefix.Length + $Suffix.Length))) {
            fLogContent -fLogContent "The total length of prefix, suffix, and random digits exceeds 15 characters. Truncating..." -fLogContentComponent "$region" -fLogContentType 2
            $randomDigits = $randomDigits - ($randomDigits - (15 - ($Prefix.Length + $Suffix.Length)))
        }
        fLogContent -fLogContent "> Using random number with $randomDigits digits for naming..." -fLogContentComponent "$region"
        $randomNumber = -join ((0..9) | Get-Random -Count $randomDigits)
        $newName = "$Prefix$randomNumber$Suffix"
    }
    else {
        # Generate a SHA256 hash of the serial number
        fLogContent -fLogContent "Using serial number hashing for naming..." -fLogContentComponent "$region"
        fLogContent -fLogContent "Generating hashed serial number..." -fLogContentComponent "$region"
        try {
            $serialNumber = ((Get-WmiObject -Class Win32_BIOS).SerialNumber -replace "-", "")
            fLogContent -fLogContent "> Serial number: $serialNumber" -fLogContentComponent "$region"
        }
        catch {
            fLogContent -fLogContent "> Serial number not found. Cannot generate name." -fLogContentComponent "$region" -fLogContentType 3
            exit 1
        }
        if (-not $serialNumber) {
            fLogContent -fLogContent "> Serial number not found. Cannot generate hashed name." -fLogContentComponent "$region" -fLogContentType 3
            exit 1
        }
        # Generate SHA256 hash
        $hash = [System.Security.Cryptography.SHA256Managed]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes($serialNumber))
        $hashString = ([BitConverter]::ToString($hash)) -replace "-", ""
        fLogContent -fLogContent "> Generated hash: $hashString" -fLogContentComponent "$region"
        # Calculate maximum substring length based on prefix + suffix
        $maxHashLength = 15 - ($Prefix.Length + $Suffix.Length)
        fLogContent -fLogContent "> Using $maxHashLength characters from hash..." -fLogContentComponent "$region"
        # Define naming template (prefix + truncated hash + suffix)
        $newName = "$Prefix$($hashString.Substring(0, $maxHashLength))$Suffix" # Ensuring name not exceed 15 characters
        fLogContent -fLogContent "Generated name: $newName" -fLogContentComponent "$region"
    }
    #endregion
    #region :: Validate name does not exceed 15 characters
    $region = "name-validation"
    if ($newName.Length -gt 15) {
        fLogContent -fLogContent "Warning: The generated name exceeds 15 characters. Truncating..." -fLogContentComponent "$region" -fLogContentType 2
        $newName = $newName.Substring(0, 15)
        fLogContent -fLogContent "Truncated name: $newName" -fLogContentComponent "$region"
    }
    #endregion
    #region :: Rename device
    $region = "rename-device"
    if ($newName.Substring(0, $Prefix.Length) -eq $env:COMPUTERNAME.Substring(0, $Prefix.Length) -and $Prefix.Length -gt 0) {
        fLogContent -fLogContent "The computer name already starts with the specified prefix." -fLogContentComponent "$region"
        fLogContent -fLogContent "> No renaming required." -fLogContentComponent "$region"
        fLogContent -fLogContent "> Current name: $($env:COMPUTERNAME)" -fLogContentComponent "$region"
    }
    else {
        fLogContent -fLogContent "Renaming device..." -fLogContentComponent "$region"
        try {
            $renameStatus = Rename-Computer -NewName $newName -Force -ErrorAction Stop -WarningAction:SilentlyContinue -PassThru
            # Check if the rename operation was successful
            if ($renameStatus.HasSucceeded) {
                fLogContent -fLogContent "Device renamed successfully" -fLogContentComponent "$region"
                fLogContent -fLogContent "> Has Succeeded: $($renameStatus.HasSucceeded)" -fLogContentComponent "$region"
                fLogContent -fLogContent "> New name: $($renameStatus.NewComputerName)" -fLogContentComponent "$region"
                fLogContent -fLogContent "> Old name: $($renameStatus.OldComputerName)" -fLogContentComponent "$region"
                fLogContent -fLogContent "> The changes will take effect after restarting the computer." -fLogContentComponent "$region"
            }
        }
        catch {
            fLogContent -fLogContent "ERROR: $($renameStatus.Exception.Message)" -fLogContentComponent "$region" -fLogContentType 3
            exit 1
        }
        finally {}
        #region :: Mark the device for pending reboot (without forcing it)
        $region = "pending-reboot"
        try {
            fLogContent -fLogContent "Adding pending reboot flag..." -fLogContentComponent "$region"
            $null = New-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" -PropertyType "String" -Name "RebootRequired" -Value 1 -Force
        }
        catch {
            $errMsg = $_.Exception.Message
            fLogContent -fLogContent "ERROR: $errMsg" -fLogContentComponent "$region" -fLogContentType 3
            exit 1
        }
        finally {}
        #endregion
    }
    #endregion
    #region :: Apply registry settings
    $region = "registry-settings"
    fLogContent -fLogContent "Configuring registry settings..." -fLogContentComponent "$region"
    try {
        fLogContent -fLogContent "> Disabling Privacy Experience..." -fLogContentComponent "$region"
        $null = New-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE" -PropertyType "DWord" -Name "DisablePrivacyExperience" -Value 1 -Force
        fLogContent -fLogContent "> Disabling Voice features..." -fLogContentComponent "$region"
        $null = New-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE" -PropertyType "DWord" -Name "DisableVoice" -Value 1 -Force
        fLogContent -fLogContent "> Setting Privacy Consent status..." -fLogContentComponent "$region"
        $null = New-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE" -PropertyType "DWord" -Name "PrivacyConsentStatus" -Value 1 -Force
        fLogContent -fLogContent "> Setting Protection settings..." -fLogContentComponent "$region"
        $null = New-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE" -PropertyType "DWord" -Name "ProtectYourPC" -Value 3 -Force
        fLogContent -fLogContent "> Hiding the End User License Agreement (EULA) page..." -fLogContentComponent "$region"
        $null = New-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE" -PropertyType "DWord" -Name "HideEULAPage" -Value 1 -Force
    }
    catch {
        $errMsg = $_.Exception.Message
        fLogContent -fLogContent "ERROR: $errMsg" -fLogContentComponent "$region" -fLogContentType 3
        exit 1
    }
    finally {}
    #endregion
    #region :: Set location marker
    $region = "location-marker"
    if ($LocationMarker.Length -gt 0) {
        fLogContent -fLogContent "Location marker provided." -fLogContentComponent "$region"
        fLogContent -fLogContent "> Setting location marker..." -fLogContentComponent "$region"
        try {
            $null = New-ItemProperty -Path "$LocationMarkerPath" -PropertyType "String" -Name "LocationMarker" -Value $LocationMarker -Force
            fLogContent -fLogContent "> Location marker path: $LocationMarkerPath" -fLogContentComponent "$region"
            fLogContent -fLogContent "> Location marker value: $LocationMarker" -fLogContentComponent "$region"
        }
        catch {
            $errMsg = $_.Exception.Message
            fLogContent -fLogContent "ERROR: $errMsg" -fLogContentComponent "$region" -fLogContentType 3
            exit 1
        }
        finally {}
    }
    else {
        fLogContent -fLogContent "No location marker provided. Skipping..." -fLogContentComponent "$region"
    }
    #endregion
}
end {
    #region :: End of script
    $region = "end"
    fLogContent -fLogContent "Windows Autopilot Device Preparation script completed." -fLogContentComponent "$region"
    if ($renameStatus.HasSucceeded) {
        fLogContent -fLogContent "A reboot is pending, but will not be forced." -fLogContentComponent "$region"
    }
}