<#
.SYNOPSIS
    Collect device warranty information.

.DESCRIPTION
    Collect device warranty information from the vendor's website.
    Currently supported vendors:
    - Lenovo

    Note: Warranty data is scraped from the vendor's web page using regex pattern matching.
    Changes to the vendor's page structure may require script updates.

.PARAMETER WarrantyTimeThreshold
    Warranty time threshold in days. If the remaining warranty is less than or equal to this
    value, the script reports the warranty as about to expire.
    Default value is 60 days.

.EXAMPLE
    .\detect.ps1

    Collect device warranty information using the default threshold of 60 days.

.EXAMPLE
    .\detect.ps1 -WarrantyTimeThreshold 90

    Collect device warranty information with a 90-day threshold.

.OUTPUTS
    Lenovo:
    :> The warranty for the device with serial number [GR97ZT9W] is active [Start: 2021-06-01 | End: 2025-06-01 | Days Left: 345].
    :> The warranty for the device with serial number [YT07QT6R] is about to expire [Start: 2021-06-01 | End: 2024-10-01 | Days Left: 48].
    :> The warranty for the device with serial number [GRT09KL4] has expired [Start: 2021-06-01 | End: 2024-06-01 | Days Overdue: 123].

    Unknown vendor:
    :> Undefined vendor [Unknown | GL24KE7Z23W].

.NOTES
    version: 1.0.0
    date: September 3, 2024
    license: MIT License

.LINK
    https://github.com/dotjesper/windows-kaleidoscope
#>

#requires -Version 5.1

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false, HelpMessage = 'Warranty time threshold in days.')]
    [int]$WarrantyTimeThreshold = 60
)

