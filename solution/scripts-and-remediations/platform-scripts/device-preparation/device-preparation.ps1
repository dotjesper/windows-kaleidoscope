<#
.SYNOPSIS
    This script is for Windows Autopilot device preparation.

.DESCRIPTION
    This script prepares Windows devices during Windows Autopilot enrollment by performing the following actions:

    DEVICE RENAMING:
    - Renames the computer based on the specified naming method:
      * %SERIAL%: Uses the device serial number (truncated to fit 15-character limit)
      * %RAND:x%: Generates x random digits for the name
      * Default: Uses a SHA256 hash of the serial number for consistent, unique naming
    - Validates the generated name does not exceed 15 characters (NetBIOS limit)
    - Skips renaming if the device already has the correct prefix
    - Sets a pending reboot flag after successful rename

    OOBE REGISTRY SETTINGS:
    - Disables Privacy Experience prompts during OOBE
    - Disables Voice features
    - Sets Privacy Consent status
    - Configures ProtectYourPC settings (value: 3)
    - Hides the End User License Agreement (EULA) page

    BITLOCKER DRIVE ENCRYPTION VALIDATION:
    - Validates BitLocker Drive Encryption status on the system drive
    - Reports protection status, encryption method, and key protectors
    - Warns if the volume is not fully encrypted

    LOCATION MARKER:
    - Creates a registry-based location marker for language and region settings
    - Can be used by other scripts or policies to determine device location

.PARAMETER Features
    Bitmask to enable/disable specific features. Default is 15 (all enabled).
    1  = Device Renaming
    2  = OOBE Registry Settings
    4  = BitLocker Drive Encryption Validation
    8  = Location Marker

    Examples: 15 = All, 7 = All except Location Marker, 5 = Renaming + BitLocker Drive Encryption only

.PARAMETER Prefix
    Defines a custom prefix for the computer name. Maximum length is 5 characters.

.PARAMETER NamingMethod
    Specify "%SERIAL%" to use the device serial number for naming.
    Specify "%RAND:x%" where x is the number of random digits to generate.
    If not specified, a SHA256 hash of the serial number is used.

.PARAMETER Suffix
    Defines a custom suffix for the computer name. Maximum length is 5 characters.

.PARAMETER LocationMarker
    Creates a location marker in the registry for language and region settings.

.PARAMETER LocationMarkerPath
    Specifies the registry path where the location marker will be stored.

.PARAMETER logFilePath
    Specifies a custom log file path. Alias: logFile.

.EXAMPLE
    .\device-preparation.ps1 -Prefix "WIN" -Suffix "01" -NamingMethod "%SERIAL%"

    Renames the device using the serial number with a prefix and suffix.

.EXAMPLE
    .\device-preparation.ps1 -Prefix "PC" -NamingMethod "%RAND:8%"

    Renames the device using 8 random digits with a prefix.

.EXAMPLE
    .\device-preparation.ps1 -Prefix "LAP" -LocationMarker "USA"

    Renames the device using a hashed serial number and sets the location marker to USA.

.NOTES
    version: 1.5.0
    date: April 10, 2026
    license: MIT License
    --------------------------------------------------------------------------------
    LEGAL DISCLAIMER

    This PowerShell script is provided "as-is" without warranty of any kind, either
    expressed or implied, including but not limited to the implied warranties of
    merchantability and fitness for a particular purpose. The author(s) and
    contributor(s) do not warrant that the functions contained in the script will
    meet your requirements or that the operation of the script will be uninterrupted
    or error-free.

    In no event shall the author(s) or contributor(s) be held liable for any direct,
    indirect, incidental, special, exemplary, or consequential damages (including,
    but not limited to, procurement of substitute goods or services; loss of use,
    data, or profits; or business interruption) however caused and on any theory of
    liability, whether in contract, strict liability, or tort (including negligence
    or otherwise) arising in any way out of the use of this script, even if advised
    of the possibility of such damage.

    IMPORTANT: It is strongly recommended to thoroughly test this script in a
    non-production environment before deploying to production systems. The script
    may require modification to fit your specific environment and requirements.
    By using this script, you acknowledge that you have read this disclaimer,
    understand it, and agree to be bound by its terms. You assume all risks and
    responsibilities associated with the use of this script.
    --------------------------------------------------------------------------------

.LINK
    https://github.com/dotjesper/windows-kaleidoscope
#>

