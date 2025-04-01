#requires -Version 5.1
<#
.SYNOPSIS
    Collect Windows RE partition size.
.DESCRIPTION
    Collect Windows RE partition size, to accommodate the KB5028997 update.
.PARAMETER WindowsREpartitionSizeThreshold
    Choose Windows RE partition size Threshold. Default is 1024MB.
.EXAMPLE
    .\detect.ps1
.NOTES
    version: 0.9.0.0
    date: April 2, 2024
    license: MIT License
.LINK
    [Jesper on Bluesky](https://bsky.app/profile/dotjesper.bsky.social "Jesper on Bluesky")
    [Jesper on GitHub](https://github.com/dotjesper/ "Jesper on GitHub")
#>
[CmdletBinding()]
param (
    #variables
    [Parameter (Mandatory = $False, HelpMessage = "Choose Windows RE partition size Threshold")]
    [int]$WindowsREpartitionSizeThreshold = 1024MB
)
begin {
    #variables :: conditions
    [bool]$runScriptIn64bitPowerShell = $false
    #variables :: environment
}
process {
    #region :: check conditions
    if ($runScriptIn64bitPowerShell -eq $true -and $([System.Environment]::Is64BitProcess) -eq $false) {
        Write-Error -Message "Windows PowerShell 64-bit is requered." -Category "ResourceUnavailable" -ErrorId "B001"
        exit 1
    }
    #endregion
    try {
        #region :: get Windows RE partition info
        $WinREInformations = Reagentc.exe /info
        foreach ($WinREInformation in $WinREInformations) {
            $params = $WinREInformation.Split(':')
            if ($params.Count -lt 2) {
                continue
            }
            if (($params[1].Trim() -eq "Enabled") -Or ($params[1].Trim() -eq "Disabled")) {
                $WindowsREstatus = $params[1].Trim()
            }
            if ($params[1].Trim() -like "\\?\GLOBALROOT*") {
                $WindowsRElocation = $params[1].Trim()
            }
        }
        Write-Verbose -Message "Windows RE status: $WindowsREstatus"
        Write-Verbose -Message "Windows RE location: $WindowsRElocation"
        #endregion
        if ($WindowsREstatus -eq "Disabled") {
            Write-Output -InputObject "Windows RE is disabled."
            exit 1
        }
        #region :: get Windows RE disk and partition number
        $WindowsRElocationItems = $WindowsRElocation.Split("\\")
        foreach ($item in $WindowsRElocationItems)
        {
            if ($item -like "harddisk*")
            {
                $WindowsREdiskIndex = $item -replace "[^0-9]"
            }
            if ($item -like "partition*")
            {
                $WindowsREpartitionIndex = $item -replace "[^0-9]"
            }
        }
        Write-Verbose -Message "Windows OS disk index: $WindowsREdiskIndex"
        Write-Verbose -Message "Windows RE partition index: $WindowsREpartitionIndex"
        $WindowsREpartition = Get-Partition -DiskNumber $WindowsREdiskIndex -PartitionNumber $WindowsREpartitionIndex
        #endregion
        #region :: get Windows RE partition size
        if ($WindowsREpartition.Size -lt $WindowsREpartitionSizeThreshold) {
            Write-Output -InputObject "Windows RE partition size is below the threshold [$($WindowsREpartition.Size/1MB)MB < $($WindowsREpartitionSizeThreshold/1MB)MB] [$WindowsREdiskIndex,$WindowsREpartitionIndex]."
            exit 1
        }
        else {
            Write-Output -InputObject "Windows RE partition size is above the threshold [$($WindowsREpartition.Size/1MB)MB > $($WindowsREpartitionSizeThreshold/1MB)MB] [$WindowsREdiskIndex,$WindowsREpartitionIndex]."
            exit 0
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
