#requires -Version 5.1
<#
.SYNOPSIS
    Collect Microsoft Defender BitLocker status
.DESCRIPTION
    The detection script will collect Microsoft Defender BitLocker status and upload state for all volumes to Log Analytics in Azure Monitor.
.PARAMETER workspaceId
    Log Analytics Workspace ID. Replace with your Workspace ID.
.PARAMETER sharedKey
    Log Analytics Primary Key. Replace with your Primary Key.
.PARAMETER logName
    Log Analytics Log Type / Log name in Log Analytics. Default is MsftDefenderBitlocker.
.PARAMETER logLocally
    Log locally without sending data to Log Analytics.
.EXAMPLE
    .\detect.ps1
.NOTES
    version: 1.0.0.5
    date: August 26, 2023
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
    [string]$logName = "MsftDefenderBitlocker", # Log name in Log Analytics
    [Parameter(Mandatory = $false, HelpMessage = "Log locally without sending data to Log Analytics")]
    [switch]$logLocally
)
begin {
    #variables :: conditions
    [bool]$runScriptIn64bitPowerShell = $true
    #variables :: environment
    $BitLockerVolumeCollection = [System.Collections.Generic.List[Object]]::new()
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
    #region check conditions
    if ($runScriptIn64bitPowerShell -eq $true -and $([System.Environment]::Is64BitProcess) -eq $false) {
        Write-Error -Message "Windows PowerShell 64-bit is requered." -Category "ResourceUnavailable" -ErrorId "B001"
        exit 1
    }
    #endregion
    #region :: collect Collect Microsoft Defender BitLocker state for all volumes
    try {
        #region :: get BitLocker policy settings from registry
        $BitLockerPolicy = Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\FVE"
        $BitLockerPolicySet = [PSCustomObject]@{
            "ComputerName" = [string]$env:COMPUTERNAME
            "EncryptionMethod" = [string]$($BitLockerPolicy.EncryptionMethod)
            "RequireActiveDirectory" = [string]$($BitLockerPolicy.RequireActiveDirectory)
            "RecoveryKey" = [string]$($BitLockerPolicy.RecoveryKey)
            "RecoveryKeyBackups" = [string]$($BitLockerPolicy.RecoveryKeyBackups)
            "RecoveryKeyLocation" = [string]$($BitLockerPolicy.RecoveryKeyLocation)
            "RecoveryKeyMessage" = [string]$($BitLockerPolicy.RecoveryKeyMessage)
            "RecoveryKeyURL" = [string]$($BitLockerPolicy.RecoveryKeyURL)
            "UseAdvancedStartup" = [string]$($BitLockerPolicy.UseAdvancedStartup)
            "UseTPM" = [string]$($BitLockerPolicy.UseTPM)
            "UseTPMKey" = [string]$($BitLockerPolicy.UseTPMKey)
            "UseTPMPIN" = [string]$($BitLockerPolicy.UseTPMPIN)
            "UseTPMWithPIN" = [string]$($BitLockerPolicy.UseTPMWithPIN)
            "UseTPMWithStartupKey" = [string]$($BitLockerPolicy.UseTPMWithStartupKey)
            "UseTPMWithUserKey" = [string]$($BitLockerPolicy.UseTPMWithUserKey)
            "UseTPMWithUserKeyPIN" = [string]$($BitLockerPolicy.UseTPMWithUserKeyPIN)
        }
        #Endregion
        #region :: get BitLocker Volumes
        $BitLockerVolumes = Get-BitLockerVolume
        foreach ($BitLockerVolume in $BitLockerVolumes) {
            $VolumeIifo = Get-Volume -DriveLetter "$($($BitLockerVolume.MountPoint).Replace(':',''))"
            $BitLockerVolumeSet = [PSCustomObject]@{
                "ComputerName"         = [string]$($BitLockerVolume.ComputerName)
                "MountPoint"           = [string]$($BitLockerVolume.MountPoint)
                "EncryptionMethod"     = [string]$($BitLockerVolume.EncryptionMethod)
                "AutoUnlockEnabled"    = [string]$($BitLockerVolume.AutoUnlockEnabled)
                "AutoUnlockKeyStored"  = [string]$($BitLockerVolume.AutoUnlockKeyStored)
                "MetadataVersion"      = [string]$($BitLockerVolume.MetadataVersion)
                "VolumeStatus"         = [string]$($BitLockerVolume.VolumeStatus)
                "ProtectionStatus"     = [string]$($BitLockerVolume.ProtectionStatus)
                "LockStatus"           = [string]$($BitLockerVolume.LockStatus)
                "EncryptionPercentage" = [string]$($BitLockerVolume.EncryptionPercentage)
                "WipePercentage"       = [string]$($BitLockerVolume.WipePercentage)
                "VolumeType"           = [string]$($BitLockerVolume.VolumeType)
               #"CapacityGB"           = [string]$($BitLockerVolume.CapacityGB)
                "KeyProtector"         = [string]$($BitLockerVolume.KeyProtector)
                "FileSystemType"       = [string]$($VolumeIifo.FileSystemType)
                "DriveType"            = [string]$($VolumeIifo.DriveType)
                "HealthStatus"         = [string]$($VolumeIifo.HealthStatus)
                "OperationalStatus"    = [string]$($VolumeIifo.OperationalStatus)
                "SizeRemaining"        = [string]$($VolumeIifo.SizeRemaining)
                "SizeRemainingGB"      = [string]$($($VolumeIifo.SizeRemaining)/1GB).ToString("#.###")
                "Size"                 = [string]$($VolumeIifo.Size)
                "SizeGB"               = [string]$($($VolumeIifo.Size)/1GB).ToString("#.###")
            }
            $BitLockerVolumeCollection.Add($BitLockerVolumeSet)
        }
        #endregion
    }
    catch {
        $errMsg = $_.Exception.Message
        Write-Error -Message "## FAIL MESSAGE - $errMsg"
        exit 1
    }
    finally {}
    #endregion
    #region :: processing log data
    if ($BitLockerVolumeCollection.Count -gt 0) {
        if ($logLocally) {
            #region :: return data to output
            Write-Output -InputObject "Running locally without sending data to Log Analytics."
            Write-Output -InputObject "Collected information for $($BitLockerVolumeCollection.Count) volumen(s)."
            Write-Output -InputObject $BitLockerVolumeCollection
            exit 0
            #endregion
        }
        else {
            try {
                #region :: send data to log analytics API uri
                [string]$BitLockerVolumeCollection = ConvertTo-Json -InputObject $BitLockerVolumeCollection
                [string]$sendResponse = Send-LogAnalyticsData -workspaceId $workspaceId -sharedKey $sharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($BitLockerVolumeCollection)) -logName $logName
                if ($sendResponse -eq "200") {
                    $outputMessage = "Succesfully uploaded encryption state for $($BitLockerVolumes.Count) Volume(s)."
                }
                else {
                    $outputMessage = "Failed to uploaded encryption state for $($BitLockerVolumes.Count) Volume(s)."
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
        Write-Output -InputObject "No BitLocker volumes found."
        exit 0
    }
    #endregion
}
end {}
