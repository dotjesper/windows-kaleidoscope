<#
.SYNOPSIS
    Collect Windows RE partition size.

.DESCRIPTION
    Collect Windows RE partition size, to accommodate the KB5028997 update.

.EXAMPLE
    .\detect.ps1

    Collect Windows RE partition size with default threshold (1024MB).

.NOTES
    version: 0.9.0
    date: April 2, 2024
    license: MIT License

.LINK
    https://github.com/dotjesper/windows-kaleidoscope
#>

#requires -Version 5.1
#requires -RunAsAdministrator

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false, HelpMessage = 'Choose Windows RE partition size threshold.')]
    [int]$WindowsREpartitionSizeThreshold = 1024MB
)

begin {
    Set-StrictMode -Version Latest

    # variables :: Conditions
    [bool]$runScriptIn64bitPowerShell = $false

    #variables :: exit
    [int]$exitCode = 0
    [datetime]$scriptStartTime = (Get-Date).ToUniversalTime()
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
        # get Windows RE partition info
        [array]$winREInformationLines = Reagentc.exe /info
        [string]$winREStatus = ''
        [string]$winRELocation = ''

        # parse Windows RE partition info
        foreach ($line in $winREInformationLines) {
            [array]$lineParts = $line -split ':'
            if ($lineParts.Count -lt 2) {
                continue
            }
            [string]$lineValue = $lineParts[1] -replace '^\s+|\s+$'
            if ($lineValue -eq 'Enabled' -or $lineValue -eq 'Disabled') {
                $winREStatus = $lineValue
            }
            if ($lineValue -like '\\?\GLOBALROOT*') {
                $winRELocation = $lineValue
            }
        }
        Write-Verbose -Message "Windows RE status: $winREStatus"
        Write-Verbose -Message "Windows RE location: $winRELocation"

        # validate Windows RE status and location
        if ($winREStatus -eq 'Disabled') {
            [string]$elapsedTime = ('{0:00.000}' -f ((Get-Date).ToUniversalTime() - $scriptStartTime).TotalSeconds) -replace ',', '.'
            Write-Output -InputObject "[$elapsedTime] Windows RE is disabled."
            $exitCode = 1
        }
        elseif ($winRELocation -eq '') {
            [string]$elapsedTime = ('{0:00.000}' -f ((Get-Date).ToUniversalTime() - $scriptStartTime).TotalSeconds) -replace ',', '.'
            Write-Output -InputObject "[$elapsedTime] Windows RE location not found."
            $exitCode = 1
        }
        else {
            # get Windows RE disk and partition number
            [string]$winREDiskIndex = ''
            [string]$winREPartitionIndex = ''
            [array]$winRELocationItems = $winRELocation -split '\\'
            foreach ($item in $winRELocationItems) {
                if ($item -like 'harddisk*') {
                    $winREDiskIndex = $item -replace '[^0-9]'
                }
                if ($item -like 'partition*') {
                    $winREPartitionIndex = $item -replace '[^0-9]'
                }
            }
            Write-Verbose -Message "Windows OS disk index: $winREDiskIndex"
            Write-Verbose -Message "Windows RE partition index: $winREPartitionIndex"
            $winREPartition = Get-Partition -DiskNumber $winREDiskIndex -PartitionNumber $winREPartitionIndex

            # get Windows RE partition size
            if ($winREPartition.Size -lt $WindowsREpartitionSizeThreshold) {
                [string]$elapsedTime = ('{0:00.000}' -f ((Get-Date).ToUniversalTime() - $scriptStartTime).TotalSeconds) -replace ',', '.'
                Write-Output -InputObject "[$elapsedTime] Windows RE partition size is below the threshold [$($winREPartition.Size/1MB)MB < $($WindowsREpartitionSizeThreshold/1MB)MB] [$winREDiskIndex,$winREPartitionIndex]."
                $exitCode = 1
            }
            else {
                [string]$elapsedTime = ('{0:00.000}' -f ((Get-Date).ToUniversalTime() - $scriptStartTime).TotalSeconds) -replace ',', '.'
                Write-Output -InputObject "[$elapsedTime] Windows RE partition size is above the threshold [$($winREPartition.Size/1MB)MB > $($WindowsREpartitionSizeThreshold/1MB)MB] [$winREDiskIndex,$winREPartitionIndex]."
                $exitCode = 0
            }
        }
    }
    catch {
        $errMsg = $_.Exception.Message
        Write-Error -Message $errMsg -Category 'SyntaxError' -ErrorId 'C001'
        $exitCode = 1
    }
    finally {}
    #endregion
}
end {
    # return exit code
    exit $exitCode
}
