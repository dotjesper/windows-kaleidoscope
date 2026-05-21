@{
    Severity = @(
        'Error'
    )

    IncludeDefaultRules = $true

    Rules = @{
        # Disable formatting rules for CI speed — focus on correctness only
        PSUseConsistentIndentation = @{
            Enable = $false
        }

        PSUseConsistentWhitespace = @{
            Enable = $false
        }

        PSPlaceOpenBrace = @{
            Enable = $false
        }

        PSPlaceCloseBrace = @{
            Enable = $false
        }

        PSAlignAssignmentStatement = @{
            Enable = $false
        }

        PSAvoidLongLines = @{
            Enable = $false
        }
    }
}
