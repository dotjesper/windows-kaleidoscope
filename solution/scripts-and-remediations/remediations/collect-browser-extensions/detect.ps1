#requires -Version 5.1
<#
.SYNOPSIS
    Collect and inventory browser extensions,
.DESCRIPTION
    The detection script will collect and upload browser extension installed, to Log Analytics in Azure Monitor.
    Collecting browser extensions for the follwoig browsers;
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
.PARAMETER workspaceId
    Workspace ID for Log Analytics.
.PARAMETER sharedKey
    Shared Key for Log Analytics.
.PARAMETER logName
    Log name for Log Analytics.
.PARAMETER logLocally
    Log locally without sending data to Log Analytics.
.EXAMPLE
    Collect and upload data to Log Analytics.
    .\detect.ps1
.EXAMPLE
    Log locally without sending data to Log Analytics.
    .\detect.ps1 -logLocally
.NOTES
    version: 1.3.1.8
    date: Juni 14, 2024
    license: MIT License
.LINK
    [Jesper on Bluesky](https://bsky.app/profile/dotjesper.bsky.social "Jesper on Bluesky")
    [Jesper on GitHub](https://github.com/dotjesper/ "Jesper on GitHub")
#>
[CmdletBinding()]
param (
    #variables
    [Parameter(Mandatory = $false, HelpMessage = "Workspace ID for Log Analytics")]
    [string]$workspaceId = "[WorkspaceID]", # Replace with your Workspace ID
    [Parameter(Mandatory = $false, HelpMessage = "Shared Key for Log Analytics")]
    [string]$sharedKey = "[Primary Key]", # Replace with your Primary Key
    [Parameter(Mandatory = $false, HelpMessage = "Log name for Log Analytics")]
    [string]$logName = "browserExtensions", # Replace with your Log namne
    [Parameter(Mandatory = $false, HelpMessage = "Log locally without sending data to Log Analytics")]
    [switch]$logLocally
)
begin {
    #variables :: conditions
    [bool]$runScriptIn64bitPowerShell = $true
    [bool]$runUsingLoggedOnCredentials = $true
    #variables :: environment
    $extensionCollection = [System.Collections.Generic.List[Object]]::new()
    #variables :: enable TLS 1.2 support
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    #region :: functions
    function Send-LogAnalyticsData () {
        <#
       .SYNOPSIS
           Send log data to Azure Monitor by using the HTTP Data Collector API
       .DESCRIPTION
           This function use the HTTP Data Collector API to send log data to Azure Monitor from the REST API client.
           See https://docs.microsoft.com/en-us/azure/azure-monitor/logs/data-collector-api.
       .NOTES
       #>
        [CmdletBinding()]
        #[OutputType ([string])]
        param (
            [Parameter(Mandatory = $true)]
            [string]$workspaceId,
            [Parameter(Mandatory = $true)]
            [string]$sharedKey,
            [Parameter(Mandatory = $true)]
            [array]$body,
            [Parameter(Mandatory = $true)]
            [string]$logName
        )
        begin {
            #setting method and content types
            [string]$method = "POST"
            [string]$contentType = "application/json"
            [string]$resource = "/api/logs"
            [string]$date = [DateTime]::UtcNow.ToString("r")
        }
        process {
            #authorization signature settings
            $xHeaders = "x-ms-date:" + $date
            $stringToHash = $method + "`n" + $body.Length + "`n" + $contentType + "`n" + $xHeaders + "`n" + $resource
            $bytesToHash = [Text.Encoding]::UTF8.GetBytes($stringToHash)
            $keyBytes = [Convert]::FromBase64String($sharedKey)
            $sha256 = New-Object System.Security.Cryptography.HMACSHA256
            $sha256.Key = $keyBytes
            $calculatedHash = $sha256.ComputeHash($bytesToHash)
            $encodedHash = [Convert]::ToBase64String($calculatedHash)
            $signature = 'SharedKey {0}:{1}' -f $workspaceId, $encodedHash
            #uri settings
            $uri = "https://" + $workspaceId + ".ods.opinsights.azure.com" + $resource + "?api-version=2016-04-01"
            #validate payload size, must be less than 32Mb
            if ($body.Length -gt (31.9 * 1024 * 1024)) {
                throw ("Payload size exceeds the maximum upload size of 32Mb pr. upload. Payload size: " + ($body.Length / 1024 / 1024).ToString("#.#") + "Mb")
            }
            $payloadsize = $(($body.Length / 1024).ToString("#.#"))
            Write-Verbose -Message "Payload size is $payloadsize Kb"
            #authorization header settings
            $headers = @{
                "Authorization"        = $signature;
                "Log-Type"             = $logName;
                "x-ms-date"            = $date;
                "time-generated-field" = "";
            }
            #region :: posting data to log analytics
            try {
                [array]$response = Invoke-WebRequest -Uri $uri -Method $method -ContentType $contentType -Headers $headers -Body $body -UseBasicParsing -Verbose:$false
                #[string]$statusmessage = "$($response.StatusCode) : $($payloadsize)"
                return $($response.StatusCode)
            }
            catch {
                $errMsg = $_.Exception.Message
                Write-Error -Message $errMsg
            }
            #endregion
        }
        end {}
    }
    #endregion
}
process {
    #region :: check conditions
    if ($runScriptIn64bitPowerShell -eq $true -and $([System.Environment]::Is64BitProcess) -eq $false) {
        Write-Error -Message "Windows PowerShell 64-bit is requered." -Category "ResourceUnavailable" -ErrorId "B001"
        exit 1
    }
    if ($runUsingLoggedOnCredentials -eq $true -and $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name -eq "NT AUTHORITY\SYSTEM")) {
        Write-Error -Message "Script is running as SYSTEM. Please run the script as user." -Category "ResourceUnavailable" -ErrorId "B002"
        exit 1
    }
    #endregion
    #region :: collect Microsoft Edge extension for all profiles
    try {
        #region :: determine Microsoft Edge profiles
        [array]$edgeProfiles = Get-ItemProperty -Path "Registry::HKEY_CURRENT_USER\Software\Microsoft\Edge\Profiles\*" | Select-Object "pschildname", "Path", "ShortcutName"
        Write-Verbose -Message "$($edgeProfiles.Count) Microsoft Edge profiles found for user"
        #endregion
        foreach ($edgeProfile in $edgeProfiles) {
            if ([string]::IsNullOrEmpty($edgeProfile.Path)) {
                $edgeProfile.Path = "$($env:LOCALAPPDATA)\Microsoft\Edge\User Data\$($edgeProfile.PSChildName)"
            }
            Write-Verbose -Message "Microsoft Edge profile name: $($edgeProfile.PSChildName)"
            Write-Verbose -Message "Microsoft Edge profile path: $($edgeProfile.Path)"
            Write-Verbose -Message "Microsoft Edge profile Shortcut name: $($edgeProfile.ShortcutName)"
            #region :: collect Microsoft Edge extension
            [array]$edgeExtensions = Get-ChildItem -Path "$($edgeProfile.Path)\Extensions" -Filter "manifest.json" -Recurse
            Write-Verbose -Message "$($edgeExtensions.Count) Microsoft Edge extensions found for profile: $($edgeProfile.PSChildName)"
            foreach ($edgeExtension in $edgeExtensions) {
                [PSCustomObject]$edgeExtensionInfo = Get-Content -Path "$($edgeExtension.Fullname)" -Raw | ConvertFrom-Json | Select-Object "Author", "Name", "Description", "Version", "update_url"
                #region :: locale strings
                Write-Verbose -Message "Checking for locale file"
                Write-Verbose -Message "$($edgeExtension.Directory)\_locales\en\messages.json"
                if (Test-Path -Path "$($edgeExtension.Directory)\_locales\en\messages.json" -PathType "Leaf") {
                    Write-Verbose -Message "** locale file found **"
                    $localeName = $($edgeExtensionInfo.Name).Replace("MSG_", "").Replace("__", "")
                    $localeDesc = $($edgeExtensionInfo.Description).Replace("MSG_", "").Replace("__", "")
                    #Read locale strings from message.json
                    $locale = Get-Content -Path "$($edgeExtension.Directory)\_locales\en\messages.json" -Raw | ConvertFrom-Json
                    Write-Verbose -Message "Replacing Name and Description fields from locale file"
                    $edgeExtensionInfo.Name = $($locale.$localeName.message)
                    $edgeExtensionInfo.Description = $($locale.$localeDesc.message)
                }
                else {
                    Write-Verbose -Message "** locale file not present **"
                }
                #endregion
                Write-Verbose -Message "Microsoft Edge extension name: $($edgeExtensionInfo.Name)"
                Write-Verbose -Message "Microsoft Edge extension author: $($edgeExtensionInfo.Author)"
                Write-Verbose -Message "Microsoft Edge extension description: $($edgeExtensionInfo.Description)"
                Write-Verbose -Message "Microsoft Edge extension version: $($edgeExtensionInfo.Version)"
                Write-Verbose -Message "Microsoft Edge extension update URL: $($edgeExtensionInfo.update_url)"
                Write-Verbose -Message "Microsoft Edge extension path: $($edgeExtension.Directory)"
                Write-Verbose -Message "Microsoft Edge extension Id: $extensionId"
                Write-Verbose -Message "Microsoft Edge extension Id: $($($edgeExtension.Directory.ToString()).Split("\")[-2])"
                $edgeExtensionSet = [PSCustomObject]@{
                    "browser"     = "Edge"
                    "name"        = [string]$($edgeExtensionInfo.Name)
                    "author"      = [string]$($edgeExtensionInfo.Author)
                    "description" = [string]$($edgeExtensionInfo.Description)
                    "version"     = [string]$($edgeExtensionInfo.Version)
                    "update-url"  = [string]$($edgeExtensionInfo.update_url)
                    "path"        = [string]$($edgeExtension.Directory)
                    "extensionId" = [string]$($($edgeExtension.Directory.ToString()).Split("\")[-2])
                    "user"        = [string]$($env:USERNAME)
                    "computer"    = [string]$($env:COMPUTERNAME)
                    "profile"     = [string]$($edgeProfile.ShortcutName)
                }
                $extensionCollection.Add($edgeExtensionSet)
            }
            #endregion
        }
    }
    catch {
        $errMsg = $_.Exception.Message
        Write-Error -Message "Failed to process Microsoft Edge extensions - $errMsg"
        exit 1
    }
    finally {}
    #endregion
    #region :: collect Google Chrome extension for all profiles
    try {
        # #region :: determine Google Chrome profiles from local state
        [string]$statePath = "$env:LOCALAPPDATA\Google\Chrome\User Data\Local State"
        if (Test-Path -Path "$statePath" -PathType "Leaf") {
            $state = Get-Content -Path $statePath -Raw
            $state = ConvertFrom-Json -InputObject $state
            [array]$chromeProfiles = $state.Profile.info_cache | Get-Member -MemberType "NoteProperty"
            Write-Verbose -Message "$($chromeProfiles.Count) Google Chrome profiles found for user"
            foreach ($chromeProfile in $chromeProfiles) {
                Write-Verbose -Message "Google Chrome profile name: $($chromeProfile.Name)"
                Write-Verbose -Message "Google Chrome profile path: $($env:LOCALAPPDATA)\Google\Chrome\User Data\$($chromeProfile.Name)"
                Write-Verbose -Message "Google Chrome profile Shortcut name: $($state.Profile.info_cache.$($chromeProfile.Name).shortcut_name)"
                #region :: collect Google Chrome extension
                [array]$chromeExtensions = Get-ChildItem -Path "$($env:LOCALAPPDATA)\Google\Chrome\User Data\$($chromeProfile.Name)\Extensions" -Filter "manifest.json" -Recurse
                Write-Verbose -Message "$($chromeExtensions.Count) Google Chrome extensions found for profile: $($chromeProfile.Name)"
                foreach ($chromeExtension in $chromeExtensions) {
                    [PSCustomObject]$chromeExtensionInfo = Get-Content -Path "$($chromeExtension.Fullname)" -Raw | ConvertFrom-Json | Select-Object "Author", "Name", "Description", "Version", "update_url"
                    #region :: locale strings
                    Write-Verbose -Message "Checking for locale file"
                    Write-Verbose -Message "$($chromeExtension.Directory)\_locales\en\messages.json"
                    if (Test-Path -Path "$($chromeExtension.Directory)\_locales\en\messages.json" -PathType "Leaf") {
                        Write-Verbose -Message "** locale file found **"
                        $localeName = $($chromeExtensionInfo.Name).Replace("MSG_", "").Replace("__", "")
                        $localeDesc = $($chromeExtensionInfo.Description).Replace("MSG_", "").Replace("__", "")
                        #Read locale strings from message.json
                        $locale = Get-Content -Path "$($chromeExtension.Directory)\_locales\en\messages.json" -Raw | ConvertFrom-Json
                        Write-Verbose -Message "Replacing Name and Description fields from locale file"
                        $chromeExtensionInfo.Name = $($locale.$localeName.message)
                        $chromeExtensionInfo.Description = $($locale.$localeDesc.message)
                    }
                    else {
                        Write-Verbose -Message "** locale file not present **"
                    }
                    #endregion
                    Write-Verbose -Message "Google Chrome extension name: $($chromeExtensionInfo.Name)"
                    Write-Verbose -Message "Google Chrome extension author: $($chromeExtensionInfo.Author)"
                    Write-Verbose -Message "Google Chrome extension description: $($chromeExtensionInfo.Description)"
                    Write-Verbose -Message "Google Chrome extension version: $($chromeExtensionInfo.Version)"
                    Write-Verbose -Message "Google Chrome extension update URL: $($chromeExtensionInfo.update_url)"
                    Write-Verbose -Message "Google Chrome extension path: $($chromeExtension.Directory)"
                    Write-Verbose -Message "Google Chrome extension Id: $($($chromeExtension.Directory.ToString()).Split("\")[-2])"
                    $chromeExtensionSet = [PSCustomObject]@{
                        "browser"     = "Chrome"
                        "name"        = [string]$($chromeExtensionInfo.Name)
                        "author"      = [string]$($chromeExtensionInfo.Author)
                        "description" = [string]$($chromeExtensionInfo.Description)
                        "version"     = [string]$($chromeExtensionInfo.Version)
                        "update-url"  = [string]$($chromeExtensionInfo.update_url)
                        "path"        = [string]$($chromeExtension.Directory)
                        "extensionId" = [string]$($($chromeExtension.Directory.ToString()).Split("\")[-2])
                        "user"        = [string]$($env:USERNAME)
                        "computer"    = [string]$($env:COMPUTERNAME)
                        "profile"     = [string]$($state.Profile.info_cache.$($chromeProfile.Name).shortcut_name)
                    }
                    $extensionCollection.Add($chromeExtensionSet)
                }
                #endregion
            }
        }
        else {
            Write-Verbose -Message "Google Chrome not present."
        }
    }
    catch {
        $errMsg = $_.Exception.Message
        Write-Error -Message "Failed to process Google Chrome extensions - $errMsg"
        exit 1
    }
    finally {}
    #endregion
    #region :: collect Mozilla Firefox extension for all profiles
    try {
        #region :: determine Firefix profiles from local state
        [string]$statePath = "$env:APPDATA\Mozilla\Firefox\Profiles"
        if (Test-Path -Path "$statePath" -PathType "Container") {
            $firefoxProfiles = Get-ChildItem -Path "$statePath" -Directory
            Write-Verbose -Message "$($firefoxProfiles.Count) Firefox profiles found for user"
            foreach ($firefoxProfile in $firefoxProfiles) {
                Write-Verbose -Message "Firefox profile name: $($firefoxProfile.Name)"
                Write-Verbose -Message "Firefox profile path: $($firefoxProfile.FullName)"
                #region :: collect Firefox extension
                [array]$firefoxExtensions = Get-ChildItem -Path "$($firefoxProfile.FullName)\extensions" -Filter "*.xpi" -Recurse
                Write-Verbose -Message "$($firefoxExtensions.Count) Firefox extension (.xpi) files found for profile"
                if (Test-Path -Path "$($firefoxProfile.FullName)\extensions.json" -PathType Leaf) {
                    Write-Verbose -Message "Firefox extensions.json found for profile"
                    [array]$firefoxAddons = (Get-Content -Path "$($firefoxProfile.FullName)\extensions.json" -Raw | ConvertFrom-Json).addons
                    Write-Verbose -Message "$($firefoxAddons.Count) Firefox extensions found for profile"
                    foreach ($firefoxAddon in $firefoxAddons) {
                        [PSCustomObject]$firefoxAddons = $firefoxAddon
                        Write-Verbose -Message "Firefox extension name: $($firefoxAddons.defaultLocale.name)"
                        Write-Verbose -Message "Firefox extension creator: $($firefoxAddons.defaultLocale.creator)"
                        Write-Verbose -Message "Firefox extension description: $($firefoxAddons.defaultLocale.description)"
                        Write-Verbose -Message "Firefox extension version: $($firefoxAddons.version)"
                        Write-Verbose -Message "Firefox extension source URI: $($firefoxAddons.sourceURI)"
                        Write-Verbose -Message "Firefox extension update URL: $($firefoxAddons.updateURL)"
                        $firefoxExtensionSet = [PSCustomObject]@{
                            "browser"     = "Firefox"
                            "name"        = [string]$($firefoxAddons.defaultLocale.name)
                            "author"      = [string]$($firefoxAddons.defaultLocale.creator)
                            "description" = [string]$($firefoxAddons.defaultLocale.description)
                            "version"     = [string]$($firefoxAddons.version)
                            "update-url"  = [string]$($firefoxAddons.updateURL)
                            "path"        = [string]$($firefoxProfile.FullName)
                            "source-uri"  = [string]$($firefoxAddons.sourceURI)
                            "user"        = [string]$($env:USERNAME)
                            "computer"    = [string]$($env:COMPUTERNAME)
                            "profile"     = [string]$($firefoxProfile.Name)
                        }
                        $extensionCollection.Add($firefoxExtensionSet)
                    }
                }
                else {
                    Write-Verbose -Message "No Firefox extensions.json found for profile: $($firefoxProfile.Name)"
                }
                #endregion
            }
        }
        else {
            Write-Verbose -Message "Mozilla Firefox not present."
        }
        #endregion
    }
    catch {
        $errMsg = $_.Exception.Message
        Write-Error -Message "Failed to process Firefox extensions - $errMsg"
        exit 1
    }
    finally {}
    #endregion
    #region :: processing log data
    if ($extensionCollection.Count -gt 0) {
        if ($logLocally) {
            #region :: return data to output
            Write-Output -InputObject "Running locally without sending data to Log Analytics."
            Write-Output -InputObject "Collected information for $($extensionCollection.Count) extensions."
            Write-Output -InputObject $extensionCollection
            exit 0
            #endregion
        }
        else {
            try {
                #region :: send data to log analytics API uri
                [string]$extensionCollection = ConvertTo-Json -InputObject $extensionCollection
                [string]$sendResponse = Send-LogAnalyticsData -workspaceId $workspaceId -sharedKey $sharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($extensionCollection)) -logName $logName
                if ($sendResponse -eq "200") {
                    $outputMessage = "Succesfully uploaded information for $($extensionCollection.Count) extensions."
                }
                else {
                    $outputMessage = "Failed to upload information for $($extensionCollection.Count) extensions."
                }
                #endregion
                #region :: send result to output
                Write-Output -InputObject $outputMessage
                exit 0
                #endregion
            }
            catch {
                $errMsg = $_.Exception.Message
                Write-Error -Message $errMsg -Category "SyntaxError" -ErrorId "C001"
                exit 1
            }
            finally {}
        }
    }
    else {
        Write-Output -InputObject "No extensions found."
        exit 0
    }
    #endregion
}
end {}