#requires -Version 5.1
#requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess)]
param (
    [Parameter(Mandatory = $false, HelpMessage = 'Bitmask to enable features: 1=Rename, 2=OOBE, 4=BitLocker Drive Encryption, 8=Location. Default 15 (all)')]
    [ValidateRange(0, 15)]
    [int]$Features = 15,

    [Parameter(Mandatory = $false, HelpMessage = 'Enter a custom prefix for the computer name (e.g., WIN, PC, LAP). Maximum length is 5 characters.')]
    [ValidateScript({ $_.Length -le 5 })]
    [string]$Prefix = 'WSR5',

    [Parameter(Mandatory = $false, HelpMessage = 'Specify "%SERIAL%" for serial number based naming or "%RAND:x%" where x is the number of random digits')]
    [Alias('naming')]
    [string]$NamingMethod = '',

    [Parameter(Mandatory = $false, HelpMessage = 'Enter a custom suffix for the computer name (e.g., 01, A). Maximum length is 5 characters.')]
    [ValidateScript({ $_.Length -le 5 })]
    [string]$Suffix = '',

    [Parameter(Mandatory = $false, HelpMessage = 'Create a location marker for language and region settings')]
    [Alias('location', 'marker')]
    [string]$LocationMarker = 'DEN',

    [Parameter(Mandatory = $false, HelpMessage = 'Specify the registry path for the location marker')]
    [Alias('locationPath', 'markerPath')]
    [string]$LocationMarkerPath = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE',

    [Parameter(Mandatory = $false, HelpMessage = 'Enter a custom log file path (e.g., C:\Temp\log.txt)')]
    [Alias('log', 'logFile')]
    [string]$logFilePath = "$($Env:ProgramData)\Microsoft\IntuneManagementExtension\Logs\DevicePreparation.log"
)
begin {
    Set-StrictMode -Version Latest

    #region :: Check conditions

    #This script requires FullLanguage mode. It uses .NET types and methods. (SHA256, BitConverter, Substring, ArrayList) that are blocked in Constrained Language Mode.
    if ($ExecutionContext.SessionState.LanguageMode -ne 'FullLanguage') {
        Write-Error -Message "FullLanguage mode is required. Current mode: $($ExecutionContext.SessionState.LanguageMode)" -Category 'ResourceUnavailable' -ErrorId 'B002'
        exit 1
    }
    #endregion

    #region :: Environment
    # Start time for runtime calculation in log summary
    [datetime]$script:startTime = (Get-Date).ToUniversalTime()

    # Log package name for CMTrace log entries
    [string]$logPackageName = 'device-preparation'

    # Feature flags derived from bitmask: 1=Rename, 2=OOBE, 4=BitLocker Drive Encryption, 8=Location
    [bool]$deviceRenaming = ($Features -band 1) -ne 0
    [bool]$applyOOBERegistrySettings = ($Features -band 2) -ne 0
    [bool]$validateBitLocker = ($Features -band 4) -ne 0
    [bool]$setLocationMarker = ($Features -band 8) -ne 0

    # Internal variables
    [string]$newName = ''
    $renameStatus = $null

    # Summary tracking
    [hashtable]$summary = @{
        DeviceRenamed       = $false
        OOBESettingsApplied = $false
        BitLockerValidated  = $false
        LocationMarkerSet   = $false
        Errors              = [System.Collections.ArrayList]::new()
        Warnings            = [System.Collections.ArrayList]::new()
    }
    #endregion

    #region :: Environment configurations
    [String]$title = 'Windows Autopilot device preparation'
    #endregion

    #region :: Functions
    function Write-Log {
        <#
        .SYNOPSIS
            Write formatted log entries to a CMTrace/Intune-compatible log file.

        .DESCRIPTION
            Writes log entries with CMTrace and Microsoft Intune Management Extension compatible formatting.
            Supports different log levels (Info, Warning, Error) and component-based logging.

        .PARAMETER Message
            The log message to write.

        .PARAMETER Component
            The component or section of the script generating the log entry.

        .PARAMETER Severity
            The severity level of the log entry:
            1: Information (Default)
            2: Warning
            3: Error
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
            [string]$Message,

            [Parameter(Mandatory = $false)]
            [string]$Component = '',

            [Parameter(Mandatory = $false)]
            [ValidateSet(1, 2, 3)]
            [int]$Severity = 1
        )
        process {
            try {
                [datetime]$timestamp = Get-Date

                # Compute UTC offset in minutes for CMTrace-compatible time field
                [timespan]$utcOffset = $timestamp - $timestamp.ToUniversalTime()
                [int]$utcOffsetMinutes = $utcOffset.TotalMinutes
                [string]$utcOffsetStr = if ($utcOffsetMinutes -ge 0) { "+$utcOffsetMinutes" } else { "$utcOffsetMinutes" }

                # Build CMTrace-compatible log entry
                [string]$logEntry = "<![LOG[[$logPackageName] $Message]LOG]!>" +
                "<time=""$($timestamp.ToString('HH:mm:ss.fffffff'))$utcOffsetStr"" " +
                "date=""$($timestamp.ToString('MM-dd-yyyy'))"" " +
                "component=""$Component"" context="""" " +
                "type=""$Severity"" thread=""$PID"" file="""">"

                # Ensure log directory exists
                if (-not (Test-Path -Path "$(Split-Path -Path $logFilePath)")) {
                    New-Item -ItemType 'Directory' -Path "$(Split-Path -Path $logFilePath)" | Out-Null
                }

                # Write to log file
                Add-Content -Path $logFilePath -Value $logEntry -Encoding 'UTF8' -ErrorAction 'Stop'

                # Output to verbose stream
                Write-Verbose -Message $Message
            }
            catch {
                Write-Warning "Failed to write to log file: $($_.Exception.Message)"
            }
        }
    }
    #endregion

    #region :: Logfile environment entries
    $region = 'environment'
    try {
        Write-Log -Message "## $title" -Component "$region"
        Write-Log -Message "Log file: $($logFilePath)" -Component "$region"
        Write-Log -Message "Script name: $($MyInvocation.MyCommand.Name)" -Component "$region"
        [string]$argsString = ''
        foreach ($key in $MyInvocation.BoundParameters.keys) {
            switch ($MyInvocation.BoundParameters[$key].GetType().Name) {
                'Boolean' {
                    $argsString += "-$key `$$($MyInvocation.BoundParameters[$key]) "
                }
                'Int32' {
                    $argsString += "-$key $($MyInvocation.BoundParameters[$key]) "
                }
                'String' {
                    $argsString += "-$key `"$($MyInvocation.BoundParameters[$key])`" "
                }
                'SwitchParameter' {
                    if ($MyInvocation.BoundParameters[$key].IsPresent) {
                        $argsString += "-$key "
                    }
                }
                Default {}
            }
        }
        Write-Log -Message "Command line: .\$($myInvocation.myCommand.name) $($argsString)" -Component "$region"
        Write-Log -Message "Running 64 bit PowerShell: $([System.Environment]::Is64BitProcess)" -Component "$region"
        Write-Log -Message "Running elevated: $(([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))" -Component "$region"
        Write-Log -Message "Detected user: $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)" -Component "$region"
        Write-Log -Message "Detected language mode: $($ExecutionContext.SessionState.LanguageMode)" -Component "$region"
        Write-Log -Message "Detected culture name: $((Get-Culture).Name)" -Component "$region"
        Write-Log -Message "Detected keyboard layout Id: $((Get-Culture).KeyboardLayoutId)" -Component "$region"
        Write-Log -Message "Detected computer name: $env:COMPUTERNAME" -Component "$region"
        Write-Log -Message "Detected OS version: $([environment]::OSVersion.Version)" -Component "$region"
        Write-Log -Message "Detected Windows UI culture name: $((Get-UICulture).Name)" -Component "$region"
        Write-Log -Message "Features bitmask: $Features (1=Rename:$deviceRenaming, 2=OOBE:$applyOOBERegistrySettings, 4=BitLocker:$validateBitLocker, 8=Location:$setLocationMarker)" -Component "$region"
    }
    catch {
        $errMsg = $_.Exception.Message
        Write-Log -Message "ERROR: $errMsg" -Component "$region" -Severity 3
    }
    finally {}
    #endregion
}
process {
    #region :: Device renaming
    # ---------------------------------------------------------------------------
    # Renames the computer based on the configured naming method:
    # - %SERIAL%: Uses the device serial number
    # - %RAND:x%: Uses x random digits
    # - Default: Uses a SHA256 hash of the serial number
    # ---------------------------------------------------------------------------
    $region = 'device-renaming'
    if ($deviceRenaming) {
        Write-Log -Message 'Device renaming is enabled.' -Component "$region"
        Write-Log -Message 'Starting device renaming process...' -Component "$region"
        try {
            #region :: Retrieve serial number
            Write-Log -Message 'Retrieving serial number...' -Component "$region"
            [string]$serialNumber = ((Get-CimInstance -ClassName Win32_BIOS -ErrorAction SilentlyContinue -Verbose:$false | Select-Object -ExpandProperty SerialNumber) -replace '-', '')
            if ($serialNumber) {
                Write-Log -Message "Serial number retrieved: $serialNumber" -Component "$region"
            }
            else {
                Write-Log -Message 'Serial number retrieval failed, using fallback value.' -Component "$region" -Severity 3
                [string]$serialNumber = $(New-Guid).Guid -replace '-', '' # Fallback value if serial number is not found
                Write-Log -Message "Fallback serial number: $serialNumber" -Component "$region"
            }
            #endregion
            #region :: Determine naming method
            if ($NamingMethod -match '%SERIAL%') {
                Write-Log -Message 'Using serial number for naming...' -Component "$region"
                $maxSerialLength = 15 - ($Prefix.Length + $Suffix.Length)
                $newName = "$Prefix$($serialNumber.Substring(0,$maxSerialLength))$Suffix"
                Write-Log -Message "Generated name: $newName" -Component "$region"
            }
            elseif ($NamingMethod -match '%RAND:(\d+)%') {
                Write-Log -Message 'Using random digits for naming...' -Component "$region"
                [int]$randomDigits = [int]$matches[1]
                if ($randomDigits -gt (15 - ($Prefix.Length + $Suffix.Length))) {
                    Write-Log -Message 'The total length of prefix, suffix, and random digits exceeds 15 characters. Truncating...' -Component "$region" -Severity 2
                    $randomDigits = 15 - ($Prefix.Length + $Suffix.Length)
                }
                Write-Log -Message "Using random number with $randomDigits digits for naming..." -Component "$region"
                $randomNumber = -join (1..$randomDigits | ForEach-Object { Get-Random -Minimum 0 -Maximum 10 })
                $newName = "$Prefix$randomNumber$Suffix"
                Write-Log -Message "Generated name: $newName" -Component "$region"
            }
            else {
                Write-Log -Message 'Using serial number hashing for naming...' -Component "$region"
                Write-Log -Message 'Generating hashed serial number...' -Component "$region"
                $sha256 = $null
                try {
                    $sha256 = [System.Security.Cryptography.SHA256]::Create()
                    $hash = $sha256.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($serialNumber))
                }
                finally {
                    if ($sha256) { $sha256.Dispose() }
                }
                $hashString = ([BitConverter]::ToString($hash)) -replace '-', ''
                Write-Log -Message "Generated hash: $hashString" -Component "$region"
                # Calculate maximum substring length based on prefix + suffix
                $maxHashLength = 15 - ($Prefix.Length + $Suffix.Length)
                Write-Log -Message "Using $maxHashLength characters from hash..." -Component "$region"
                # Define naming template (prefix + truncated hash + suffix)
                $newName = "$Prefix$($hashString.Substring(0, $maxHashLength))$Suffix" # Ensuring name not exceed 15 characters
                Write-Log -Message "Generated name: $newName" -Component "$region"
            }
            #endregion
            #region :: Validate name does not exceed 15 characters
            $region = 'device-renaming: name-validation'
            if ($newName.Length -gt 15) {
                Write-Log -Message 'Warning: The generated name exceeds 15 characters. Truncating...' -Component "$region" -Severity 2
                $newName = $newName.Substring(0, 15)
                Write-Log -Message "Truncated name: $newName" -Component "$region"
            }
            #endregion
            #region :: Validate name contains only valid NetBIOS characters
            $region = 'device-renaming: character-validation'
            if ($newName -match '[^a-zA-Z0-9-]') {
                Write-Log -Message 'Warning: The generated name contains invalid characters. Removing...' -Component "$region" -Severity 2
                $newName = $newName -replace '[^a-zA-Z0-9-]', ''
                Write-Log -Message "Sanitized name: $newName" -Component "$region"
                $null = $summary.Warnings.Add('Computer name contained invalid characters and was sanitized')
            }
            if ($newName -match '^-|-$') {
                Write-Log -Message 'Warning: The generated name starts or ends with a hyphen. Removing...' -Component "$region" -Severity 2
                $newName = $newName -replace '^-+|-+$', ''
                Write-Log -Message "Sanitized name: $newName" -Component "$region"
            }
            #endregion
        }
        catch {
            $errMsg = $_.Exception.Message
            Write-Log -Message "ERROR: $errMsg" -Component "$region" -Severity 3
        }
        finally {
        }
        #region :: Rename device
        $region = 'device-renaming: rename-device'
        if ([string]::IsNullOrEmpty($newName)) {
            Write-Log -Message 'Error: Generated computer name is empty. Skipping rename.' -Component "$region" -Severity 3
            $null = $summary.Errors.Add('Generated computer name was empty')
        }
        elseif ($Prefix.Length -gt 0 -and $newName.Length -ge $Prefix.Length -and $env:COMPUTERNAME.Length -ge $Prefix.Length -and $newName.Substring(0, $Prefix.Length) -eq $env:COMPUTERNAME.Substring(0, $Prefix.Length)) {
            Write-Log -Message 'The computer name already starts with the specified prefix.' -Component "$region"
            Write-Log -Message 'No renaming required.' -Component "$region"
            Write-Log -Message "Current name: $($env:COMPUTERNAME)" -Component "$region"
        }
        else {
            Write-Log -Message 'Renaming device...' -Component "$region"
            if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, "Rename computer to '$newName'")) {
                try {
                    $renameStatus = Rename-Computer -NewName $newName -Force -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -Verbose:$false -PassThru
                    # Check if the rename operation was successful
                    if ($renameStatus.HasSucceeded) {
                        Write-Log -Message 'Device renamed successfully' -Component "$region"
                        Write-Log -Message "Has Succeeded: $($renameStatus.HasSucceeded)" -Component "$region"
                        Write-Log -Message "New name: $($renameStatus.NewComputerName)" -Component "$region"
                        Write-Log -Message "Old name: $($renameStatus.OldComputerName)" -Component "$region"
                        Write-Log -Message 'The changes will take effect after restarting the computer.' -Component "$region" -Severity 2
                        $summary.DeviceRenamed = $true
                    }
                    else {
                        Write-Log -Message 'Device renaming failed.' -Component "$region" -Severity 2
                        $null = $summary.Warnings.Add('Device renaming failed')
                    }
                }
                catch {
                    $errMsg = $_.Exception.Message
                    Write-Log -Message "ERROR: $errMsg" -Component "$region" -Severity 3
                    $null = $summary.Errors.Add("Device renaming: $errMsg")
                }
                finally {}
            }
            else {
                Write-Log -Message "WhatIf: Would rename computer from '$($env:COMPUTERNAME)' to '$newName'" -Component "$region"
            }
            #region :: Mark device for pending reboot (without forcing it)
            $region = 'device-renaming: pending-reboot'
            if ($renameStatus.HasSucceeded) {
                Write-Log -Message 'Adding pending reboot flag...' -Component "$region"
                if ($PSCmdlet.ShouldProcess('Registry', 'Add pending reboot flag')) {
                    try {
                        $null = New-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update' -PropertyType 'String' -Name 'RebootRequired' -Value 1 -Force
                    }
                    catch {
                        $errMsg = $_.Exception.Message
                        Write-Log -Message "ERROR: $errMsg" -Component "$region" -Severity 3
                    }
                    finally {}
                }
            }
            #endregion
        }
        #endregion
        Write-Log -Message 'Device renaming process completed.' -Component "$region"
    }
    else {
        Write-Log -Message 'Device renaming is disabled.' -Component "$region"
    }
    #endregion

    #region :: Apply OOBE registry settings
    # ---------------------------------------------------------------------------
    # Configures Windows Out-of-Box Experience (OOBE) settings:
    # - Disables Privacy Experience prompts
    # - Disables Voice features
    # - Sets Privacy Consent status
    # - Configures ProtectYourPC settings
    # - Hides the EULA page
    # ---------------------------------------------------------------------------
    $region = 'OOBE-registry-settings'
    if ($applyOOBERegistrySettings) {
        Write-Log -Message 'Setting OOBE registry settings is enabled.' -Component "$region"
        Write-Log -Message 'Starting OOBE registry settings...' -Component "$region"
        # Set registry values to configure OOBE settings as per best practices for Autopilot devices.
        if ($PSCmdlet.ShouldProcess('OOBE Registry Settings', 'Apply OOBE configuration')) {
            try {
                Write-Log -Message 'Disabling Privacy Experience...' -Component "$region"
                $null = New-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE' -PropertyType 'DWord' -Name 'DisablePrivacyExperience' -Value 1 -Force
                Write-Log -Message 'Disabling Voice features...' -Component "$region"
                $null = New-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE' -PropertyType 'DWord' -Name 'DisableVoice' -Value 1 -Force
                Write-Log -Message 'Setting Privacy Consent status...' -Component "$region"
                $null = New-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE' -PropertyType 'DWord' -Name 'PrivacyConsentStatus' -Value 1 -Force
                Write-Log -Message 'Setting Protection settings...' -Component "$region"
                $null = New-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE' -PropertyType 'DWord' -Name 'ProtectYourPC' -Value 3 -Force
                Write-Log -Message 'Hiding the End User License Agreement (EULA) page...' -Component "$region"
                $null = New-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE' -PropertyType 'DWord' -Name 'HideEULAPage' -Value 1 -Force
                Write-Log -Message 'OOBE registry settings applied successfully.' -Component "$region"
                $summary.OOBESettingsApplied = $true
            }
            catch {
                $errMsg = $_.Exception.Message
                Write-Log -Message "ERROR: $errMsg" -Component "$region" -Severity 3
                $null = $summary.Errors.Add("OOBE settings: $errMsg")
            }
            finally {}
        }
        else {
            Write-Log -Message 'WhatIf: Would apply OOBE registry settings' -Component "$region"
        }
        Write-Log -Message 'OOBE registry settings process completed.' -Component "$region"
    }
    else {
        Write-Log -Message 'OOBE registry settings is disabled.' -Component "$region"
    }
    #endregion

    #region :: BitLocker Validation
    # ---------------------------------------------------------------------------
    # Validates the BitLocker encryption status on the system drive:
    # - Checks if BitLocker protection is enabled
    # - Reports encryption method and key protectors
    # - Warns if volume is not fully encrypted
    # ---------------------------------------------------------------------------
    $region = 'validate-bitlocker'
    if ($validateBitLocker) {
        Write-Log -Message 'BitLocker Drive Encryption validation is enabled.' -Component "$region"
        Write-Log -Message 'Starting BitLocker Drive Encryption validation process...' -Component "$region"
        try {
            # Get BitLocker status for the system drive
            $bitlockerStatus = Get-BitLockerVolume -MountPoint $($env:SystemDrive) -ErrorAction SilentlyContinue

            # Log retrieved BitLocker status details
            if ($bitlockerStatus) {
                Write-Log -Message 'BitLocker Drive Encryption status retrieved successfully.' -Component "$region"
                if ($bitlockerStatus.ProtectionStatus -eq 'On') {
                    Write-Log -Message 'BitLocker Drive Encryption is enabled on the system drive.' -Component "$region"
                    Write-Log -Message "BitLocker Drive Encryption Volume: $($bitlockerStatus.MountPoint)" -Component "$region"
                    Write-Log -Message "Protection Status: $($bitlockerStatus.ProtectionStatus)" -Component "$region"
                    Write-Log -Message "Encryption Method: $($bitlockerStatus.EncryptionMethod)" -Component "$region"
                    Write-Log -Message "Key Protectors: $($bitlockerStatus.KeyProtectors | ForEach-Object { $_.KeyProtectorType })" -Component "$region"
                    Write-Log -Message "Volume Status: $($bitlockerStatus.VolumeStatus)" -Component "$region"

                    # Check if the volume is fully encrypted
                    if ($bitlockerStatus.VolumeStatus -ne 'FullyEncrypted') {
                        Write-Log -Message 'Warning: BitLocker Drive Encryption volume is not fully encrypted.' -Component "$region" -Severity 2
                        $null = $summary.Warnings.Add('BitLocker Drive Encryption volume is not fully encrypted')
                    }
                    else {
                        Write-Log -Message 'BitLocker Drive Encryption volume is fully encrypted.' -Component "$region"
                    }
                    $summary.BitLockerValidated = $true
                }
                else {
                    Write-Log -Message 'BitLocker Drive Encryption is not enabled on the system drive.' -Component "$region" -Severity 2
                    $null = $summary.Warnings.Add('BitLocker Drive Encryption is not enabled on the system drive')
                }
            }
            else {
                Write-Log -Message 'BitLocker Drive Encryption status retrieval failed.' -Component "$region" -Severity 2
            }
        }
        catch {
            $errMsg = $_.Exception.Message
            Write-Log -Message "ERROR: $errMsg" -Component "$region" -Severity 3
        }
        finally {}
        Write-Log -Message 'BitLocker Drive Encryption validation process completed.' -Component "$region"
    }
    else {
        Write-Log -Message 'BitLocker Drive Encryption validation is disabled.' -Component "$region"
    }
    #endregion

    #region :: Location marker
    # ---------------------------------------------------------------------------
    # Creates a registry-based location marker for language and region settings.
    # This can be used by other scripts or policies to determine device location
    # and apply appropriate regional configurations.
    # ---------------------------------------------------------------------------
    $region = 'set-location-marker'
    if ($setLocationMarker) {
        Write-Log -Message 'Setting location marker is enabled.' -Component "$region"
        Write-Log -Message 'Starting location marker setting process...' -Component "$region"

        # Check if a location marker value is provided before attempting to set it
        if ($LocationMarker.Length -gt 0) {
            Write-Log -Message 'Location marker provided.' -Component "$region"
            Write-Log -Message 'Setting location marker...' -Component "$region"

            # Adding a location marker in the registry.
            # This can be used by other scripts or policies to determine device location and apply appropriate regional configurations.
            if ($PSCmdlet.ShouldProcess("$LocationMarkerPath", "Set location marker to '$LocationMarker'")) {
                try {
                    $null = New-ItemProperty -Path "$LocationMarkerPath" -PropertyType 'String' -Name 'LocationMarker' -Value $LocationMarker -Force
                    Write-Log -Message "Location marker path: $LocationMarkerPath" -Component "$region"
                    Write-Log -Message "Location marker value: $LocationMarker" -Component "$region"
                    Write-Log -Message 'Location marker set successfully.' -Component "$region"
                    $summary.LocationMarkerSet = $true
                }
                catch {
                    $errMsg = $_.Exception.Message
                    Write-Log -Message "ERROR: $errMsg" -Component "$region" -Severity 3
                    $null = $summary.Errors.Add("Location marker: $errMsg")
                }
                finally {}
            }
            else {
                Write-Log -Message "WhatIf: Would set location marker to '$LocationMarker' at '$LocationMarkerPath'" -Component "$region"
            }
        }
        else {
            Write-Log -Message 'No location marker provided. Skipping...' -Component "$region"
        }
        Write-Log -Message 'Location marker setting process completed.' -Component "$region"
    }
    else {
        Write-Log -Message 'Setting location marker is disabled.' -Component "$region"
    }
    #endregion
}
end {
    #region :: Summary
    $region = 'summary'
    Write-Log -Message 'Execution Summary' -Component "$region"
    Write-Log -Message "Device Renamed: $($summary.DeviceRenamed)" -Component "$region"
    Write-Log -Message "OOBE Settings Applied: $($summary.OOBESettingsApplied)" -Component "$region"
    Write-Log -Message "BitLocker Drive Encryption Validated: $($summary.BitLockerValidated)" -Component "$region"
    Write-Log -Message "Location Marker Set: $($summary.LocationMarkerSet)" -Component "$region"

    # Log warnings and errors from the execution summary
    if ($summary.Warnings.Count -gt 0) {
        Write-Log -Message "Warnings ($($summary.Warnings.Count)):" -Component "$region" -Severity 2
        foreach ($warning in $summary.Warnings) {
            Write-Log -Message "$warning" -Component "$region" -Severity 2
        }
    }
    if ($summary.Errors.Count -gt 0) {
        Write-Log -Message "Errors ($($summary.Errors.Count)):" -Component "$region" -Severity 3
        foreach ($errorItem in $summary.Errors) {
            Write-Log -Message "$errorItem" -Component "$region" -Severity 3
        }
    }
    #endregion

    #region :: End of script
    $region = 'end'
    Write-Log -Message "Total execution time: $((New-TimeSpan -Start $script:startTime -End (Get-Date).ToUniversalTime()).ToString('hh\:mm\:ss\.fff'))" -Component "$region"
    Write-Log -Message 'Windows Autopilot Device Preparation script completed.' -Component "$region"
    if ($renameStatus -and $renameStatus.HasSucceeded) {
        Write-Log -Message 'A reboot is pending, but will not be forced.' -Component "$region" -Severity 2
    }

    # Exit with code 1 if there were any errors, otherwise exit with code 0
    if ($summary.Errors.Count -gt 0) {
        exit 1
    }
    else {
        exit 0
    }
    #endregion
}
