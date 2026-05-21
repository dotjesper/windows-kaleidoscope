<#
.SYNOPSIS
    Collect and inventory browser extensions

.DESCRIPTION
    The detection script will collect and upload browser extension installed, to Log Analytics in Azure Monitor.
    Collecting browser extensions for the following browsers;
    - Microsoft Edge
    - Google Chrome
    - Mozilla Firefox

    Extensions are collected for all user profiles in browsers, and can result in extensions is reported multiple times due to the nature of the browsers handle extensions.
    The script will collect the following information for each extension;
    - Browser       : Browser name
    - Author        : Extension author
    - Name          : Extension name
    - Description   : Extension description
    - Version       : Extension version
    - Update URL    : Extension update URL
    - Path          : Extension path
    - Extension ID  : Extension ID
    - Source URI    : Extension URI (Firefox only)
    - Profile       : Browser Profile name
    - User          : User name
    - Computer      : Computer name

    Prerequisites:
    - A Log Analytics workspace is required (e.g., a tenant inventory workspace) to receive the collected data.
    - Replace the WorkspaceId and SharedKey parameter defaults with values from your Log Analytics workspace.
    - Use the -SkipUpload switch to run without sending data to Log Analytics.
    - See the README for instructions on obtaining WorkspaceId and SharedKey from your Log Analytics workspace.

.PARAMETER WorkspaceId
    Workspace ID for Log Analytics.

.PARAMETER SharedKey
    Shared Key for Log Analytics.

.PARAMETER TableName
    Custom table name in Log Analytics. The table will be created with a _CL suffix.

.PARAMETER SkipUpload
    Skip uploading data to Log Analytics and output collected data locally.

.EXAMPLE
    .\detect.ps1

    Collect and upload data to Log Analytics.

.EXAMPLE
    .\detect.ps1 -SkipUpload

    Skip uploading data to Log Analytics and output collected data locally.

.NOTES
    version: 1.4.0
    date: June 14, 2024
    license: MIT License

.LINK
    https://github.com/dotjesper/windows-kaleidoscope
#>

#requires -Version 5.1

[CmdletBinding()]
param (
    #variables
    [Parameter(Mandatory = $false, HelpMessage = 'Workspace ID for Log Analytics')]
    [string]$WorkspaceId = '[WorkspaceID]', # Replace with your Workspace ID

    [Parameter(Mandatory = $false, HelpMessage = 'Shared Key for Log Analytics')]
    [string]$SharedKey = '[Primary Key]', # Replace with your Primary Key

    [Parameter(Mandatory = $false, HelpMessage = 'Custom table name in Log Analytics')]
    [string]$TableName = 'browserExtensions', # Replace with your table name

    [Parameter(Mandatory = $false, HelpMessage = 'Skip uploading data to Log Analytics and output collected data locally')]
    [switch]$SkipUpload
)

