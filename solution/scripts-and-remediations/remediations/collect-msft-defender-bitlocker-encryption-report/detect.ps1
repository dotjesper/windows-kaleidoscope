<#
.SYNOPSIS
    Collect Microsoft Defender BitLocker status

.DESCRIPTION
    The detection script will collect Microsoft Defender BitLocker status and upload state for all volumes to Log Analytics in Azure Monitor.

.PARAMETER WorkspaceId
    Log Analytics Workspace ID. Replace with your Workspace ID.

.PARAMETER SharedKey
    Log Analytics Primary Key. Replace with your Primary Key.

.PARAMETER TableName
    Custom table name in Log Analytics. Default is MsftDefenderBitlocker.

.PARAMETER SkipUpload
    Skip uploading data to Log Analytics and output collected data locally.

.EXAMPLE
    .\detect.ps1

.NOTES
    version: 1.1.0
    date: August 26, 2023
    license: MIT License

.LINK
    https://github.com/dotjesper/windows-kaleidoscope
#>

#requires -Version 5.1
#requires -RunAsAdministrator

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false, HelpMessage = 'Workspace ID for Log Analytics')]
    [string]$WorkspaceId = '[WorkspaceID]', # Replace with your Workspace ID

    [Parameter(Mandatory = $false, HelpMessage = 'Shared Key for Log Analytics')]
    [string]$SharedKey = '[Primary Key]', # Replace with your Primary Key

    [Parameter(Mandatory = $false, HelpMessage = 'Custom table name in Log Analytics')]
    [string]$TableName = 'MsftDefenderBitlocker', # Replace with your table name

    [Parameter(Mandatory = $false, HelpMessage = 'Skip uploading data to Log Analytics and output collected data locally')]
    [switch]$SkipUpload
)

