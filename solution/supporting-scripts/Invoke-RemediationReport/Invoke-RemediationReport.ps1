<#PSScriptInfo
.VERSION 1.0.0
.GUID 53d01844-c77b-4366-966f-f20f43f52c79
.AUTHOR @dotjesper
.COMPANYNAME dotjesper.com
.COPYRIGHT dotjesper.com
.TAGS windows powershell-5 windows-10 windows-11 microsoft-intune
.LICENSEURI https://github.com/dotjesper/windows-kaleidoscope/blob/main/LICENSE
.PROJECTURI https://github.com/dotjesper/windows-kaleidoscope
.ICONURI
.EXTERNALMODULEDEPENDENCIES
.REQUIREDSCRIPTS
.EXTERNALSCRIPTDEPENDENCIES
.RELEASENOTES https://github.com/dotjesper/windows-kaleidoscope/wiki/release-notes
#>

<#
.SYNOPSIS
    Export device status report for Microsoft Intune Remediation scripts.

.DESCRIPTION
    This script connects to Microsoft Graph and retrieves device run state data for
    Microsoft Intune Remediation packages, exporting the results to CSV or HTML.

    Remediation packages can be selected interactively using Grid View or a numbered
    console menu. The collected data includes device details, OS version, detection and
    remediation status, script output, and error information.

    This is a working sample — a conceptual solution intended for inspiration and for
    extracting, viewing, and working with remediation data. It is subject to change and
    is not intended for production use.

.PARAMETER TenantId
    The Microsoft Entra ID tenant identifier for the Microsoft Graph connection.
    If omitted, the connection prompt uses the default tenant.

.PARAMETER ReportOutputType
    The output file format. Valid values are CSV and HTML. Default is CSV.

.PARAMETER ReportOutputFolder
    The folder path where the report file is saved. Default is the current user's
    Documents folder.

.PARAMETER SelectOutputFolder
    Show a folder browser dialog to select the output folder interactively.
    Overrides the ReportOutputFolder parameter value when a folder is selected.

.PARAMETER UseGridView
    Use Out-GridView for interactive package and row selection. When Out-GridView is
    not available, the script falls back to console-based selection automatically.

.PARAMETER InstallRequiredComponents
    Install required PowerShell modules and package providers automatically without
    prompting for confirmation.

.EXAMPLE
    .\Invoke-RemediationReport.ps1

.EXAMPLE
    .\Invoke-RemediationReport.ps1 -ReportOutputType "html" -InstallRequiredComponents

.EXAMPLE
    .\Invoke-RemediationReport.ps1 -TenantId "<TenantId>" -ReportOutputType "csv" -ReportOutputFolder "C:\Temp" -UseGridView -InstallRequiredComponents

.NOTES
    File Name      : Invoke-RemediationReport.ps1
    Author         : @dotjesper
    Prerequisite   : PowerShell 5.1
#>

#requires -version 5.1

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false, HelpMessage = "TenantId for the Microsoft Graph connection")]
    [ValidateNotNullOrEmpty()]
    [Alias("Id")]
    [string]$TenantId,

    [Parameter(Mandatory = $false, HelpMessage = "Choose output file format [CSV | HTML]")]
    [ValidateSet("csv", "html")]
    [Alias("SAVEAS")]
    [string]$ReportOutputType = "csv",

    [Parameter(Mandatory = $false, HelpMessage = "Folder path to save the report output")]
    [ValidateNotNullOrEmpty()]
    [Alias("SAVETO")]
    [string]$ReportOutputFolder = "$([Environment]::GetFolderPath('MyDocuments'))",

    [Parameter(Mandatory = $false, HelpMessage = "Show a folder browser dialog to select the output folder")]
    [switch]$SelectOutputFolder,

    [Parameter(Mandatory = $false, HelpMessage = "List remediation details in Grid View for interactive selection")]
    [Alias("LIST")]
    [switch]$UseGridView,

    [Parameter(Mandatory = $false, HelpMessage = "Install required modules and package providers automatically")]
    [Alias("InstallRequired")]
    [switch]$InstallRequiredComponents
)

