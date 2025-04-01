#requires -Version 5.1
<#
.SYNOPSIS
    Manage & removing dublicated files.
.DESCRIPTION
    Find and remove files containing "*- copy.*" in file name.
    In some rare cases some clean-up might be requered if on-prem Folder Redirection is migrated to Microsoft OneDrive for Business Known Folder Move (KFM) - in some case dublicated files containing * - Copy.* might be created, this script will find and can delete the files.
.EXAMPLE
    .\detect.ps1
.NOTES
    version: 0.9.0.0
    date: February 16, 2022
    license: MIT License
.LINK
    [Jesper on Bluesky](https://bsky.app/profile/dotjesper.bsky.social "Jesper on Bluesky")
    [Jesper on GitHub](https://github.com/dotjesper/ "Jesper on GitHub")
#>
[CmdletBinding()]
param (
    #variables
    [int]$ignoreFilesOlderThan = 0, # Value in days - 0 will disable ignoring files based on timestamp.
    [string]$searchString = "* - copy.*",
    [string]$filePath = "$env:OneDriveCommercial"
)
begin {
    #variables :: conditions
    [bool]$runScriptIn64bitPowerShell = $false
    #variables :: environment
    [array]$fileCollection = @()
    #variables :: logfile
    [string]$fLogContentpkg = "prDublicatedFiles"
    [string]$fLogContentFile = "$($Env:ProgramData)\Microsoft\IntuneManagementExtension\Logs\$fLogContentpkg.log"
    #region :: functions
    function fLogContent () {
        <#
        .SYNOPSIS
            Log-file function.
        .DESCRIPTION
            Log-file function, write a single log line when called.
            Each line in the log can have various attributes, log text, information about the component from which the fumction is called and an option to specify log file name for each entry.
            Formatting adhere to the CMTrace and Microsoft Intune log format.
            Standard log types
            1: MessageTypeInfo - Informational Message (Default)
            2: MessageTypeWarning - Warning Message
            3: MessageTypeError - Error Message
        .PARAMETER fLogContent
            Holds the string to write to the log file. If script is called with the -Verbose, this string will be sent to the console.
        .PARAMETER fLogContentComponent
            Information about the component from which the fumction is called, e.g. a specific section in the script.
        .PARAMETER fLogContentType
            Standard log types
            1: MessageTypeInfo - Informational Message (Default)
            2: MessageTypeWarning - Warning Message
            3: MessageTypeError - Error Message
        .PARAMETER fLogContentfn
            Option to specify log file name for each entry.
        .EXAMPLE
            fLogContent -fLogContent "This is the log string." -fLogContentComponent "If applicable, add section, or component for log entry."
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory = $true)]
            [string]$fLogContent,
            [Parameter(Mandatory = $false)]
            [string]$fLogContentComponent,
            [Parameter(Mandatory = $false)]
            [ValidateSet(1,2,3)]
            [int]$fLogContentType = 1,
            [Parameter(Mandatory = $false)]
            [string]$fLogContentfn = $fLogContentFile
        )
        begin {
            $fdate = $(Get-Date -Format "M-dd-yyyy")
            $ftime = $(Get-Date -Format "HH:mm:ss.fffffff")
        }
        process {
            if ($fLogContentDisable) {
            }
            else {
                try {
                    if (-not (Test-Path -Path "$(Split-Path -Path $fLogContentfn)")) {
                        New-Item -itemType "Directory" -Path "$(Split-Path -Path $fLogContentfn)" | Out-Null
                    }
                    Add-Content -Path $fLogContentfn -Value "<![LOG[[$fLogContentpkg] $($fLogContent)]LOG]!><time=""$($ftime)"" date=""$($fdate)"" component=""$fLogContentComponent"" context="""" type=""$fLogContentType"" thread="""" file="""">" -Encoding "UTF8" | Out-Null
                }
                catch {
                    throw $_.Exception.Message
                    exit 1
                }
                finally {}
            }
            Write-Verbose -Message "$($fLogContent)"
        }
        end {}
    }
}
process {
    #region :: check conditions
    if ($runScriptIn64bitPowerShell -eq $true -and $([System.Environment]::Is64BitProcess) -eq $false) {
        fLogContent -fLogContent "Windows PowerShell 64-bit is requered - script exiting." -fLogContentType 2
        Write-Output -InputObject "Windows PowerShell 64-bit is requered - script exiting."
        exit 1
    }
    #endregion
    #region :: main
    try {
        [int]$fileCounter = 0
        fLogContent -fLogContent "Looking for files containing '$searchString' in path '$filePath'."
        [array]$files = Get-ChildItem -Path $filePath -Recurse -File -Filter $searchString
        if ($files.Count -gt 0) {
            fLogContent -fLogContent "Found $($files.Count) file(s) matching searchstring."
            foreach ($file in $files) {
                if (($($file.CreationTime) -gt $((Get-Date).AddDays(-$ignoreFilesOlderThan))) -and $ignoreFilesOlderThan -gt 0) {
                    fLogContent -fLogContent "File name $($file.FullName)."
                    fLogContent -fLogContent "File creation time $($file.CreationTime)."
                    fLogContent -fLogContent "File last write time $($file.LastWriteTime)."
                    fLogContent -fLogContent "File created after $((Get-Date).AddDays(-$ignoreFilesOlderThan))."
                    [int]$fileCounter = $fileCounter + 1
                }
                else {
                    fLogContent -fLogContent "File name $($file.FullName)."
                    fLogContent -fLogContent "File creation time $($file.CreationTime)."
                    fLogContent -fLogContent "File last write Time $($file.LastWriteTime)."
                }
                Write-Verbose -Message "Adding file information to data collection"
                [array]$fileCollection += [PSCustomObject] @{
                    "Action"                = "Detected"
                    "File name"             = $($file.FullName)
                    "File creation time"    = $($file.CreationTime)
                    "File last access time" = $($file.LastAccessTime)
                    "File last write time"  = $($file.LastWriteTime)
                    "File size"             = $($file.Length)
                    "File is read only"     = $($file.IsReadOnly)
                }
            }
            Write-Verbose -Message "Saving file collection to $($fLogContentFile.Replace(".log",".csv"))"
            $fileCollection | Export-Csv -Path $($fLogContentFile.Replace(".log",".csv")) -Encoding "UTF8" -Delimiter ";" -NoTypeInformation -NoClobber -Append -Force
            if ($ignoreFilesOlderThan -gt 0) {
                fLogContent -fLogContent "Found $($files.Count) file(s) containing the search string '$searchString' - $($fileCounter) files created after $((Get-Date).AddDays(-$ignoreFilesOlderThan))."
                Write-Output -InputObject "Found $($files.Count) file(s) containing the search string '$searchString' - $($fileCounter) files created after $((Get-Date).AddDays(-$ignoreFilesOlderThan))."
            }
            else {
                fLogContent -fLogContent "Found $($files.Count) file(s) containing the search string '$searchString'."
                Write-Output -InputObject "Found $($files.Count) file(s) containing the search string '$searchString'."
            }
            exit 1
        }
        else {
            fLogContent -fLogContent "No files found containing the search string '$searchString'."
            Write-Output -InputObject "No files found containing the search string '$searchString'."
            exit 0
        }
    }
    catch {
        $errMsg = $_.Exception.Message
        fLogContent -fLogContent "$errMsg" -fLogContentType 3
        Write-Error -Message $errMsg -Category "SyntaxError" -ErrorId "C001"
        exit 1
    }
    finally {}
    #endregion
}
end {}