begin {
    Set-StrictMode -Version Latest

    # variables :: Conditions
    [bool]$runScriptIn64bitPowerShell = $true

    # variables :: Environment
    $BitLockerVolumeCollection = [System.Collections.Generic.List[Object]]::new()
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
            [string]$method = 'POST'
            [string]$contentType = 'application/json'
            [string]$resource = '/api/logs'
            [string]$date = [DateTime]::UtcNow.ToString('r')
        }
        process {
            #authorization signature settings
            $xHeaders = 'x-ms-date:' + $date
            $stringToHash = $method + '`n' + $body.Length + '`n' + $contentType + '`n' + $xHeaders + '`n' + $resource
            $bytesToHash = [Text.Encoding]::UTF8.GetBytes($stringToHash)
            $keyBytes = [Convert]::FromBase64String($sharedKey)
            $sha256 = New-Object System.Security.Cryptography.HMACSHA256
            $sha256.Key = $keyBytes
            $calculatedHash = $sha256.ComputeHash($bytesToHash)
            $encodedHash = [Convert]::ToBase64String($calculatedHash)
            $signature = 'SharedKey {0}:{1}' -f $workspaceId, $encodedHash
            #uri settings
            $uri = 'https://' + $workspaceId + '.ods.opinsights.azure.com' + $resource + '?api-version=2016-04-01'
            #validate payload size, must be less than 32Mb
            if ($body.Length -gt (31.9 * 1024 * 1024)) {
                throw ('Payload size exceeds the maximum upload size of 32Mb pr. upload. Payload size: ' + ($body.Length / 1024 / 1024).ToString('#.#') + 'Mb')
            }
            $payloadsize = $(($body.Length / 1024).ToString('#.#'))
            Write-Verbose -Message "Payload size is $payloadsize Kb"
            #authorization header settings
            $headers = @{
                'Authorization'        = $signature
                'Log-Type'             = $logName
                'x-ms-date'            = $date
                'time-generated-field' = ''
            }
            #region :: posting data to log analytics
            try {
                [array]$response = Invoke-WebRequest -Uri $uri -Method $method -ContentType $contentType -Headers $headers -Body $body -UseBasicParsing -Verbose:$false
                #[string]$statusmessage = "$($response.StatusCode) : $($payloadsize)"
                return $($response.StatusCode)
            }
            catch {
                $errorMessage = $_.Exception.Message
                Write-Error -Message $errorMessage
            }
            #endregion
        }
        end {}
    }
    #endregion
}
process {
    #region :: Check conditions
    if ($runScriptIn64bitPowerShell -eq $true -and $([System.Environment]::Is64BitProcess) -eq $false) {
        Write-Error -Message 'Windows PowerShell 64-bit is required.' -Category 'ResourceUnavailable' -ErrorId 'B001'
        exit 1
    }
    #endregion

    #region :: collect Collect Microsoft Defender BitLocker state for all volumes
    try {
        #region :: get BitLocker policy settings from registry
        [string]$regPolicyPath = 'HKLM:\SOFTWARE\Policies\Microsoft\FVE'
        $BitLockerPolicy = $null
        if (Test-Path -Path $regPolicyPath) {
            $BitLockerPolicy = Get-ItemProperty -Path $regPolicyPath -ErrorAction SilentlyContinue
        }

        # Build policy set dynamically from all registry values, skipping PS* metadata properties
        [hashtable]$policySet = [ordered]@{
            'ComputerName' = [string]$env:COMPUTERNAME
        }
        if ($null -ne $BitLockerPolicy) {
            foreach ($prop in $BitLockerPolicy.PSObject.Properties) {
                if ($prop.Name -notmatch '^PS') {
                    $policySet[$prop.Name] = [string]$prop.Value
                }
            }
        }
        $BitLockerPolicySet = [PSCustomObject]$policySet
        Write-Verbose -Message "Collected BitLocker policy settings from registry for computer $($env:COMPUTERNAME)."
        Write-Verbose -Message "BitLocker policy settings: $($BitLockerPolicySet | ConvertTo-Json -Depth 5)"
        #endregion

        #region :: get BitLocker Volumes
        $BitLockerVolumes = Get-BitLockerVolume
        foreach ($BitLockerVolume in $BitLockerVolumes) {
            $volumeInfo = Get-Volume -DriveLetter "$($($BitLockerVolume.MountPoint).Replace(':',''))"
            $BitLockerVolumeSet = [PSCustomObject]@{
                'ComputerName'         = [string]$($BitLockerVolume.ComputerName)
                'MountPoint'           = [string]$($BitLockerVolume.MountPoint)
                'EncryptionMethod'     = [string]$($BitLockerVolume.EncryptionMethod)
                'AutoUnlockEnabled'    = [string]$($BitLockerVolume.AutoUnlockEnabled)
                'AutoUnlockKeyStored'  = [string]$($BitLockerVolume.AutoUnlockKeyStored)
                'MetadataVersion'      = [string]$($BitLockerVolume.MetadataVersion)
                'VolumeStatus'         = [string]$($BitLockerVolume.VolumeStatus)
                'ProtectionStatus'     = [string]$($BitLockerVolume.ProtectionStatus)
                'LockStatus'           = [string]$($BitLockerVolume.LockStatus)
                'EncryptionPercentage' = [string]$($BitLockerVolume.EncryptionPercentage)
                'WipePercentage'       = [string]$($BitLockerVolume.WipePercentage)
                'VolumeType'           = [string]$($BitLockerVolume.VolumeType)
                'KeyProtector'         = [string]$($BitLockerVolume.KeyProtector)
                'FileSystemType'       = [string]$($volumeInfo.FileSystemType)
                'DriveType'            = [string]$($volumeInfo.DriveType)
                'HealthStatus'         = [string]$($volumeInfo.HealthStatus)
                'OperationalStatus'    = [string]$($volumeInfo.OperationalStatus)
                'SizeRemaining'        = [string]$($volumeInfo.SizeRemaining)
                'SizeRemainingGB'      = [string]$($($volumeInfo.SizeRemaining) / 1GB).ToString('#.###')
                'Size'                 = [string]$($volumeInfo.Size)
                'SizeGB'               = [string]$($($volumeInfo.Size) / 1GB).ToString('#.###')
            }
            $BitLockerVolumeCollection.Add($BitLockerVolumeSet)
        }
        #endregion
    }
    catch {
        $errorMessage = $_.Exception.Message
        Write-Error -Message "## FAIL MESSAGE - $errorMessage"
        exit 1
    }
    finally {}
    #endregion

    #region :: processing log data
    if ($BitLockerVolumeCollection.Count -gt 0) {
        if ($SkipUpload) {
            #region :: return data to output
            [string]$elapsedTime = ('{0:00.000}' -f ((Get-Date).ToUniversalTime() - $scriptStartTime).TotalSeconds) -replace ',', '.'
            Write-Output -InputObject "[$elapsedTime] Running locally without sending data to Log Analytics."
            Write-Output -InputObject "[$elapsedTime] Collected information for $($BitLockerVolumeCollection.Count) volume(s)."
            Write-Output -InputObject $BitLockerVolumeCollection
            exit 0
            #endregion
        }
        else {
            try {
                #region :: send data to log analytics API uri
                [string]$bitLockerVolumeJson = ConvertTo-Json -InputObject $BitLockerVolumeCollection
                [string]$sendResponse = Send-LogAnalyticsData -workspaceId $WorkspaceId -sharedKey $SharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($bitLockerVolumeJson)) -logName $TableName
                if ($sendResponse -eq '200') {
                    $outputMessage = "Successfully uploaded encryption state for $($BitLockerVolumes.Count) volume(s)."
                }
                else {
                    $outputMessage = "Failed to upload encryption state for $($BitLockerVolumes.Count) volume(s)."
                }
                #endregion

                #region :: send result to output
                [string]$elapsedTime = ('{0:00.000}' -f ((Get-Date).ToUniversalTime() - $scriptStartTime).TotalSeconds) -replace ',', '.'
                Write-Output -InputObject "[$elapsedTime] $outputMessage"
                exit 0
                #endregion
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
        Write-Output -InputObject "[$elapsedTime] No BitLocker volumes found."
        exit 0
    }
    #endregion
}
end {}