begin {

    #region :: Environment configurations
    [version]$ScriptVersion = '1.0.0'
    Set-Variable -Name 'ScriptVersion' -Value $ScriptVersion -Option ReadOnly -Scope Script
    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'
    #endregion

    #region :: variables
    [string]$headerText = "$([char]0x25CF) Microsoft Intune Remediation Reporting tool $([char]0x25CF)"
    [string]$detectedLanguageMode = $($ExecutionContext.SessionState.LanguageMode)
    [string]$detectedCultureName = $(Get-Culture).Name
    [int]$detectedKeyboardLayoutId = $(Get-Culture).KeyboardLayoutId

    # OS build number to release name mapping
    [hashtable]$osBuildMap = @{
        18362 = @{ Release = 'Windows 10'; Label = '19H1' }
        18363 = @{ Release = 'Windows 10'; Label = '19H2' }
        19041 = @{ Release = 'Windows 10'; Label = '20H1' }
        19042 = @{ Release = 'Windows 10'; Label = '20H2' }
        19043 = @{ Release = 'Windows 10'; Label = '21H1' }
        19044 = @{ Release = 'Windows 10'; Label = '21H2' }
        19045 = @{ Release = 'Windows 10'; Label = '22H2' }
        22000 = @{ Release = 'Windows 11'; Label = '21H2' }
        22621 = @{ Release = 'Windows 11'; Label = '22H2' }
        22631 = @{ Release = 'Windows 11'; Label = '23H2' }
        26100 = @{ Release = 'Windows 11'; Label = '24H2' }
        26200 = @{ Release = 'Windows 11'; Label = '25H2' }
    }
    [int]$osBuildMapMax = ($osBuildMap.Keys | Measure-Object -Maximum).Maximum
    #endregion

    #region :: preflight checks
    Write-Output -InputObject " $headerText "

    # Language mode check
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

    # Output folder check
    Write-Output -InputObject "Validating Output folder"
    if ($SelectOutputFolder) {
        Add-Type -AssemblyName "System.Windows.Forms"
        $folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog -Property @{
            rootfolder      = "Desktop"
            Description     = "Select a folder to save the report"
            SelectedPath    = "$([Environment]::GetFolderPath('MyDocuments'))"
            ShowNewFolderButton = $true
        }
        if ($folderDialog.ShowDialog() -eq "OK") {
            $ReportOutputFolder = $folderDialog.SelectedPath
            Write-Output -InputObject "> Selected folder: '$ReportOutputFolder'"
        }
        else {
            Write-Output -InputObject "> No folder selected, script exiting"
            exit
        }
    }
    else {
        Write-Output -InputObject "> Output folder: '$ReportOutputFolder'"
    }

    # Validate output folder existence or create it if it doesn't exist
    if (Test-Path -Path $ReportOutputFolder) {
        Write-Output -InputObject "> Output folder '$ReportOutputFolder' exists"
    }
    else {
        Write-Output -InputObject "> Output folder '$ReportOutputFolder' not found"
        Write-Output -InputObject "> Creating output folder: '$ReportOutputFolder'"
        try {
            [void](New-Item -Path $ReportOutputFolder -ItemType "Directory" -Force)
            Write-Output -InputObject "> Output folder '$ReportOutputFolder' created"
        }
        catch {
            $errMsg = $_.Exception.Message
            Write-Error -Message $errMsg
            exit
        }
    }

    # Validate write access to output folder by creating and deleting a test file
    try {
        [string]$writeTestFile = Join-Path -Path $ReportOutputFolder -ChildPath ".writetest_$([guid]::NewGuid())"
        [void](New-Item -Path $writeTestFile -ItemType "File" -Force)
        Remove-Item -Path $writeTestFile -Force
        Write-Verbose -Message "Write access to '$ReportOutputFolder' confirmed"
    }
    catch {
        Write-Output -InputObject "> Output folder '$ReportOutputFolder' is not writable, script exiting"
        exit
    }
    #endregion

    #region :: functions
    function Install-RequiredPackageProvider {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory)]
            [string]$Name
        )
        try {
            $result = Install-PackageProvider -Name $Name -Force
            Write-Output -InputObject "> $($result.Name) $($result.Version) installed"
        }
        catch {
            $errMsg = $_.Exception.Message
            Write-Error -Message $errMsg
            exit
        }
    }
    function Install-RequiredModule {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory)]
            [string]$Name
        )
        try {
            Install-Module -Name $Name -AllowClobber -Scope "CurrentUser" -SkipPublisherCheck -Force
            Write-Output -InputObject "> $Name module installed"
        }
        catch {
            $errMsg = $_.Exception.Message
            Write-Error -Message $errMsg
            exit
        }
    }
    #endregion
}
process {

    #region :: dependency validation
    [array]$requiredPackageProviders = @("NuGet")
    [array]$requiredModules = @("Microsoft.Graph.DeviceManagement")
    Write-Output -InputObject "Validating $($requiredPackageProviders.Count) Package Provider(s) and $($requiredModules.Count) module(s)"
    foreach ($requiredPackageProvider in $requiredPackageProviders) {
        if (Get-PackageProvider -Name $requiredPackageProvider -ListAvailable -ErrorAction SilentlyContinue) {
            Write-Verbose -Message "$requiredPackageProvider Package Provider found"
        }
        else {
            Write-Verbose -Message "$requiredPackageProvider Package Provider not found"
            if ($InstallRequiredComponents) {
                Write-Verbose -Message "Installing $requiredPackageProvider Package Provider"
                Install-RequiredPackageProvider -Name $requiredPackageProvider
            }
            else {
                Write-Output -InputObject "$requiredPackageProvider Package Provider not found"
                Write-Output -InputObject "Would you like to download and install '$requiredPackageProvider' now?"
                $confirmation = Read-Host "[Y] Yes  [N] No  [S] Suspend (default is 'N')"
                if ($confirmation -eq 'Y') {
                    Write-Verbose -Message "Installing $requiredPackageProvider Package Provider"
                    Install-RequiredPackageProvider -Name $requiredPackageProvider
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
            if ($InstallRequiredComponents) {
                Write-Verbose -Message "Installing $requiredModule module"
                Install-RequiredModule -Name $requiredModule
            }
            else {
                Write-Output -InputObject "$requiredModule module not found"
                Write-Output -InputObject "Would you like to download and install '$requiredModule' module now?"
                $confirmation = Read-Host "[Y] Yes  [N] No  [S] Suspend (default is 'N')"
                if ($confirmation -eq 'Y') {
                    Write-Verbose -Message "Installing $requiredModule module"
                    Install-RequiredModule -Name $requiredModule
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

            ### To list all scopes, use: Find-MgGraphPermission ###
        }
        else {
            Write-Output -InputObject "> no TenantId specified"
            Connect-MgGraph -Scopes "Directory.Read.All,DeviceManagementConfiguration.Read.All" -NoWelcome
        }
        Write-Output -InputObject "> connected"
        Write-Output -InputObject "Fetching organization metadata"
        [array]$organizationMetadata = (Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/organization").value
        Write-Output -InputObject "> $($organizationMetadata.displayName) (TenantId: $($organizationMetadata.Id))"
        Write-Output -InputObject "> done"

        [string]$TenantId = $($organizationMetadata.Id)
        [string]$tenantDisplayName = $organizationMetadata.displayName
        [System.Collections.Generic.List[PSCustomObject]]$deviceHealthScriptRemediationDetails = @()
    }
    catch {
        Write-Output -InputObject "> user canceled authentication, script exiting"
        exit
    }
    #endregion

    #region :: Reading Remediation packages
    Write-Output -InputObject "Reading Remediation packages"

    # Microsoft Graph API endpoint for device health scripts: https://graph.microsoft.com/beta/deviceManagement/deviceHealthScripts
    $mgGraphUrl = "https://graph.microsoft.com"
    $mgGraphApiVersion = "beta"
    $mgGraphResource = "deviceManagement/deviceHealthScripts"

    try {
        [string]$mgGraphDeviceHealthScriptsUrl = "$mgGraphUrl/$mgGraphApiVersion/$mgGraphResource"
        [array]$deviceHealthPackages = (Invoke-MgGraphRequest -Method GET -Uri $mgGraphDeviceHealthScriptsUrl).value

        # Note: The API may return paginated results, check for the @odata.nextLink property and fetch all pages if necessary.
    }
    catch {
        $errMsg = $_.Exception.Message
        Write-Error -Message $errMsg
        exit
    }
    Write-Output -InputObject "> Found $($deviceHealthPackages.Count) Remediation packages"
    #endregion

    #region :: Select Remediation package(s) for reporting
    if ($UseGridView) {
        # Verify Out-GridView availability by attempting a test call
        try {
            $null | Out-GridView -Title "Testing Out-GridView availability" -ErrorAction Stop
        }
        catch {
            Write-Output -InputObject "> Out-GridView is not available in this environment, falling back to console selection"
            $UseGridView = $false
        }
    }
    if ($UseGridView) {
        Write-Output -InputObject "Select one or more Remediation packages"

        [array]$selectedPackages = $deviceHealthPackages |
            Select-Object -Property @{Label = "Script package Id"; Expression = { $_.Id } }, @{Name = "Script package name"; Expression = { $_.displayName } }, @{Name = "Description"; Expression = { $_.description } }, @{Name = "Publisher"; Expression = { $_.publisher } } |
            Sort-Object -Property "Script package name" |
            Out-GridView -Title "Select one or more Remediation packages - $tenantDisplayName" -PassThru

        if ($($selectedPackages.Count) -gt 0) {
            Write-Output -InputObject "$($selectedPackages.Count) Remediation package(s) selected"
        }
        else {
            Write-Output -InputObject "> No Remediation package(s) selected, script exiting"
            exit
        }
    }
    else {
        Write-Output -InputObject "Select one or more Remediation packages"

        [array]$allPackages = $deviceHealthPackages |
            Select-Object -Property @{Label = "Script package Id"; Expression = { $_.Id } }, @{Name = "Script package name"; Expression = { $_.displayName } }, @{Name = "Description"; Expression = { $_.description } }, @{Name = "Publisher"; Expression = { $_.publisher } } |
            Sort-Object -Property "Script package name"

        # Selecting packages via console input
        for ([int]$i = 0; $i -lt $allPackages.Count; $i++) {
            Write-Output -InputObject "  [$($i + 1)] $($allPackages[$i].'Script package name')"
        }
        Write-Output -InputObject "  [A] All"
        Write-Output -InputObject "  [C] Cancel"

        [string]$selection = Read-Host "Select Remediation package(s) (default is 'A')"

        <# Supported input formats:
           Enter or A — selects all packages (default)
           2 — single package
           1,2 — comma-separated
           1-3 — range
           1,3-5,7 — mixed
        #>

        if ($selection -eq 'C') {
            Write-Output -InputObject "> Selection canceled, script exiting"
            exit
        }
        elseif ($selection -eq '' -or $selection -eq 'A') {
            [array]$selectedPackages = $allPackages
            Write-Output -InputObject "> All $($selectedPackages.Count) Remediation package(s) selected"
        }
        else {
            # Parse comma-separated numbers and ranges (e.g. "1,3-5,7")
            [System.Collections.Generic.List[int]]$selectedIndices = @()
            foreach ($part in ($selection -split ',')) {
                [string]$trimmed = $part -replace '\s', ''
                if ($trimmed -match '^\d+-\d+$') {
                    [int]$rangeStart = ($trimmed -split '-')[0]
                    [int]$rangeEnd = ($trimmed -split '-')[1]
                    for ([int]$r = $rangeStart; $r -le $rangeEnd; $r++) {
                        if ($r -ge 1 -and $r -le $allPackages.Count -and -not $selectedIndices.Contains($r)) {
                            $selectedIndices.Add($r)
                        }
                    }
                }
                elseif ($trimmed -match '^\d+$') {
                    [int]$num = [int]$trimmed
                    if ($num -ge 1 -and $num -le $allPackages.Count -and -not $selectedIndices.Contains($num)) {
                        $selectedIndices.Add($num)
                    }
                }
            }

            if ($selectedIndices.Count -eq 0) {
                Write-Output -InputObject "> No valid selection, script exiting"
                exit
            }

            [array]$selectedPackages = foreach ($idx in $selectedIndices) {
                $allPackages[$idx - 1]
            }
            Write-Output -InputObject "> $($selectedPackages.Count) Remediation package(s) selected"
        }
    }
    #endregion

    #region :: deviceHealthScriptRemediationDetails
    foreach ($deviceHealthPackage in $selectedPackages) {

        #region :: fetching device run states for remediation package
        Write-Output -InputObject "> processing '$($deviceHealthPackage.'Script package name')' [$($deviceHealthPackage.'Script package Id')]"
        try {
            [string]$mgGraphdeviceRunStatesUrl = "$mgGraphDeviceHealthScriptsUrl/$($deviceHealthPackage.'Script package Id')/deviceRunStates/" + '?$expand=*'
            $deviceHealthScriptProbe = Invoke-MgGraphRequest -Method GET -Uri $mgGraphdeviceRunStatesUrl

            # Check if paginated results exist via @odata.nextLink
            if ($deviceHealthScriptProbe.ContainsKey('@odata.nextLink')) {
                Write-Output -InputObject " *"
                [array]$deviceHealthScriptRows = (Invoke-MgGraphRequest -Method GET -Uri $mgGraphdeviceRunStatesUrl) | Get-MgGraphAllPages
            }
            else {
                [array]$deviceHealthScriptRows = $deviceHealthScriptProbe.value
            }
            Write-Output -InputObject "> total entries: $($deviceHealthScriptRows.Count)"
        }
        catch {
            $errMsg = $_.Exception.Message
            Write-Error -Message $errMsg
            exit
        }
        #endregion

        #region :: enumerating device run states for remediation package
        foreach ($deviceHealthScriptRow in $deviceHealthScriptRows) {

            #region :: enumerating OS build
            if ($deviceHealthScriptRow.managedDevice.osVersion -ne "") {
                [int]$osBuildNumber = $([version]$deviceHealthScriptRow.managedDevice.osVersion).Build
                if ($osBuildMap.ContainsKey($osBuildNumber)) {
                    [string]$osRelease = $osBuildMap[$osBuildNumber].Release
                    [string]$osBuildLabel = $osBuildMap[$osBuildNumber].Label
                }
                elseif ($osBuildNumber -gt $osBuildMapMax) {
                    [string]$osRelease = 'Future'
                    [string]$osBuildLabel = 'Future'
                }
                else {
                    [string]$osRelease = 'Unknown'
                    [string]$osBuildLabel = 'Unsupported'
                }
            }
            else {
                [string]$osRelease = 'Unknown'
                [string]$osBuildLabel = 'Unknown'
            }
            #endregion

            #region :: building object
            Write-Verbose -Message "Adding $($deviceHealthScriptRow.managedDevice.id) ($($deviceHealthScriptRow.managedDevice.deviceName)) to data collection"
            $deviceHealthScriptRemediationDetails.Add([PSCustomObject]@{
                "Script package name"               = $($deviceHealthPackage.'Script package name')
                "Device name"                       = $deviceHealthScriptRow.managedDevice.deviceName
                "Device Id"                         = $deviceHealthScriptRow.managedDevice.id
                "OS Release"                        = $osRelease
                "OS build"                          = $osBuildLabel
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
            })
            #endregion
        }
        #endregion
    }
    #endregion

    #region :: Select and export remediation details
    if ($($deviceHealthScriptRemediationDetails.Count) -ge 1) {

        # When using Grid View, allow interactive row selection; otherwise export all rows
        if ($UseGridView) {
            Write-Output -InputObject "Opening $($deviceHealthScriptRemediationDetails.Count) rows in Grid View"
            Write-Output -InputObject "> Select one or more rows from Remediation package details"
            try {
                [array]$selectedRemediationDetails = $deviceHealthScriptRemediationDetails | Out-GridView -Title "Remediation package details - $tenantDisplayName" -PassThru
            }
            catch {
                Write-Output -InputObject "> Out-GridView failed, exporting all rows instead"
                [array]$selectedRemediationDetails = @($deviceHealthScriptRemediationDetails)
            }
        }
        else {
            [array]$selectedRemediationDetails = @($deviceHealthScriptRemediationDetails)
        }

        if ($($selectedRemediationDetails.Count) -gt 0) {
            if ($($selectedRemediationDetails.Count) -eq 1) {
                Write-Output -InputObject "> $($selectedRemediationDetails.Count) row selected"
            }
            else {
                Write-Output -InputObject "> $($selectedRemediationDetails.Count) rows selected"
            }

            #region :: Exporting to CSV or HTML
            Write-Output -InputObject "Exporting selected rows to '$($ReportOutputType.ToUpper())'"
            Write-Output -InputObject "> processing $($selectedRemediationDetails.Count) rows"
            switch ($ReportOutputType) {
                "csv" {
                    Write-Verbose -Message "Exporting selected rows to 'CSV'"
                    $selectedRemediationDetails | Export-Csv -Path "$($ReportOutputFolder)\RemediationReport.csv" -Encoding "UTF8" -Delimiter ";" -NoTypeInformation
                }
                "html" {
                    Write-Verbose -Message "Exporting selected rows to 'HTML'"
                    $htmlTitle = "Remediation report - $tenantDisplayName"
                    $htmlPreContent = "<h1>Remediation report - $tenantDisplayName</h1><p id='TenantName'>Tenant: $tenantDisplayName</p><p id='Tenant ID'>TenantID: $TenantId</p><p id='Records'>Records exported: $($selectedRemediationDetails.Count)</p>"
                    $htmlPostContent = "<p id='CreationDate'>Creation Date: $(Get-Date)</p>"
                    $htmlCssUri = "./css/style.css"
                    $selectedRemediationDetails | ConvertTo-Html -As "Table" -Title $htmlTitle -PreContent $htmlPreContent -PostContent $htmlPostContent -CssUri $htmlCssUri | Out-File -FilePath "$($ReportOutputFolder)\RemediationReport.html" -Encoding "UTF8"
                    Write-Verbose -Message "Copying 'html stylesheet' file to output folder"
                    Copy-Item -Path $htmlCssUri -Destination $ReportOutputFolder -Force
                }
            }
            Write-Output -InputObject "> $($selectedRemediationDetails.Count) rows exported to '$($ReportOutputFolder)\RemediationReport.$($ReportOutputType.ToLower())'"
            #endregion
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
end {
    Write-Output -InputObject "Finishing up, please wait..."
    Write-Output -InputObject "Done - have a nice day!"
}
