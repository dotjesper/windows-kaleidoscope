<#
.SYNOPSIS
    Show pending reboot notification

.DESCRIPTION
    Display a toast notification to inform the user about a pending reboot and write
    a notification cooldown marker to the registry. The marker prevents the detection
    script from re-triggering remediation within the configured cooldown period.

.PARAMETER notificationScenario
    Specify notification scenario (reminder | default). Default is reminder.

.EXAMPLE
    .\remediate.ps1

    Displays a toast notification about the pending reboot and writes a cooldown marker.

.NOTES
    version: 1.0.0
    date: April 13, 2025
    license: MIT License

.LINK
    https://github.com/dotjesper/windows-kaleidoscope
#>

#requires -Version 5.1

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false, HelpMessage = 'Specify notification scenario (reminder | default)')]
    [ValidateSet('reminder', 'default')]
    [string]$notificationScenario = 'reminder'
)

begin {
    Set-StrictMode -Version Latest

    # variables :: conditions
    [bool]$runScriptIn64bitPowerShell = $false
    [bool]$runUsingLoggedOnCredentials = $true
    [bool]$script:isConstrainedLanguageMode = $ExecutionContext.SessionState.LanguageMode -eq 'ConstrainedLanguage'

    # variables :: environment
    [string]$markerRegRoot = 'HKCU'
    [string]$markerRegPath = 'SOFTWARE\windows-kaleidoscope\monitor-pending-reboots'
    [string]$detectedSystemLocale = (Get-WinSystemLocale).Name

    # variables :: pending reboot duration
    [string]$pendingDaysText = ''
    $firstSeenProp = Get-ItemProperty -Path "Registry::$markerRegRoot\$markerRegPath" -Name 'FirstSeenDate' -ErrorAction SilentlyContinue
    if ($firstSeenProp) {
        [int]$pendingDays = ((Get-Date) - (Get-Date -Date $firstSeenProp.FirstSeenDate)).Days
        $pendingDaysText = "$pendingDays"
    }

    # variables :: notification images
    [string]$base64HeroImage = ''
    [string]$notificationHeroImage = "$env:TEMP\pendingRebootHeroImage.png"

    # variables :: notification strings
    # Notification strings use XML numeric character references (e.g. &#xe5; for the letter a-ring)
    # to avoid Unicode encoding issues with PowerShell 5.1 and keep the file as pure ASCII.
    switch ($detectedSystemLocale) {
        'da-DK' {
            [string]$attributionText = 'Microsoft Intune'
            [string]$notificationHeader = 'Handling p&#xe5;kr&#xe6;vet: Genstart din enhed'
            [string]$notificationTitle = "En genstart har afventet i $pendingDaysText dage."
            [string]$notificationBody1 = 'Vigtige opdateringer og system&#xe6;ndringer afventer at blive anvendt.'
            [string]$notificationBody2 = 'Gem dit arbejde og genstart din enhed ved f&#xf8;rst givne lejlighed.'
            [string]$dismissButtonText = 'Afvis'
        }
        'de-DE' {
            [string]$attributionText = 'Microsoft Intune'
            [string]$notificationHeader = 'Aktion erforderlich: Ger&#xe4;t neu starten'
            [string]$notificationTitle = "Ein Neustart steht seit $pendingDaysText Tagen aus."
            [string]$notificationBody1 = 'Wichtige Updates und System&#xe4;nderungen warten auf die Anwendung.'
            [string]$notificationBody2 = 'Bitte speichern Sie Ihre Arbeit und starten Sie Ihr Ger&#xe4;t bei n&#xe4;chster Gelegenheit neu.'
            [string]$dismissButtonText = 'Schlie&#xdf;en'
        }
        default {
            [string]$attributionText = 'Microsoft Intune'
            [string]$notificationHeader = 'Action required: Restart your device'
            [string]$notificationTitle = "A restart has been pending for $pendingDaysText days."
            [string]$notificationBody1 = 'Important updates and system changes are waiting to be applied.'
            [string]$notificationBody2 = 'Please save your work and restart your device at your earliest convenience.'
            [string]$dismissButtonText = 'Dismiss'
        }
    }

    # variables :: toast notification XML template
    [string]$heroImageElement = ''
    if ($base64HeroImage -ne '') {
        $heroImageElement = "<image placement=`"hero`" src=`"$notificationHeroImage`" />"
    }
    [string]$toastTemplateString = @"
<toast scenario="$notificationScenario">
    <visual>
        <binding template="ToastGeneric">
            $heroImageElement
            <text hint-style="header">$notificationHeader</text>
            <text hint-style="subtitle" hint-wrap="true">$notificationTitle</text>
            <group>
                <subgroup>
                    <text hint-style="body" hint-wrap="true">$notificationBody1</text>
                </subgroup>
            </group>
            <group>
                <subgroup>
                    <text hint-style="body" hint-wrap="true">$notificationBody2</text>
                </subgroup>
            </group>
            <group>
                <subgroup>
                    <text hint-style="captionSubtle" hint-wrap="true">Message from $attributionText</text>
                </subgroup>
            </group>
        </binding>
    </visual>
    <actions>
        <action activationType="system" arguments="dismiss" content="$dismissButtonText" />
    </actions>
</toast>
"@
}
process {
    #region :: check conditions
    if ($runScriptIn64bitPowerShell -eq $true -and $([System.Environment]::Is64BitProcess) -eq $false) {
        Write-Error -Message 'Windows PowerShell 64-bit is required.' -Category 'ResourceUnavailable' -ErrorId 'B001'
        exit 1
    }
    if ($runUsingLoggedOnCredentials -eq $true -and $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name -eq 'NT AUTHORITY\SYSTEM')) {
        Write-Error -Message 'Script is running as SYSTEM. Please configure the script to run using logged-on credentials.' -Category 'ResourceUnavailable' -ErrorId 'B002'
        exit 1
    }
    #endregion

    #region :: main logic
    try {
        # write notification cooldown marker
        if (Test-Path -Path $($markerRegRoot + ':\' + $markerRegPath)) {
            $null = New-ItemProperty -Path "Registry::$markerRegRoot\$markerRegPath" -Name 'NotificationSentDate' -Value (Get-Date -Format 'yyyy-MM-ddTHH:mm:ss') -PropertyType 'String' -Force
        }
        else {
            $null = New-Item -Path "Registry::$markerRegRoot\$markerRegPath" -Force
            $null = New-ItemProperty -Path "Registry::$markerRegRoot\$markerRegPath" -Name 'NotificationSentDate' -Value (Get-Date -Format 'yyyy-MM-ddTHH:mm:ss') -PropertyType 'String' -Force
        }

        # check language mode for toast notification compatibility
        if ($script:isConstrainedLanguageMode -eq $true) {
            Write-Error -Message 'Toast notification requires full language mode. Notification marker was written but notification could not be displayed.' -Category 'ResourceUnavailable' -ErrorId 'B003'
            exit 0
        }

        # register custom AppID for use with Action Center
        [string]$appID = 'windows-kaleidoscope.monitor-pending-reboots'
        [string]$appRegRoot = 'HKCU'
        [string]$appRegPath = 'SOFTWARE\Classes\AppUserModelId'
        if (-not (Test-Path -Path $($appRegRoot + ':\' + $appRegPath + '\' + $appID))) {
            $null = New-Item -Path "Registry::$appRegRoot\$appRegPath\$appID" -Force
        }

        # set custom AppID properties
        $null = New-ItemProperty -Path "Registry::$appRegRoot\$appRegPath\$appID" -Name 'DisplayName' -Value $attributionText -PropertyType 'String' -Force
        $null = New-ItemProperty -Path "Registry::$appRegRoot\$appRegPath\$appID" -Name 'ShowInSettings' -Value 0 -PropertyType 'DWORD' -Force

        # register custom AppID for toast notifications and Action Center
        [string]$notifRegPath = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings'
        if (-not (Test-Path -Path $($appRegRoot + ':\' + $notifRegPath + '\' + $appID))) {
            $null = New-Item -Path "Registry::$appRegRoot\$notifRegPath\$appID" -Force
            $null = New-ItemProperty -Path "Registry::$appRegRoot\$notifRegPath\$appID" -Name 'ShowInActionCenter' -Value 1 -PropertyType 'DWORD' -Force
        }

        # prepare notification hero image
        if ($base64HeroImage -ne '') {
            [byte[]]$bytes = [System.Convert]::FromBase64String($base64HeroImage)
            [System.IO.File]::WriteAllBytes($notificationHeroImage, $bytes)
        }

        # load namespaces
        $null = [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
        $null = [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime]

        # display notification
        $toastXml = New-Object -TypeName Windows.Data.Xml.Dom.XmlDocument
        $toastXml.LoadXml($toastTemplateString)
        [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($appID).Show($toastXml)
        exit 0
    }
    catch {
        $errMsg = $_.Exception.Message
        Write-Error -Message $errMsg -Category 'SyntaxError' -ErrorId 'C001'
        exit 1
    }
    finally {}
    #endregion
}
end {}
