<#
.SYNOPSIS
    Collect low disk space inventory.

.DESCRIPTION
    Collect Windows disk usage, fails if system disk space usage is above defined disk space usage threshold.

.PARAMETER DiskSpaceUsageThreshold
    Windows disk usage threshold in percentages (0-100). Default is 80.

.PARAMETER DiskSpaceUsageMeasureMethod
    Disk space usage measure method. 1. Class: Win32_LogicalDisk 2. Class: Win32_Volume. Default is 1.

.EXAMPLE
    .\detect.ps1

    Run the script with default settings (80% disk space usage threshold, measure method: Win32_LogicalDisk).

.EXAMPLE
    .\detect.ps1 -DiskSpaceUsageThreshold 80 -DiskSpaceUsageMeasureMethod 2 -Verbose

    Run the script with 80% disk space usage threshold and measure method: Win32_Volume. Verbose output enabled.

.NOTES
    version: 1.2.0
    date: May 6, 2022
    license: MIT License

.LINK
    https://github.com/dotjesper/windows-kaleidoscope
#>

#requires -Version 5.1

[CmdletBinding()]
param (
    #variables
    [Parameter (Mandatory = $False, HelpMessage = 'Choose disk space usage threshold') ]
    [ValidateRange(0, 100)]
    [int]$DiskSpaceUsageThreshold = 80,

    [Parameter (Mandatory = $False, HelpMessage = 'Choose disk space usage measure method') ]
    [ValidateRange(1, 2)]
    [int]$DiskSpaceUsageMeasureMethod = 1
)

begin {
    Set-StrictMode -Version Latest

    # variables :: Conditions
    [bool]$runScriptIn64bitPowerShell = $false

    # variables :: Environment
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
        # Collect disk usage information and evaluate against the defined threshold.
        switch ($DiskSpaceUsageMeasureMethod) {
            1 {
                $systemDrive = Get-CimInstance -ClassName 'Win32_LogicalDisk' -Filter "DeviceID = '$($Env:SystemDrive)'"
                [int]$systemDriveSize = [int]($systemDrive.Size / 1GB)
                [int]$systemDriveSizeRemaining = [int]($systemDrive.FreeSpace / 1GB)
            }
            2 {
                $systemDrive = Get-CimInstance -ClassName 'Win32_Volume' -Filter "DriveLetter = '$($Env:SystemDrive)'"
                [int]$systemDriveSize = [int]($systemDrive.Capacity / 1GB)
                [int]$systemDriveSizeRemaining = [int]($systemDrive.FreeSpace / 1GB)
            }
        }

        # Depending on the measure method, the drive name is either the DeviceID or DriveLetter property of the system drive.
        [string]$driveName = if ($DiskSpaceUsageMeasureMethod -eq 1) { $systemDrive.DeviceID } else { $systemDrive.DriveLetter }
        Write-Verbose -Message "System drive size: $systemDriveSize GB ($driveName)"
        Write-Verbose -Message "System drive size remaining: $systemDriveSizeRemaining GB ($driveName)"
        [int]$diskSpaceUsageGB = $systemDriveSize - $systemDriveSizeRemaining
        Write-Verbose -Message "$diskSpaceUsageGB GB used"
        [int]$diskSpaceUsagePercent = [int]((($systemDriveSize - $systemDriveSizeRemaining) * 100) / $systemDriveSize)
        Write-Verbose -Message "$diskSpaceUsagePercent% used"

        # Evaluate disk usage against the defined threshold and exit with appropriate status code.
        [string]$elapsedTime = ('{0:00.000}' -f ((Get-Date).ToUniversalTime() - $scriptStartTime).TotalSeconds) -replace ',', '.'
        if ($diskSpaceUsagePercent -gt $DiskSpaceUsageThreshold) {
            Write-Output -InputObject "[$elapsedTime] Disk usage on $driveName drive is above the threshold ($diskSpaceUsagePercent% used | size: $systemDriveSize GB)"
            exit 1
        }
        else {
            Write-Output -InputObject "[$elapsedTime] Disk usage on $driveName drive is below the threshold ($diskSpaceUsagePercent% used | size: $systemDriveSize GB)"
            exit 0
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
