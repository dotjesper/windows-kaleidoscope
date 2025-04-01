#requires -Version 5.1
<#
.SYNOPSIS
    Collect device warranty information.
.DESCRIPTION
    Collect device warranty information from the vendors website.
    Currently supported vendors:
    - Lenovo
.PARAMETER warrantyTimeThreshold
    Choose Warranty time threshold in days.
    Default value is 60 days.
.EXAMPLE
    .\detect.ps1
.OUTPUTS
    Lenovo:
    :> The warranty for the device with serial number [GR97ZT9W] is active [Start: 2021-06-01 | End: 2025-06-01 | Days Left: 345].
    :> The warranty for the device with serial number [YT07QT6R] is about to expire [Start: 2021-06-01 | End: 2024-10-01 | Days Left: 48].
    :> The warranty for the device with serial number [GRT09KL4] has expired [Start: 2021-06-01 | End: 2024-06-01 | Days Overdue: 123].
    Unknown vendor:
    :> Undefined vendor [Unknown | GL24KE7Z23W].
.NOTES
    version: 1.0.0.0
    date: September 3, 2024
    license: MIT License
.LINK
    [Jesper on Bluesky](https://bsky.app/profile/dotjesper.bsky.social "Jesper on Bluesky")
    [Jesper on GitHub](https://github.com/dotjesper/ "Jesper on GitHub")
#>
[CmdletBinding()]
param (
    #variables
    [Parameter(Mandatory = $False, HelpMessage = "Choose Warranty time threshold in days.")]
    [int]$warrantyTimeThreshold = 60
)
begin {
    #variables :: conditions
    [bool]$runScriptIn64bitPowerShell = $false
    #variables :: environment
}
process {
    #region check conditions
    if ($runScriptIn64bitPowerShell -eq $true -and $([System.Environment]::Is64BitProcess) -eq $false) {
        Write-Error -Message "Windows PowerShell 64-bit is requered." -Category "ResourceUnavailable" -ErrorId "B001"
        exit 1
    }
    #endregion
    try {
        Write-Verbose -Message "Collecting device warranty information."
        [string]$vendor = (Get-CimInstance -ClassName Win32_ComputerSystemProduct -Verbose:$false).Vendor
        Write-Verbose -Message "Vendor: $vendor"
        [string]$model = (Get-CimInstance -ClassName Win32_ComputerSystemProduct -Verbose:$false).Name
        Write-Verbose -Message "Model: $model"
        [string]$version = (Get-CimInstance -ClassName Win32_ComputerSystemProduct -Verbose:$false).Version
        Write-Verbose -Message "Model: $version"
        [string]$serialNumber = (Get-CimInstance -ClassName "win32_bios" -Verbose:$false).SerialNumber
        Write-Verbose -Message "Serial number: $serialNumber"
        switch ($vendor) {
            "Lenovo" {
                #region :: Lenovo
                # Retrive warranty information from Lenovo
                try {
                    $Device_Info = invoke-restmethod "https://pcsupport.lenovo.com/us/en/api/v4/mse/getproducts?productId=$serialNumber"
                    $Device_ID = $Device_Info.id
                    $Warranty_url = "https://pcsupport.lenovo.com/us/en/products/$Device_ID/warranty"
                    $Web_Response = Invoke-WebRequest -Uri "$Warranty_url" -Method "GET" -UseBasicParsing
                }
                catch {
                    Write-Error -Message "Can not retrive serial number infomation: $serialNumber" -Category "SyntaxError" -ErrorId "C001"
                    exit 1
                }
                # Check if the request was successful
                if ($Web_Response.StatusCode -eq 200){
                    $HTML_Content = $Web_Response.Content
                    $Pattern_Status = '"warrantystatus":"(.*?)"'
                    $Pattern_Status2 = '"StatusV2":"(.*?)"'
                    $Pattern_StartDate = '"Start":"(.*?)"'
                    $Pattern_EndDate = '"End":"(.*?)"'
                    $Pattern_DeviceModel = '"Name":"(.*?)"'
                    $Status_Matches = [regex]::Matches($HTML_Content, $Pattern_Status)
                    $Statusv2_Matches = [regex]::Matches($HTML_Content, $Pattern_Status2)
                    $StartDate_Matches = [regex]::Matches($HTML_Content, $Pattern_StartDate)
                    $EndDate_Matches = [regex]::Matches($HTML_Content, $Pattern_EndDate)
                    $Model_Matches = [regex]::Matches($HTML_Content, $Pattern_DeviceModel)
                    if ($Status_Matches.Count -gt 0){
                        $Status_Result = $Status_Matches[0].Groups[1].Value.Trim()
                    }
                    else {
                        $Status_Result = "Can not get status info"
                    }
                    if ($Statusv2_Matches.Count -gt 0){
                        $Statusv2_Result = $Statusv2_Matches[0].Groups[1].Value.Trim()
                    }
                    else {
                        $Statusv2_Result = "Can not get status info"
                    }
                    if ($StartDate_Matches.Count -gt 0){
                        $StartDate_Result = $StartDate_Matches[0].Groups[1].Value.Trim()
                    }
                    if ($EndDate_Matches.Count -gt 0){
                        $EndDate_Result = $EndDate_Matches[0].Groups[1].Value.Trim()
                    }
                    if ($Model_Matches.Count -gt 0){
                        $Model_Result = $Model_Matches[0].Groups[1].Value.Trim()
                    }
                }
                else{
                    Write-Output -InputObject "Failed to retrieve warranty information. Status Code: $($response.StatusCode)"
                    exit 1
                }
                # Create object
                $Warranty_Object = @()
                $Properties = @{
                    SerialNumber = $serialNumber
                    Model = $Model_Result
                    Status = $Status_Result
                    StartDate = $StartDate_Result
                    EndDate = $EndDate_Result
                    IsActive = $Statusv2_Result
                }
                # Add object to array
                $Warranty_Object += New-Object -TypeName PSObject -Property $Properties | Select-Object Model,serialNumber,Status,IsActive,StartDate,EndDate
                # Output object
                Write-Verbose -Message "Model: $($Warranty_Object.Model)"
                Write-Verbose -Message "Serial: $($Warranty_Object.serialNumber)"
                Write-Verbose -Message "Status: $($Warranty_Object.Status)"
                Write-Verbose -Message "IsActive: $($Warranty_Object.IsActive)"
                Write-Verbose -Message "StartDate: $($Warranty_Object.StartDate)"
                Write-Verbose -Message "EndDate: $($Warranty_Object.EndDate)"
                $daydiff = (New-TimeSpan -Start $(Get-Date) -End $($Warranty_Object.EndDate) -Verbose:$false).Days
                if ($daydiff -gt 0) {
                    [string]$warrentyTime = "Days Left: $daydiff"
                    Write-Verbose -Message "$warrentyTime"
                }
                else {
                    [string]$warrentyTime = "Days Overdue: $($daydiff * -1)"
                    Write-Verbose -Message "$warrentyTime"
                }
                if ($Warranty_Object.status -eq "In Warranty") {
                    if ($daydiff -gt $warrantyTimeThreshold) {
                        Write-Output -InputObject "The warranty for the device with serial number [$serialNumber] is active [Start: $($Warranty_Object.StartDate) | End: $($Warranty_Object.EndDate) | $warrentyTime]."
                        exit 0
                    }
                    else {
                        Write-Output -InputObject "The warranty for the device with serial number [$serialNumber] is about to expire [Start: $($Warranty_Object.StartDate) | End: $($Warranty_Object.EndDate) | $warrentyTime]."
                        exit 1
                    }
                }
                else {
                    Write-Output -InputObject "The warranty for the device with serial number [$serialNumber] has expired [Start: $($Warranty_Object.StartDate) | End: $($Warranty_Object.EndDate) | $warrentyTime]."
                    exit 1
                }
                #endregion
            }
            Default {
                Write-Output -InputObject "Undefined vendor [$vendor | $serialNumber]."
                exit 0
            }
        }
    }
    catch {
        $errMsg = $_.Exception.Message
        Write-Error -Message $errMsg -Category "SyntaxError" -ErrorId "C001"
        exit 1
    }
    finally {}
}
end {}