begin {
    Set-StrictMode -Version Latest

    # variables :: Conditions
    [bool]$runScriptIn64bitPowerShell = $false

    # variables :: Environment
    [datetime]$scriptStartTime = (Get-Date).ToUniversalTime()

    #variables :: enable TLS 1.2 support
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
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
        Write-Verbose -Message 'Collecting device warranty information.'
        $computerSystemProduct = Get-CimInstance -ClassName Win32_ComputerSystemProduct -Verbose:$false
        [string]$vendor = $computerSystemProduct.Vendor
        Write-Verbose -Message "Vendor: $vendor"
        [string]$model = $computerSystemProduct.Name
        Write-Verbose -Message "Model: $model"
        [string]$version = $computerSystemProduct.Version
        Write-Verbose -Message "Version: $version"
        [string]$serialNumber = (Get-CimInstance -ClassName Win32_BIOS -Verbose:$false).SerialNumber
        Write-Verbose -Message "Serial number: $serialNumber"
        switch ($vendor) {
            'Lenovo' {
                #region :: Lenovo
                # Retrieve warranty information from Lenovo
                [string]$encodedSerialNumber = [System.Uri]::EscapeDataString($serialNumber)
                try {
                    $deviceInfo = Invoke-RestMethod -Uri "https://pcsupport.lenovo.com/us/en/api/v4/mse/getproducts?productId=$encodedSerialNumber"
                    [string]$deviceId = $deviceInfo.id
                    [string]$warrantyUrl = "https://pcsupport.lenovo.com/us/en/products/$deviceId/warranty"
                    $webResponse = Invoke-WebRequest -Uri $warrantyUrl -Method 'GET' -UseBasicParsing
                }
                catch {
                    Write-Error -Message "Cannot retrieve serial number information: $serialNumber" -Category 'SyntaxError' -ErrorId 'C001'
                    exit 1
                }
                # Check if the request was successful
                if ($webResponse.StatusCode -eq 200) {
                    [string]$htmlContent = $webResponse.Content
                    [string]$patternStatus = '"warrantystatus":"(.*?)"'
                    [string]$patternStatusV2 = '"StatusV2":"(.*?)"'
                    [string]$patternStartDate = '"Start":"(.*?)"'
                    [string]$patternEndDate = '"End":"(.*?)"'
                    [string]$patternDeviceModel = '"Name":"(.*?)"'
                    $statusMatches = [regex]::Matches($htmlContent, $patternStatus)
                    $statusV2Matches = [regex]::Matches($htmlContent, $patternStatusV2)
                    $startDateMatches = [regex]::Matches($htmlContent, $patternStartDate)
                    $endDateMatches = [regex]::Matches($htmlContent, $patternEndDate)
                    $modelMatches = [regex]::Matches($htmlContent, $patternDeviceModel)
                    if ($statusMatches.Count -gt 0) {
                        [string]$statusResult = $statusMatches[0].Groups[1].Value.Trim()
                    }
                    else {
                        [string]$statusResult = 'Cannot get status info'
                    }
                    if ($statusV2Matches.Count -gt 0) {
                        [string]$statusV2Result = $statusV2Matches[0].Groups[1].Value.Trim()
                    }
                    else {
                        [string]$statusV2Result = 'Cannot get status info'
                    }
                    [string]$startDateResult = ''
                    if ($startDateMatches.Count -gt 0) {
                        $startDateResult = $startDateMatches[0].Groups[1].Value.Trim()
                    }
                    [string]$endDateResult = ''
                    if ($endDateMatches.Count -gt 0) {
                        $endDateResult = $endDateMatches[0].Groups[1].Value.Trim()
                    }
                    [string]$modelResult = ''
                    if ($modelMatches.Count -gt 0) {
                        $modelResult = $modelMatches[0].Groups[1].Value.Trim()
                    }
                }
                else {
                    [string]$elapsedTime = ('{0:00.000}' -f ((Get-Date).ToUniversalTime() - $scriptStartTime).TotalSeconds) -replace ',', '.'
                    Write-Output -InputObject "[$elapsedTime] Failed to retrieve warranty information. Status Code: $($webResponse.StatusCode)"
                    exit 1
                }
                # Create warranty object
                $warrantyObject = [PSCustomObject]@{
                    Model        = $modelResult
                    SerialNumber = $serialNumber
                    Status       = $statusResult
                    IsActive     = $statusV2Result
                    StartDate    = $startDateResult
                    EndDate      = $endDateResult
                }
                Write-Verbose -Message "Warranty: $($warrantyObject.Model) [$($warrantyObject.SerialNumber)] Status: $($warrantyObject.Status) ($($warrantyObject.StartDate) - $($warrantyObject.EndDate))"
                # Validate end date before calculating time span
                if ([string]::IsNullOrEmpty($warrantyObject.EndDate)) {
                    [string]$elapsedTime = ('{0:00.000}' -f ((Get-Date).ToUniversalTime() - $scriptStartTime).TotalSeconds) -replace ',', '.'
                    Write-Output -InputObject "[$elapsedTime] Cannot determine warranty end date for device with serial number [$serialNumber]."
                    exit 1
                }
                [int]$dayDiff = (New-TimeSpan -Start $(Get-Date) -End $($warrantyObject.EndDate) -Verbose:$false).Days
                if ($dayDiff -gt 0) {
                    [string]$warrantyTime = "Days Left: $dayDiff"
                }
                else {
                    [string]$warrantyTime = "Days Overdue: $($dayDiff * -1)"
                }
                Write-Verbose -Message "$warrantyTime"
                if ($warrantyObject.Status -eq 'In Warranty') {
                    [string]$elapsedTime = ('{0:00.000}' -f ((Get-Date).ToUniversalTime() - $scriptStartTime).TotalSeconds) -replace ',', '.'
                    if ($dayDiff -gt $WarrantyTimeThreshold) {
                        Write-Output -InputObject "[$elapsedTime] The warranty for the device with serial number [$serialNumber] is active [Start: $($warrantyObject.StartDate) | End: $($warrantyObject.EndDate) | $warrantyTime]."
                        exit 0
                    }
                    else {
                        Write-Output -InputObject "[$elapsedTime] The warranty for the device with serial number [$serialNumber] is about to expire [Start: $($warrantyObject.StartDate) | End: $($warrantyObject.EndDate) | $warrantyTime]."
                        exit 1
                    }
                }
                else {
                    [string]$elapsedTime = ('{0:00.000}' -f ((Get-Date).ToUniversalTime() - $scriptStartTime).TotalSeconds) -replace ',', '.'
                    Write-Output -InputObject "[$elapsedTime] The warranty for the device with serial number [$serialNumber] has expired [Start: $($warrantyObject.StartDate) | End: $($warrantyObject.EndDate) | $warrantyTime]."
                    exit 1
                }
                #endregion
            }
            Default {
                [string]$elapsedTime = ('{0:00.000}' -f ((Get-Date).ToUniversalTime() - $scriptStartTime).TotalSeconds) -replace ',', '.'
                Write-Output -InputObject "[$elapsedTime] Undefined vendor [$vendor | $serialNumber]."
                exit 0
            }
        }
    }
    catch {
        $errorMessage = $_.Exception.Message
        Write-Error -Message $errorMessage -Category 'SyntaxError' -ErrorId 'C001'
        exit 1
    }
    finally {}
    #endregion
}
end {}
