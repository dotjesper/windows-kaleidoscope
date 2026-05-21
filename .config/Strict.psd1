@{
    Severity = @(
        'Error'
        'Warning'
        'Information'
    )

    # Custom rules can be defined in separate .psm1 files and imported here.
    # This allows for modular organization of rules (e.g., by category or purpose) and keeps the main configuration file focused on rule selection and settings.
    CustomRulePath = @(
        '.\.config\FileFormatRules.psm1'
    )

    # Enable all default rules, then override specific rules below
    IncludeDefaultRules = $true

    Rules = @{

        #region Code style rules

        # Flag use of ! operator instead of -not
        PSAvoidExclaimOperator = @{
            Enable = $true
        }

        # Flag lines longer than 150 characters
        # Disabled to avoid false positives in long URLs, comments, or code that is more readable on a single line
        PSAvoidLongLines = @{
            Enable            = $false
            MaximumLineLength = 150
        }

        # Flag semicolons used as line terminators
        PSAvoidSemicolonsAsLineTerminators = @{
            Enable = $true
        }

        # Enforce single quotes for constant strings (flag unnecessary double quotes)
        PSAvoidUsingDoubleQuotesForConstantString = @{
            Enable = $true
        }

        #endregion

        #region Formatting rules

        # Align assignment statements (hash table formatting)
        PSAlignAssignmentStatement = @{
            Enable         = $true
            CheckHashtable = $true
        }

        # Place closing brace on its own line
        PSPlaceCloseBrace = @{
            Enable             = $true
            NewLineAfter       = $true
            IgnoreOneLineBlock = $true
            NoEmptyLineBefore  = $true
        }

        # Place opening brace on same line
        PSPlaceOpenBrace = @{
            Enable             = $true
            OnSameLine         = $true
            NewLineAfter       = $true
            IgnoreOneLineBlock = $true
        }

        # Enforce consistent indentation (4 spaces, no tabs)
        PSUseConsistentIndentation = @{
            Enable              = $true
            IndentationSize     = 4
            PipelineIndentation = 'IncreaseIndentationForFirstPipeline'
            Kind                = 'space'
        }

        # Enforce consistent whitespace around braces, parentheses, operators, pipes, and separators
        PSUseConsistentWhitespace = @{
            Enable                                  = $true
            CheckInnerBrace                         = $true
            CheckOpenBrace                          = $true
            CheckOpenParen                          = $true
            CheckOperator                           = $true
            CheckPipe                               = $true
            CheckPipeForRedundantWhitespace         = $true
            CheckSeparator                          = $true
            CheckParameter                          = $true
            IgnoreAssignmentOperatorInsideHashTable = $true
        }

        #endregion

        #region Naming and documentation rules

        # Require comment-based help for all functions (block comment style, placed before param block)
        PSProvideCommentHelp = @{
            Enable                  = $true
            ExportedOnly            = $false
            BlockComment            = $true
            VSCodeSnippetCorrection = $false
            Placement               = 'begin'
        }

        # Enforce correct casing for cmdlets, functions, and type names
        PSUseCorrectCasing = @{
            Enable = $true
        }

        # Enforce singular nouns in function names
        PSUseSingularNouns = @{
            Enable = $true
        }

        #endregion

        #region Compatibility rules

        # Enforce PowerShell 5.1 compatible syntax (catch ternary, null-coalescing, pipeline chain operators)
        PSUseCompatibleSyntax = @{
            Enable         = $true
            TargetVersions = @('5.1')
        }

        # Enforce consistent parameter definition style across functions
        PSUseConsistentParametersKind = @{
            Enable = $true
        }

        #endregion
    }
}