begin {
    Set-StrictMode -Version Latest

    # variables :: Conditions
    [bool]$runScriptIn64bitPowerShell = $true
    [bool]$runUsingLoggedOnCredentials = $true

    # variables :: Environment
    $extensionCollection = [System.Collections.Generic.List[Object]]::new()
    [datetime]$scriptStartTime = (Get-Date).ToUniversalTime()

    #variables :: enable TLS 1.2 support
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    #region :: functions
    function Send-LogAnalyticsData {
        <#
       .SYNOPSIS
           Send log data to Azure Monitor by using the HTTP Data Collector API

       .DESCRIPTION
           This function use the HTTP Data Collector API to send log data to Azure Monitor from the REST API client.
           See https://learn.microsoft.com/azure/azure-monitor/logs/data-collector-api.
       #>
        [CmdletBinding()]
        #[OutputType ([string])]
        param (
            [Parameter(Mandatory = $true)]
            [string]$WorkspaceId,

            [Parameter(Mandatory = $true)]
            [string]$SharedKey,

            [Parameter(Mandatory = $true)]
            [array]$Body,

            [Parameter(Mandatory = $true)]
            [string]$TableName
        )
        begin {
            # setting method and content types
            [string]$method = 'POST'
            [string]$contentType = 'application/json'
            [string]$resource = '/api/logs'
            [string]$requestDate = [DateTime]::UtcNow.ToString('r')
        }
        process {
            # authorization signature settings
            [string]$xHeaders = 'x-ms-date:' + $requestDate
            [string]$stringToHash = $method + '`n' + $Body.Length + '`n' + $contentType + '`n' + $xHeaders + '`n' + $resource
            $bytesToHash = [Text.Encoding]::UTF8.GetBytes($stringToHash)
            $keyBytes = [Convert]::FromBase64String($SharedKey)
            $sha256 = New-Object System.Security.Cryptography.HMACSHA256
            $sha256.Key = $keyBytes
            $calculatedHash = $sha256.ComputeHash($bytesToHash)
            $sha256.Dispose()

            # encode signature and prepare authorization header
            [string]$encodedHash = [Convert]::ToBase64String($calculatedHash)
            [string]$signature = 'SharedKey {0}:{1}' -f $WorkspaceId, $encodedHash

            # uri settings
            [string]$apiUri = 'https://' + $WorkspaceId + '.ods.opinsights.azure.com' + $resource + '?api-version=2016-04-01'

            # validate payload size, must be less than 32Mb
            if ($Body.Length -gt (31.9 * 1024 * 1024)) {
                throw ('Payload size exceeds the maximum upload size of 32Mb pr. upload. Payload size: ' + ($Body.Length / 1024 / 1024).ToString('#.#') + 'Mb')
            }

            # log payload size in Kb for troubleshooting purposes
            [string]$payloadSize = $(($Body.Length / 1024).ToString('#.#'))
            Write-Verbose -Message "Payload size is $payloadSize Kb"

            # authorization header settings
            [hashtable]$requestHeaders = @{
                'Authorization'        = $signature
                'Log-Type'             = $TableName
                'x-ms-date'            = $requestDate
                'time-generated-field' = ''
            }

            #region :: posting data to log analytics
            try {
                [array]$webResponse = Invoke-WebRequest -Uri $apiUri -Method $method -ContentType $contentType -Headers $requestHeaders -Body $Body -UseBasicParsing -Verbose:$false
                return $($webResponse.StatusCode)
            }
            catch {
                [string]$errorMessage = $_.Exception.Message
                if ($_.Exception.Response) {
                    [string]$errorMessage = "$errorMessage (HTTP $($_.Exception.Response.StatusCode.value__))"
                }
                Write-Error -Message $errorMessage
            }
            #endregion
        }
    }
    #endregion
}
process {
    #region :: Check conditions
    if ($runScriptIn64bitPowerShell -eq $true -and $([System.Environment]::Is64BitProcess) -eq $false) {
        Write-Error -Message 'Windows PowerShell 64-bit is required.' -Category 'ResourceUnavailable' -ErrorId 'B001'
        exit 1
    }
    if ($runUsingLoggedOnCredentials -eq $true -and $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name -eq 'NT AUTHORITY\SYSTEM')) {
        Write-Error -Message 'Script is running as SYSTEM. Please run the script as user.' -Category 'ResourceUnavailable' -ErrorId 'B002'
        exit 1
    }
    #endregion

    #region :: collect Microsoft Edge extension for all profiles
    try {
        # determine Microsoft Edge profiles
        if (-not (Test-Path -Path 'Registry::HKEY_CURRENT_USER\Software\Microsoft\Edge\Profiles' -ErrorAction SilentlyContinue)) {
            Write-Verbose -Message 'Microsoft Edge not present.'
        }
        else {
            [array]$edgeProfiles = Get-ItemProperty -Path 'Registry::HKEY_CURRENT_USER\Software\Microsoft\Edge\Profiles\*' | Select-Object 'pschildname', 'Path', 'ShortcutName'
            Write-Verbose -Message "$($edgeProfiles.Count) Microsoft Edge profiles found for user"

            foreach ($edgeProfile in $edgeProfiles) {
                if ([string]::IsNullOrEmpty($edgeProfile.Path)) {
                    $edgeProfile.Path = "$($env:LOCALAPPDATA)\Microsoft\Edge\User Data\$($edgeProfile.PSChildName)"
                }
                Write-Verbose -Message "Microsoft Edge profile: $($edgeProfile.PSChildName) ($($edgeProfile.Path))"

                # collect Microsoft Edge extension
                [array]$edgeExtensions = Get-ChildItem -Path "$($edgeProfile.Path)\Extensions" -Filter 'manifest.json' -Recurse -ErrorAction SilentlyContinue
                Write-Verbose -Message "$($edgeExtensions.Count) Microsoft Edge extensions found for profile: $($edgeProfile.PSChildName)"
                foreach ($edgeExtension in $edgeExtensions) {
                    [PSCustomObject]$edgeExtensionInfo = Get-Content -Path "$($edgeExtension.Fullname)" -Raw | ConvertFrom-Json | Select-Object 'Author', 'Name', 'Description', 'Version', 'update_url'

                    # collect locale strings
                    Write-Verbose -Message 'Checking for locale file'
                    Write-Verbose -Message "$($edgeExtension.Directory)\_locales\en\messages.json"
                    if (Test-Path -Path "$($edgeExtension.Directory)\_locales\en\messages.json" -PathType 'Leaf') {
                        Write-Verbose -Message '** locale file found **'
                        $localeName = $($edgeExtensionInfo.Name).Replace('MSG_', '').Replace('__', '')
                        $localeDesc = $($edgeExtensionInfo.Description).Replace('MSG_', '').Replace('__', '')

                        # read locale strings from message.json
                        [PSCustomObject]$localeData = Get-Content -Path "$($edgeExtension.Directory)\_locales\en\messages.json" -Raw | ConvertFrom-Json
                        Write-Verbose -Message 'Replacing Name and Description fields from locale file'
                        $edgeExtensionInfo.Name = $($localeData.$localeName.message)
                        $edgeExtensionInfo.Description = $($localeData.$localeDesc.message)
                    }
                    else {
                        Write-Verbose -Message '** locale file not present **'
                    }

                    # log extension information and add to collection
                    Write-Verbose -Message "Microsoft Edge extension: $($edgeExtensionInfo.Name) v$($edgeExtensionInfo.Version) [$($($edgeExtension.Directory.ToString()).Split('\')[-2])]"
                    $edgeExtensionSet = [PSCustomObject]@{
                        'browser'     = 'Edge'
                        'name'        = [string]$($edgeExtensionInfo.Name)
                        'author'      = [string]$($edgeExtensionInfo.Author)
                        'description' = [string]$($edgeExtensionInfo.Description)
                        'version'     = [string]$($edgeExtensionInfo.Version)
                        'update-url'  = [string]$($edgeExtensionInfo.update_url)
                        'path'        = [string]$($edgeExtension.Directory)
                        'extensionId' = [string]$($($edgeExtension.Directory.ToString()).Split('\')[-2])
                        'user'        = [string]$($env:USERNAME)
                        'computer'    = [string]$($env:COMPUTERNAME)
                        'profile'     = [string]$($edgeProfile.ShortcutName)
                    }
                    $extensionCollection.Add($edgeExtensionSet)
                }
            }
        }
    }
    catch {
        $errorMessage = $_.Exception.Message
        Write-Error -Message "Failed to process Microsoft Edge extensions - $errorMessage"
    }
    finally {}
    #endregion

    #region :: collect Google Chrome extension for all profiles
    try {
        # determine Google Chrome profiles from local state
        [string]$chromeStatePath = "$env:LOCALAPPDATA\Google\Chrome\User Data\Local State"
        if (Test-Path -Path "$chromeStatePath" -PathType 'Leaf') {
            $chromeState = Get-Content -Path $chromeStatePath -Raw
            $chromeState = ConvertFrom-Json -InputObject $chromeState
            [array]$chromeProfiles = $chromeState.Profile.info_cache | Get-Member -MemberType 'NoteProperty'
            Write-Verbose -Message "$($chromeProfiles.Count) Google Chrome profiles found for user"
            foreach ($chromeProfile in $chromeProfiles) {
                Write-Verbose -Message "Google Chrome profile: $($chromeProfile.Name) ($($env:LOCALAPPDATA)\Google\Chrome\User Data\$($chromeProfile.Name))"

                # collect Google Chrome extension
                [array]$chromeExtensions = Get-ChildItem -Path "$($env:LOCALAPPDATA)\Google\Chrome\User Data\$($chromeProfile.Name)\Extensions" -Filter 'manifest.json' -Recurse -ErrorAction SilentlyContinue
                Write-Verbose -Message "$($chromeExtensions.Count) Google Chrome extensions found for profile: $($chromeProfile.Name)"
                foreach ($chromeExtension in $chromeExtensions) {
                    [PSCustomObject]$chromeExtensionInfo = Get-Content -Path "$($chromeExtension.Fullname)" -Raw | ConvertFrom-Json | Select-Object 'Author', 'Name', 'Description', 'Version', 'update_url'

                    # collect locale strings
                    Write-Verbose -Message 'Checking for locale file'
                    Write-Verbose -Message "$($chromeExtension.Directory)\_locales\en\messages.json"
                    if (Test-Path -Path "$($chromeExtension.Directory)\_locales\en\messages.json" -PathType 'Leaf') {
                        Write-Verbose -Message '** locale file found **'
                        $localeName = $($chromeExtensionInfo.Name).Replace('MSG_', '').Replace('__', '')
                        $localeDesc = $($chromeExtensionInfo.Description).Replace('MSG_', '').Replace('__', '')

                        # read locale strings from message.json
                        [PSCustomObject]$localeData = Get-Content -Path "$($chromeExtension.Directory)\_locales\en\messages.json" -Raw | ConvertFrom-Json
                        Write-Verbose -Message 'Replacing Name and Description fields from locale file'
                        $chromeExtensionInfo.Name = $($localeData.$localeName.message)
                        $chromeExtensionInfo.Description = $($localeData.$localeDesc.message)
                    }
                    else {
                        Write-Verbose -Message '** locale file not present **'
                    }

                    # log extension information and add to collection
                    Write-Verbose -Message "Google Chrome extension: $($chromeExtensionInfo.Name) v$($chromeExtensionInfo.Version) [$($($chromeExtension.Directory.ToString()).Split('\')[-2])]"
                    $chromeExtensionSet = [PSCustomObject]@{
                        'browser'     = 'Chrome'
                        'name'        = [string]$($chromeExtensionInfo.Name)
                        'author'      = [string]$($chromeExtensionInfo.Author)
                        'description' = [string]$($chromeExtensionInfo.Description)
                        'version'     = [string]$($chromeExtensionInfo.Version)
                        'update-url'  = [string]$($chromeExtensionInfo.update_url)
                        'path'        = [string]$($chromeExtension.Directory)
                        'extensionId' = [string]$($($chromeExtension.Directory.ToString()).Split('\')[-2])
                        'user'        = [string]$($env:USERNAME)
                        'computer'    = [string]$($env:COMPUTERNAME)
                        'profile'     = [string]$($chromeState.Profile.info_cache.$($chromeProfile.Name).shortcut_name)
                    }
                    $extensionCollection.Add($chromeExtensionSet)
                }
            }
        }
        else {
            Write-Verbose -Message 'Google Chrome not present.'
        }
    }
    catch {
        $errorMessage = $_.Exception.Message
        Write-Error -Message "Failed to process Google Chrome extensions - $errorMessage"
    }
    finally {}
    #endregion

    #region :: collect Mozilla Firefox extension for all profiles
    try {
        #region :: determine Firefox profiles from local state
        [string]$firefoxStatePath = "$env:APPDATA\Mozilla\Firefox\Profiles"
        if (Test-Path -Path "$firefoxStatePath" -PathType 'Container') {
            $firefoxProfiles = Get-ChildItem -Path "$firefoxStatePath" -Directory
            Write-Verbose -Message "$($firefoxProfiles.Count) Firefox profiles found for user"
            foreach ($firefoxProfile in $firefoxProfiles) {
                Write-Verbose -Message "Firefox profile: $($firefoxProfile.Name) ($($firefoxProfile.FullName))"

                # collect Firefox extension
                if (Test-Path -Path "$($firefoxProfile.FullName)\extensions.json" -PathType 'Leaf') {
                    Write-Verbose -Message 'Firefox extensions.json found for profile'
                    [array]$firefoxAddons = (Get-Content -Path "$($firefoxProfile.FullName)\extensions.json" -Raw | ConvertFrom-Json).addons

                    # collect locale strings for Firefox extensions
                    Write-Verbose -Message "$($firefoxAddons.Count) Firefox extensions found for profile"
                    foreach ($firefoxAddon in $firefoxAddons) {
                        Write-Verbose -Message "Firefox extension: $($firefoxAddon.defaultLocale.name) v$($firefoxAddon.version)"
                        $firefoxExtensionSet = [PSCustomObject]@{
                            'browser'     = 'Firefox'
                            'name'        = [string]$($firefoxAddon.defaultLocale.name)
                            'author'      = [string]$($firefoxAddon.defaultLocale.creator)
                            'description' = [string]$($firefoxAddon.defaultLocale.description)
                            'version'     = [string]$($firefoxAddon.version)
                            'update-url'  = [string]$($firefoxAddon.updateURL)
                            'path'        = [string]$($firefoxProfile.FullName)
                            'source-uri'  = [string]$($firefoxAddon.sourceURI)
                            'user'        = [string]$($env:USERNAME)
                            'computer'    = [string]$($env:COMPUTERNAME)
                            'profile'     = [string]$($firefoxProfile.Name)
                        }
                        $extensionCollection.Add($firefoxExtensionSet)
                    }
                }
                else {
                    Write-Verbose -Message "No Firefox extensions.json found for profile: $($firefoxProfile.Name)"
                }
            }
        }
        else {
            Write-Verbose -Message 'Mozilla Firefox not present.'
        }
        #endregion
    }
    catch {
        $errorMessage = $_.Exception.Message
        Write-Error -Message "Failed to process Firefox extensions - $errorMessage"
    }
    finally {}
    #endregion

    #region :: processing log data
    if ($extensionCollection.Count -gt 0) {
        if ($SkipUpload) {
            # return data to output
            [string]$elapsedTime = ('{0:00.000}' -f ((Get-Date).ToUniversalTime() - $scriptStartTime).TotalSeconds) -replace ',', '.'
            Write-Output -InputObject "[$elapsedTime] Running locally without sending data to Log Analytics."
            Write-Output -InputObject "[$elapsedTime] Collected information for $($extensionCollection.Count) extensions."
            Write-Output -InputObject $extensionCollection
            exit 0
        }
        else {
            try {
                # send data to log analytics API uri
                [int]$extensionCount = $extensionCollection.Count
                [string]$extensionCollectionJson = ConvertTo-Json -InputObject $extensionCollection
                [string]$sendResponse = Send-LogAnalyticsData -WorkspaceId $WorkspaceId -SharedKey $SharedKey -Body ([System.Text.Encoding]::UTF8.GetBytes($extensionCollectionJson)) -TableName $TableName
                if ($sendResponse -eq '200') {
                    [string]$outputMessage = "Successfully uploaded information for $($extensionCount) extensions."
                }
                else {
                    [string]$outputMessage = "Failed to upload information for $($extensionCount) extensions."
                }

                # send result to output
                [string]$elapsedTime = ('{0:00.000}' -f ((Get-Date).ToUniversalTime() - $scriptStartTime).TotalSeconds) -replace ',', '.'
                Write-Output -InputObject "[$elapsedTime] $outputMessage"
                exit 0
            }
            catch {
                $errorMessage = $_.Exception.Message
                Write-Error -Message $errorMessage -Category 'SyntaxError' -ErrorId 'C001'
                exit 1
            }
            finally {}
        }
    }
    else {
        [string]$elapsedTime = ('{0:00.000}' -f ((Get-Date).ToUniversalTime() - $scriptStartTime).TotalSeconds) -replace ',', '.'
        Write-Output -InputObject "[$elapsedTime] No extensions found."
        exit 0
    }
    #endregion
}
end {}
