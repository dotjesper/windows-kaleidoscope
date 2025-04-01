<#PSScriptInfo
.VERSION 0.9.2.5
.GUID 53d01844-c77b-4366-966f-f20f43f52c79
.AUTHOR @dotjesper
.COMPANYNAME dotjesper.com
.COPYRIGHT dotjesper.com
.TAGS windows powershell-5 windows-10 windows-11 microsoft-intune
.LICENSEURI https://github.com/dotjesper/windows-rhythm/blob/main/LICENSE
.PROJECTURI https://github.com/dotjesper/windows-rhythm
.ICONURI
.EXTERNALMODULEDEPENDENCIES
.REQUIREDSCRIPTS
.EXTERNALSCRIPTDEPENDENCIES
.RELEASENOTES https://github.com/dotjesper/windows-rhythm/wiki/release-notes
#>
<#
.SYNOPSIS
    Export Device status report for Remediation scripts.
.DESCRIPTION
    Export Device status report for Remediation scripts into grid view, outputting to *.csv or *.html
    This script is a conceptual preview and is subject to change. It is not intended for production use.
.PARAMETER TenantId
    The TenantId to use for the connection to Microsoft Graph. Default is $null.
.PARAMETER scriptPackageOutputType
    The output file type (CSV | HTML). Default is CSV.
.PARAMETER scriptPackageOutputFolder
    The output folder. Default is "Documents" folder.
.PARAMETER useGridView
    List Remediation details in Grid View. Default is $true.
.PARAMETER installRequiredComponents
    Install required modules and package providers automaticly. Default is $false.
.EXAMPLE
    .\Invoke-RemidiationStatusReport.ps1
.EXAMPLE
    .\Invoke-RemidiationStatusReport.ps1 -$reportOutputType "htmL" -installRequiredComponents $true
.EXAMPLE
    .\Invoke-RemidiationStatusReport.ps1 -TenantId "<TenantId>" -scriptPackageOutputType "csv" -scriptPackageOutputFolder "C:\Temp" -useGridView $true -installRequiredComponents $true
.NOTES
    File Name      : Invoke-RemidiationStatusReport.ps1
    Author         : @dotjesper
    Prerequisite   : PowerShell 5.1
