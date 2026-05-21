# Contributing to Windows kaleidoscope

Thank you for your interest in contributing to **Windows kaleidoscope**! This project is a personal learning platform and open-source tool, and contributions of all kinds are welcome - from bug reports and feature ideas to code improvements and documentation updates.

## How to contribute

There are several ways to contribute to **Windows kaleidoscope**, depending on the type of feedback or change you want to make.

### Reporting issues

If you find a bug or have a feature request, please open an [issue](https://github.com/dotjesper/windows-kaleidoscope/issues) on GitHub. The repository provides structured issue forms to help you provide the right information:

- **[Bug Report](https://github.com/dotjesper/windows-kaleidoscope/issues/new?template=bug_report.yml)** - for reporting bugs or unexpected behavior. The form will guide you through providing reproduction steps, environment details, and log output.
- **[Feature Request](https://github.com/dotjesper/windows-kaleidoscope/issues/new?template=feature_request.yml)** - for suggesting new features or improvements. The form will help you describe the problem, proposed solution, and related module.

### Starting a discussion

For general questions, ideas, or feedback that are not specific bugs or feature requests, consider starting a discussion using [GitHub Discussions](https://github.com/dotjesper/windows-kaleidoscope/discussions). This is the best place to:

- Ask questions about usage or configuration
- Share ideas for new features or improvements
- Discuss best practices for deployment scenarios

### Submitting pull requests

To submit a change, follow these steps:

1. **Fork** the repository and create a new branch from `main`
1. **Create a branch** using the naming convention `feature/short-description` or `fix/short-description`
1. **Make your changes** following the conventions described below
1. **Commit** with a clear, imperative message (e.g., "Add validation to configuration parser")
1. **Test your changes** thoroughly in a non-production environment before submitting
1. **Push your branch** and open a pull request against `main`

When you open a pull request, a template will be provided to help you describe your changes, link related issues, and confirm that your submission meets the project guidelines.

### Pull request guidelines

When submitting a pull request, follow these guidelines:

- Keep changes focused - one pull request per feature or fix
- Follow the existing code style and conventions used in the project
- Ensure your changes are compatible with PowerShell 5.1
- Ensure your changes work in both Full Language mode and Constrained Language mode (CLM) where applicable
- Update documentation if your changes affect usage or parameters
- Do not include sensitive or environment-specific information in your changes
- **No policy enforcement settings** - Windows kaleidoscope is a desired state configuration tool, not a policy enforcement solution. Sample configurations or pull requests that include settings designed to restrict or prevent users from changing their configuration (e.g., policy-based registry keys) are likely to be declined. If you need to enforce policy settings, use a dedicated management solution such as Microsoft Intune or Group Policy.

## Prerequisites

The workspace includes Visual Studio Code tasks that require specific components to be installed and enabled. The following table lists the prerequisites for each task:

| Task | Prerequisite | How to enable or install |
| :--- | :----------- | :----------------------- |
| Launch Windows Sandbox | Windows Sandbox feature enabled | `Enable-WindowsOptionalFeature -Online -FeatureName Containers-DisposableClientVM` |
| Run PSScriptAnalyzer | PSScriptAnalyzer module installed | `Install-Module -Name PSScriptAnalyzer -Scope CurrentUser` |
| Run PSScriptAnalyzer | `.config/` folder with analyzer profiles | Included in the repository - contains `Default.psd1`, `Strict.psd1`, and `CI.psd1` |

## Code style

This project uses a [copilot-instructions.md](./.github/copilot-instructions.md) file to define coding standards, writing style, and terminology conventions for GitHub Copilot. The file is included in the repository and serves as the reference for project conventions. The repository also includes a `.github/instructions/` folder for additional instruction files. These files are excluded from version control because their content is considered highly individual - they should not be copied directly but created in your own context based on your own standards and working style.

Follow these conventions when writing or modifying scripts in this repository:

- Use proper PowerShell cmdlet names instead of aliases (e.g., `Get-ChildItem` instead of `dir`)
- Follow the existing comment and region structure in the scripts
- Use `Write-Output` for detection script output and `Write-Error` for error reporting - do not use `Write-Host` for runtime messages
- Ensure CMTrace/Intune Management Extension log compatibility is maintained
- All code should work under [PowerShell Constrained Language Mode](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_language_modes/) (CLM). Avoid .NET type accelerators (except `[int]`, `[string]`, `[bool]`, `[array]`, `[version]`, `[IntPtr]`), `.GetEnumerator()`, string methods like `.Trim()`, and other constructs blocked by CLM. Use PowerShell operators instead. Where CLM compatibility is not possible, guard the code path with `$script:IsConstrainedLanguageMode` and handle it gracefully (e.g., log a warning and skip the operation)
- Run [PSScriptAnalyzer](https://learn.microsoft.com/powershell/module/psscriptanalyzer/) against your changes before submitting. Install it with `Install-Module -Name PSScriptAnalyzer` and run `Invoke-ScriptAnalyzer -Path .\detect.ps1` to check for issues
- This project uses an [.editorconfig](./.editorconfig) file to enforce consistent formatting across editors. Visual Studio Code users also benefit from the included [.vscode/settings.json](./.vscode/settings.json) workspace settings. The [EditorConfig extension](https://marketplace.visualstudio.com/items?itemName=EditorConfig.EditorConfig) is required for Visual Studio Code to apply `.editorconfig` rules

## Testing

Before submitting any changes, verify the following:

- Test with a valid configuration file (JSON)
- Test in both SYSTEM and USER context where applicable
- Test in both 32-bit and 64-bit PowerShell to verify architecture-dependent behavior
- Verify that the log output is correct and properly formatted
- Use `-Verbose` and `-WhatIf` (where supported) to validate behavior before applying changes

For detailed guidance on testing scripts - including the Visual Studio Code tasks, execution context, Windows Sandbox, script signing, and external logging - see the [Testing and validation](https://github.com/dotjesper/windows-kaleidoscope/wiki/Testing-and-validation) page in the wiki.

## Security

If you discover a security vulnerability in this project, please report it responsibly. Do not open a public issue for security-related concerns. Instead, use [GitHub's private vulnerability reporting](https://github.com/dotjesper/windows-kaleidoscope/security/advisories/new) or reach out directly via [https://dotjesper.com/contact/](https://dotjesper.com/contact/).

## Code of conduct

This project does not have a formal code of conduct, but contributors are expected to respect the community sharing philosophy:

- Be respectful and constructive in all interactions
- Keep discussions focused and on-topic
- Acknowledge that this is an evolving project and be patient with responses

## License

By contributing to **Windows kaleidoscope**, you agree that your contributions will be licensed under the [MIT License](./LICENSE).

## Questions?

If you have questions that are not covered here, reach out on [Bluesky](https://bsky.app/profile/dotjesper.bsky.social/) or visit [https://dotjesper.com/contact/](https://dotjesper.com/contact/).

---

*Page revised: May 20, 2026*
