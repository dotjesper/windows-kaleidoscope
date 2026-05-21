function Measure-UTF8NoBOMAndLF {
    <#
    .SYNOPSIS
        Check that PowerShell files use UTF-8 without BOM and LF line endings.

    .DESCRIPTION
        Custom PSScriptAnalyzer rule that checks PowerShell files for UTF-8 BOM
        and CRLF line endings. Emits a warning diagnostic for each violation.

    .PARAMETER ScriptBlockAst
        The script block AST node provided by PSScriptAnalyzer.
    #>
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord])]
    param(
        [Parameter(Mandatory)]
        [System.Management.Automation.Language.ScriptBlockAst] $ScriptBlockAst
    )

    # Get file path from the AST extent
    [string]$filePath = $ScriptBlockAst.Extent.File
    if ([string]::IsNullOrEmpty($filePath)) {
        return
    }

    # Only process the root ScriptBlockAst to avoid duplicate diagnostics
    if ($null -ne $ScriptBlockAst.Parent) {
        return
    }

    # Only analyze PowerShell-related files
    $validExtensions = '.ps1', '.psm1', '.psd1', '.ps1xml'
    if (-not ($validExtensions -contains ([IO.Path]::GetExtension($filePath)))) {
        return
    }

    # --- Read raw bytes for BOM detection ---
    $bytes = [IO.File]::ReadAllBytes($filePath)

    $hasBOM = $false
    if ($bytes.Length -ge 3) {
        $hasBOM = ($bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
    }

    # --- Read text for newline detection ---
    $content = [IO.File]::ReadAllText($filePath)

    $hasCRLF = $content -match "`r`n"

    # --- Emit diagnostics ---
    [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticSeverity]$warningSeverity = 'Warning'

    if ($hasBOM) {
        New-Object -TypeName 'Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord' -ArgumentList @(
            'File must be UTF-8 without BOM. A UTF-8 BOM was detected.',
            $ScriptBlockAst.Extent,
            'UTF8NoBOMAndLF',
            $warningSeverity,
            $filePath,
            $null,
            $null
        )
    }

    if ($hasCRLF) {
        New-Object -TypeName 'Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord' -ArgumentList @(
            'File must use LF line endings only. CRLF sequences were detected.',
            $ScriptBlockAst.Extent,
            'UTF8NoBOMAndLF',
            $warningSeverity,
            $filePath,
            $null,
            $null
        )
    }
}

Export-ModuleMember -Function Measure-UTF8NoBOMAndLF