#>
# requires -version 5.1
[CmdletBinding(SupportsShouldProcess = $True, ConfirmImpact = "Medium")]
param
(
    [Parameter (Mandatory = $False, HelpMessage = "TenantId") ]
    [Alias("Id")]
    [string]$TenantId = $null,

   #[Parameter (Mandatory = $False, HelpMessage = "Specify remediation package (* for all)") ]
   #[Alias("PackageName")]
   #[array]$remediationPackageId = "*",

    [Parameter (Mandatory = $False, HelpMessage = "Choose output file format [CSV | HTML]") ]
    [ValidateSet("csv", "html")]
    [Alias("SAVEAS")]
    [String]$reportOutputType = "csv",

    [Parameter (Mandatory = $False, HelpMessage = "Choose where to save output [Select 'S' for File picker, 'D' for Documents]") ]
    [Alias("SAVETO")]
    [String]$reportOutputFolder = "D",

    [Parameter (Mandatory = $False, HelpMessage = "List remediation details in Grid View") ]
    [Alias("LIST")]
    [bool]$useGridView = $true,

    [Parameter (Mandatory = $False, HelpMessage = "Install required modules and package providers automaticly") ]
    [Alias("installRequired")]
    [bool]$installRequiredComponents = $false
) #
begin {
    [string]$headerText = "$([char]0x25CF) Microsoft Intune Remediation Reporting tool $([char]0x25CF)"
    [string]$detectedLanguageMode = $($ExecutionContext.SessionState.LanguageMode)
    [string]$detectedCultureName = $(Get-Culture).Name
    [int]$detectedKeyboardLayoutId = $(Get-Culture).KeyboardLayoutId
    #region :: welcome
    Write-Output -InputObject " $headerText "
    #endregion
    #region :: prefligh checks
    if ($detectedLanguageMode -eq "ConstrainedLanguage") {
        Write-Output -InputObject "ERROR: Constrained Language mode detected"
        Write-Output -InputObject "ERROR: Constrained Language mode not supported, script exiting"
        exit
    }
    else {
        Write-Verbose -Message "Detected language mode: $detectedLanguageMode"
        Write-Verbose -Message "Detected culture name: $detectedCultureName"
        Write-Verbose -Message "Detected keyboard layout ID: $detectedKeyboardLayoutId"
    }
    [array]$requiredPackageProviders = @("NuGet")
    [array]$requiredModules = @("Microsoft.Graph.DeviceManagement")
    Write-Output -InputObject "Validating $($requiredPackageProviders.Count) Package Provider(s) and $($requiredModules.Count) module(s)"
    foreach ($requiredPackageProvider in $requiredPackageProviders) {
        if (Get-PackageProvider -Name $requiredPackageProvider -ListAvailable -ErrorAction SilentlyContinue) {
            Write-Verbose -Message "$requiredPackageProvider Package Provider found"
        }
        else {
            Write-Verbose -Message "$requiredPackageProvider Package Provider not found"
            if ($installRequiredComponents -eq $true) {
                Write-Verbose -Message "Installing $requiredPackageProvider Package Provider"
                try {
                    $PackageProviderInstall = Install-PackageProvider -Name $requiredPackageProvider -Force

                    Write-Output -InputObject "> $($PackageProviderInstall.Name) $($PackageProviderInstall.Version) installed"
                }
                catch {
                    $errMsg = $_.Exception.Message
                    Write-Error -Message $errMsg
                    exit
                }
            }
            else {
                Write-Output -InputObject "$requiredPackageProvider Package Provider not found"
                Write-Output -InputObject "Would you like to download and install '$requiredPackageProvider' now?"
                $confirmation = Read-Host "[Y] Yes  [N] No  [S] Suspend (default is 'N')"
                if ($confirmation.ToUpper() -eq 'Y') {
                    Write-Verbose -Message "Installing $requiredPackageProvider Package Provider"
                    try {
                        $PackageProviderInstall = Install-PackageProvider -Name $requiredPackageProvider -Force
                        Write-Output -InputObject "> $($PackageProviderInstall.Name) $($PackageProviderInstall.Version) installed"
                    }
                    catch {
                        $errMsg = $_.Exception.Message
                        Write-Error -Message $errMsg
                        exit
                    }
                }
                else {
                    Write-Verbose -Message "$requiredPackageProvider Package Provider not installed!"
                    Write-Output -InputObject "$requiredPackageProvider Package Provider is required, script exiting"
                    exit
                }
            }
        }
    }
    foreach ($requiredModule in $requiredModules) {
        if (Get-Module -Name $requiredModule -ListAvailable -ErrorAction SilentlyContinue) {
            Write-Verbose -Message "$requiredModule module found"
        }
        else {
            if ($installRequiredComponents -eq $true) {
                Write-Verbose -Message "Installing $requiredModule module"
                try {
                    Install-Module -Name $requiredModule -AllowClobber -Scope "CurrentUser" -SkipPublisherCheck -Force
                    Write-Output -InputObject "> $requiredModule module installed"
                }
                catch {
                    $errMsg = $_.Exception.Message
                    Write-Error -Message $errMsg
                    exit
                }
            }
            else {
                Write-Output -InputObject "$requiredModule module not found"
                Write-Output -InputObject "Would you like to download and install '$requiredModule' module now?"
                $confirmation = Read-Host "[Y] Yes  [N] No  [S] Suspend (default is 'N')"
                if ($confirmation.ToUpper() -eq 'Y') {
                    Write-Verbose -Message "Installing $requiredModule module"
                    try {
                        Install-Module -Name $requiredModule -Scope "CurrentUser" -AllowClobber -SkipPublisherCheck -Force
                        Write-Verbose -Message "> $requiredModule module installed"
                    }
                    catch {
                        $errMsg = $_.Exception.Message
                        Write-Error -Message $errMsg
                        exit
                    }
                }
                else {
                    Write-Verbose -Message "$requiredModule not installed!"

                    Write-Output -InputObject "$requiredModule module is required, script exiting"
                    exit
                }
            }
        }
    }
    #endregion
    #region :: Connecting to Microsoft Graph
    Write-Output -InputObject "Connecting to Microsoft Graph"
    try {
        if ($TenantId) {
            Write-Output -InputObject "> using TenantId: $TenantId"
            Connect-MgGraph -Scopes "Directory.Read.All,DeviceManagementConfiguration.Read.All" -NoWelcome -TenantId $TenantId
            ### Note:
            ### To list all scopes, use: Find-MgGraphPermission
        }
        else {
            Write-Output -InputObject "> no TenantId specified"
            Connect-MgGraph -Scopes "Directory.Read.All,DeviceManagementConfiguration.Read.All" -NoWelcome
        }
        Write-Output -InputObject "> connected"
        Write-Output -InputObject "Fetching organization metadata"
        [array]$organizationMetadata = (Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/organization").value
        Write-Output -InputObject "> $($organizationMetadata.displayName) (TenantId: $($organizationMetadata.Id))"
    }
    catch {
        Write-Output -InputObject "> user canceled authentication, script exiting"
        exit
    }
    finally {
        Write-Output -InputObject "> done"
    }
    #endregion
    #region :: internal variables
    [string]$TenantId = $($organizationMetadata.Id)
    [string]$tenantDisplayName = $organizationMetadata.displayName
    [array]$deviceHealthScriptRemediationDetails = @()
    #endregion
} #
process {
    #region :: Reading Remediation packages
    Write-Output -InputObject "Reading Remediation packages"
    $mgGraphUrl = "https://graph.microsoft.com"
    $mgGraphApiVersion = "beta"
    $mgGraphResource = "deviceManagement/deviceHealthScripts"
    try {
        [string]$mgGraphDeviceHealthScriptsUrl = "$mgGraphUrl/$mgGraphApiVersion/$mgGraphResource"
        [array]$deviceHealthPackages = (Invoke-MgGraphRequest -Method GET -Uri $mgGraphDeviceHealthScriptsUrl).value
    }
    catch {
        $errMsg = $_.Exception.Message
        Write-Error -Message $errMsg
        exit
    }
    Write-Output -InputObject "> Found $($deviceHealthPackages.Count) Remediation packages"
    #endregion
    if ($useGridView -eq $true) {
        Write-Output -InputObject "Select one or more Remediation packages"
        [array]$deviceHealthPackages = $deviceHealthPackages | Select-Object -Property @{Label = "Script package Id"; Expression = { $_.Id } }, @{Name = "Script package name"; Expression = { $_.displayName } }, @{Name = "Description"; Expression = { $_.description } }, @{Name = "Publisher"; Expression = { $_.publisher } } | Sort-Object -Property "Script package name" | Out-GridView -Title "Select one or more Remediation packages - $tenantDisplayName" -PassThru
        if ($($deviceHealthPackages.Count) -gt 0) {
            Write-Output -InputObject "$($deviceHealthPackages.Count) Remediation package(s) selected"
        }
        else {
            Write-Output -InputObject "> No Remediation package(s) selected, script exiting"
            #exit
        }
        #region :: deviceHealthScriptRemediationDetails
        foreach ($deviceHealthPackage in $deviceHealthPackages) {
            Write-Output -InputObject "> processing '$($deviceHealthPackage.'Script package name')' [$($deviceHealthPackage.'Script package Id')]"
            try {
                [string]$mgGraphdeviceRunStatesUrl = "$mgGraphDeviceHealthScriptsUrl/$($deviceHealthPackage.'Script package Id')/deviceRunStates/" + '?$expand=*'
                [array]$deviceHealthScriptProbe = (Invoke-MgGraphRequest -Method GET -Uri $mgGraphdeviceRunStatesUrl)
                # Check if value attribute @odate.nextLink exits
                if ($deviceHealthScriptProbe.'@odata.nextLink') {
                    Write-Output -InputObject " *"
                    [array]$deviceHealthScriptRows = (Invoke-MgGraphRequest -Method GET -Uri $mgGraphdeviceRunStatesUrl) | Get-MgGraphAllPages
                }
                else {
                   #[array]$deviceHealthScriptRows = (Invoke-MgGraphRequest -Method GET -Uri $mgGraphdeviceRunStatesUrl).value
                   [array]$deviceHealthScriptRows = $deviceHealthScriptProbe.value
                }
                Write-Output -InputObject "> total entries: $($deviceHealthScriptRows.Count)"
            }
            catch {
                $errMsg = $_.Exception.Message
                Write-Error -Message $errMsg
                exit
            }
            foreach ($deviceHealthScriptRow in $deviceHealthScriptRows) {
                #region :: enumerating OS build
                if ($deviceHealthScriptRow.managedDevice.osVersion -ne "") {
                    [int]$osBuild = $([version]$deviceHealthScriptRow.managedDevice.osVersion).Build
                    switch ($osBuild) {
                        18362 {
                            [string]$osRelease = "Windows 10"
                            [string]$osBuild = "19H1"
                        }
                        18363 {
                            [string]$osRelease = "Windows 10"
                            [string]$osBuild = "19H2"
                        }
                        19041 {
                            [string]$osRelease = "Windows 10"
                            [string]$osBuild = "20H1"
                        }
                        19042 {
                            [string]$osRelease = "Windows 10"
                            [string]$osBuild = "20H2"
                        }
                        19043 {
                            [string]$osRelease = "Windows 10"
                            [string]$osBuild = "21H1"
                        }
                        19044 {
                            [string]$osRelease = "Windows 10"
                            [string]$osBuild = "21H2"
                        }
                        19045 {
                            [string]$osRelease = "Windows 10"
                            [string]$osBuild = "22H2"
                        }
                        22000 {
                            [string]$osRelease = "Windows 11"
                            [string]$osBuild = "21H2"
                        }
                        22621 {
                            [string]$osRelease = "Windows 11"
                            [string]$osBuild = "22H2"
                        }
                        22631 {
                            [string]$osRelease = "Windows 11"
                            [string]$osBuild = "23H2"
                        }
                        22641 {
                            [string]$osRelease = "Windows 11"
                            [string]$osBuild = "24H2"
                        }
                        Default {
                            if ($osBuild -gt 22641) {
                                [string]$osRelease = "Future"
                                [string]$osBuild = "Future"
                            }
                            else {
                                [string]$osRelease = "Unknown"
                                [string]$osBuild = "Unsupported"
                            }
                        }
                    }
                }
                else {
                    [string]$osBuild = "Unknown"
                }
                #endregion
                #region :: building object
                Write-Verbose -Message "Adding $($deviceHealthScriptRow.managedDevice.id) ($($deviceHealthScriptRow.managedDevice.deviceName)) to data collection"
                $deviceHealthScriptRemediationDetails += [PSCustomObject] @{
                    "Script package name"               = $($deviceHealthPackage.'Script package name')
                    "Device name"                       = $deviceHealthScriptRow.managedDevice.deviceName
                    "Device Id"                         = $deviceHealthScriptRow.managedDevice.id
                    "OS Release"                        = $osRelease
                    "OS build"                          = $osBuild
                    "OS version"                        = $deviceHealthScriptRow.managedDevice.osVersion
                    "User name"                         = $deviceHealthScriptRow.managedDevice.userPrincipalName
                    "Detection status"                  = $deviceHealthScriptRow.detectionState
                    "Remediation status"                = $deviceHealthScriptRow.remediationState
                    "Pre-remediation detection error"   = $deviceHealthScriptRow.preRemediationDetectionScriptError
                    "Pre-remediation detection output"  = $deviceHealthScriptRow.preRemediationDetectionScriptOutput
                    "Remediation error"                 = $deviceHealthScriptRow.remediationScriptError
                    "Post-remediation detection error"  = $deviceHealthScriptRow.postRemediationDetectionScriptError
                    "Post-remediation detection output" = $deviceHealthScriptRow.postRemediationDetectionScriptOutput
                    "Last sync time"                    = $deviceHealthScriptRow.lastSyncDateTime
                    "Last update time"                  = $deviceHealthScriptRow.lastStateUpdateDateTime
                }
                #endregion
            }
        }
        if ($($deviceHealthScriptRemediationDetails.Count) -ge 1) {
            Write-Output -InputObject "Opening $($deviceHealthScriptRemediationDetails.Count) rows in Grid View"
            Write-Output -InputObject "> Select one or more rows from Remediation packages details"
            [array]$selectedRemediationDetails = $deviceHealthScriptRemediationDetails | Out-GridView -Title "Remediation pachage details - $tenantDisplayName" -PassThru
            if ($($selectedRemediationDetails.Count) -gt 0) {
                if ($($selectedRemediationDetails.Count) -eq 1) {
                    Write-Output -InputObject "> $($selectedRemediationDetails.Count) row selected"
                }
                else {
                    Write-Output -InputObject "> $($selectedRemediationDetails.Count) rows selected"
                }
                #region :: Configure Output folder
                Write-Output -InputObject "Validating Output folder"
                switch ($reportOutputFolder) {
                    "D" {
                        $reportOutputFolder = "$([environment]::getfolderpath("MyDocuments"))"
                        Write-Output -InputObject "> Output folder: '$reportOutputFolder' (Default)"
                    }
                    "S" {
                        [void]([System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms"))
                        $foldername = New-Object System.Windows.Forms.FolderBrowserDialog -Property @{
                            rootfolder = "Desktop"
                            Description = "Select a folder to save the report"
                            SelectedPath = "$([environment]::getfolderpath("MyDocuments"))"
                            ShowNewFolderButton = $true
                        }
                        if($foldername.ShowDialog() -eq "OK") {
                            $reportOutputFolder = $foldername.SelectedPath
                            Write-Output -InputObject "> Selected folder: '$reportOutputFolder'"
                        }
                        else {
                            Write-Output -InputObject "> No folder selected, script exiting"
                            exit
                        }
                    }
                    Default {
                        Write-Output -InputObject "> Output folder: '$reportOutputFolder' (Custom)"
                    }
                }
                #endregion
                #region :: Validate Output folder
                if (Test-Path -Path $reportOutputFolder) {
                    Write-Output -InputObject "> Output folder '$reportOutputFolder' exists"
                }
                else {
                    Write-Output -InputObject "> Output folder '$reportOutputFolder' not found"
                    Write-Output -InputObject "> Creating output folder: '$reportOutputFolder'"
                    try {
                        [void](New-Item -Path $reportOutputFolder -ItemType "Directory" -Force)
                    }
                    catch {
                        $errMsg = $_.Exception.Message
                        Write-Error -Message $errMsg
                        exit
                    }
                    finally {
                        Write-Output -InputObject "> Output folder '$reportOutputFolder' created"
                    }
                }
                #endregion
                #region :: Exporting to CSV or HTML
                Write-Output -InputObject "Exporting selected rows to '$($reportOutputType.ToUpper())'"
                Write-Output -InputObject "> processing $($selectedRemediationDetails.Count) rows"
                switch ($reportOutputType) {
                    "csv" {
                        Write-Verbose -Message "Exporting selected rows to 'CSV'"
                        $selectedRemediationDetails | Export-Csv -Path "$($reportOutputFolder)\RemidiationReport.csv" -Encoding "UTF8" -Delimiter ";" -NoTypeInformation
                    }
                    "html" {
                        Write-Verbose -Message "Exporting selected rows to 'HTML'"
                        $htmlTitle = "Remediation report - $tenantDisplayName"
                        $htmlPreContent = "<h1>Remediation report - $tenantDisplayName</h1><p id='TenantName'>Tenant: $tenantDisplayName</p><p id='Tenant ID'>TenantID: $TenantId</p><p id='Records'>Records exported: $($selectedRemediationDetails.Count)</p>"
                        $htmlPostContent = "<p id='CreationDate'>Creation Date: $(Get-Date)<p>"
                        $htmlCssUri = "./style.css"
                        $selectedRemediationDetails | ConvertTo-Html -As "Table" -Title $htmlTitle -PreContent $htmlPreContent -PostContent $htmlPostContent -CssUri $htmlCssUri | Out-File -FilePath "$($reportOutputFolder)\RemidiationReport.html" -Encoding "UTF8"
                        Write-Verbose -Message "Copying 'html stylesheet' file to output folder"
                        Copy-Item -Path $htmlCssUri -Destination $reportOutputFolder -Force
                    }
                }
                #endregion
                Write-Output -InputObject "> $($selectedRemediationDetails.Count) rows exported to '$($reportOutputFolder)\RemidiationReport.$($reportOutputType.ToLower())'"
            }
            else {
                Write-Output -InputObject "No rows selected."
            }
        }
        else {
            Write-Output -InputObject "> Device health script remediation details has no data"
        }
        #endregion
    }
    else {
        foreach ($deviceHealthScript in $deviceHealthPackages) {
            Write-Output -InputObject "> $($deviceHealthScript.Id) - $($deviceHealthScript.displayName)"
        }
    }
} #
end {
    Write-Output -InputObject "Finishing up, please wait..."
    Write-Output -InputObject "> Cleaning up environment"
    Remove-Variable -Name * -ErrorAction SilentlyContinue
    $error.Clear()
    [System.GC]::Collect()
    Write-Output -InputObject "> Done - have a nice day!"
} #
