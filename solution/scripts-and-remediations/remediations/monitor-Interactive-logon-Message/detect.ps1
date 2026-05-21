<#
.SYNOPSIS
    Monitor Interactive Logon Message

.DESCRIPTION
    Monitor Interactive Logon Message is often used in secure environments, but can also be used as a prototype notification for e.g., pilot users or alike.
    The configuration is configured using Local Policies: Security Options, using
    - Interactive Logon Message Title For Users Attempting To Log On
    - Interactive Logon Message Text For Users Attempting To Log On
    Removing the policy might fail to remove the tattooed settings, and this solution will attempt to clear the two configurations.
        [HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System]
        LegalNoticeCaption=""
        LegalNoticeText=""

.EXAMPLE
    .\detect.ps1

    Run the script with default parameters.

.NOTES
    version: 1.1.0
    date: April 10, 2026
    license: MIT License

.LINK
    https://github.com/dotjesper/windows-kaleidoscope
#>

#requires -Version 5.1

[CmdletBinding()]
param ()

begin {
    Set-StrictMode -Version Latest

    # variables :: Conditions
    [bool]$runScriptIn64bitPowerShell = $true

    # variables :: Environment
    [string]$regRoot = 'HKLM'
    [string]$regPath = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
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
        if (Test-Path -Path $($regRoot + ':\' + $regPath)) {
            # Check if the registry values for Interactive Logon Message are configured
            $regLegalNoticeCaption = Get-ItemProperty -Path "Registry::$regRoot\$regPath" -Name 'LegalNoticeCaption' -ErrorAction SilentlyContinue
            [string]$currentLegalNoticeCaption = if ($null -ne $regLegalNoticeCaption) { $regLegalNoticeCaption.LegalNoticeCaption } else { '' }

            # Check if the registry values for Interactive Logon Message are configured
            $regLegalNoticeText = Get-ItemProperty -Path "Registry::$regRoot\$regPath" -Name 'LegalNoticeText' -ErrorAction SilentlyContinue
            [string]$currentLegalNoticeText = if ($null -ne $regLegalNoticeText) { $regLegalNoticeText.LegalNoticeText } else { '' }

            # Evaluate the results
            if (($currentLegalNoticeCaption -ne '') -or ($currentLegalNoticeText -ne '')) {
                Write-Verbose -Message 'Interactive Logon Message configurations found.'
                Write-Verbose -Message "Interactive Logon Message Title For Users Attempting To Log On: $currentLegalNoticeCaption."
                Write-Verbose -Message "Interactive Logon Message Text For Users Attempting To Log On: $currentLegalNoticeText."
                [string]$elapsedTime = ('{0:00.000}' -f ((Get-Date).ToUniversalTime() - $scriptStartTime).TotalSeconds) -replace ',', '.'
                Write-Output -InputObject "[$elapsedTime] Interactive Logon Message found: LegalNoticeCaption='$currentLegalNoticeCaption', LegalNoticeText='$currentLegalNoticeText'"
                exit 1
            }
            else {
                [string]$elapsedTime = ('{0:00.000}' -f ((Get-Date).ToUniversalTime() - $scriptStartTime).TotalSeconds) -replace ',', '.'
                Write-Output -InputObject "[$elapsedTime] Interactive Logon Message values not configured."
                exit 0
            }
        }
        else {
            [string]$elapsedTime = ('{0:00.000}' -f ((Get-Date).ToUniversalTime() - $scriptStartTime).TotalSeconds) -replace ',', '.'
            Write-Output -InputObject "[$elapsedTime] Interactive Logon Message configurations not found."
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
