---
Title: README
Date: March 31, 2025
Author: dotjesper
Status: In development
---

# Windows kaleidoscope

[![Built for Windows 11](https://img.shields.io/badge/Built%20for%20Windows%2011-Yes-blue?style=flat)](https://windows.com/ "Built for Windows 11")
[![Built for Windows 10](https://img.shields.io/badge/Built%20for%20Windows%2010-Yes-blue?style=flat)](https://windows.com/ "Built for Windows 10")
[![Built for Windows Autopilot](https://img.shields.io/badge/Built%20for%20Windows%20Autopilot-Yes-blue?style=flat)](https://docs.microsoft.com/en-us/mem/autopilot/windows-autopilot/ "Windows Autopilot")

[![PSScriptAnalyzer verified](https://img.shields.io/badge/PowerShell%20Script%20Analyzer%20verified-Yes-green?style=flat)](https://learn.microsoft.com/powershell/module/psscriptanalyzer/ "PowerShell Script Analyzer")
[![PowerShell Constrained Language mode verified](https://img.shields.io/badge/PowerShell%20Constrained%20Language%20mode%20verified-Yes-green?style=flat)](https://docs.microsoft.com/powershell/module/microsoft.powershell.core/about/about_language_modes/ "PowerShell Language mode")

This repository contains the source code for the Windows kaleidoscope project.

<img src="./solution/kaleidoscope.png" width="200" title="Windows kaleidoscope logo" >

According to Wikipedia, kaleidoscope is an optical instrument with two or more reflecting surfaces (or mirrors) tilted to each other at an angle, so that one or more (parts of) objects on one end of these mirrors are shown as a regular symmetrical pattern when viewed from the other end, due to repeated reflection

> A kaleidoscope is used for observation of beautiful forms.

The **Windows kaleidoscope** project is exactly that, an optical instrument, to shown device insights as a regular symmetrical pattern adding beautiful forms.

This repository is under development and alive and for the most, kicking - I welcome any feedback or suggestions for improvement. Reach out on [Bluesky](https://bsky.app/profile/dotjesper.bsky.social/ "dotjesper.bsky.social") or [Twitter](https://twitter.com/dotjesper/ "dotjesper"), I read Direct Messages (DMs) and allow them from people I do not follow. For other means of contact, please visit [https://dotjesper.com/contact/](https://dotjesper.com/contact/ "Contact").

Do not hesitate to reach out if issues arise or new functionality and improvement comes to mind.

Feel free to fork and build.

This is a personal development, please respect the community sharing philosophy and be nice!

[![Jesper on Bluesky](https://img.shields.io/badge/follow-@dotjesper.bsky.social-whitesmoke?style=social&logo=bluesky)](https://bsky.app/profile/dotjesper.bsky.social/ "Follow Jesper")

## Requirements

Windows kaleidoscope is developed and tested for Windows 10 22H2 Pro and Enterprise 64-bit and newer and require PowerShell 5.1.

## Repository content

### Content

```
   .
   ├── solution
   |   ├── compliance-policies
   |   ├── custom-script-packages
   |   |   ├── sample
   |   |   ├── windows-edition
   |   |   ├── windows-encryption
   |   |   └── windows-hypervisor
   |   └── scripts-and-remediations
   |       ├── platform-scripts
   |       |   └── sample-script
   |       └── remediations
   │           ├── collect-battery-health
   │           ├── collect-browser-extensions
   │           ├── collect-device-warrenty
   │           ├── collect-firmware-mode
   │           ├── collect-hardrive-health (Coming soon)
   │           ├── collect-hypervisor-presence
   │           ├── collect-last-bootUp-time (Coming soon)
   │           ├── collect-msft-365-apps-update-configuration
   │           ├── collect-msft-defender-bitlocker-encryption-method
   │           ├── collect-msft-defender-bitlocker-encryption-metrics
   │           ├── collect-msft-defender-bitlocker-encryption-report
   │           ├── collect-msft-office-add-ins-health (In exploration)
   │           ├── collect-processor-architecture
   │           ├── collect-windows-eventlog-health (In Preview)
   │           ├── collect-windows-compliance-metrics (Coming soon)
   │           ├── collect-windows-low-disk-space
   │           ├── collect-windows-re-partition-size
   │           ├── collect-windows-system-root
   │           ├── collect-windows-system-stability-index
   │           ├── collect-windows-user-profile-health (In exploration)
   │           ├── invoke-bios-configuration (In developement)
   │           ├── invoke-delete-dublicated-files
   │           ├── invoke-system-file-check (Coming soon)
   │           ├── invoke-winre-update (In Preview)
   │           ├── monitor-additional-lsa-protection
   │           ├── monitor-assoc-for-risky-files
   │           ├── monitor-automatic-logon
   │           ├── monitor-folder-write-access
   │           ├── monitor-Interactive-logon-Message
   │           ├── monitor-onedrive-kfm
   │           ├── monitor-orphaned-windows-update-settings
   │           ├── monitor-posh-execution-policy
   │           ├── monitor-windows-sense-service
   │           ├── monitor-windows-unquoted-service-paths
   │           ├── monitor-windows-update-dynamic-active-hours
   │           └── sample-script
   ├── supporting-scripts
   |   ├── Invoke-RemidiationStatusReport.ps1
   |   └── README.md
   ├── LICENSE
   └── README.md
```

## Disclaimer

This is not an official repository, and is not affiliated with Microsoft, the **Windows kaleidoscope** repository is not affiliated with or endorsed by Microsoft. The names of actual companies and products mentioned herein may be the trademarks of their respective owners. All trademarks are the property of their respective companies.

We do not guarantee the accuracy, completeness, or suitability of the solution in this repository for any specific purpose. We do not assume any liability for any damages, losses, or expenses that may result from the use of the solution. We do not provide any warranty, express or implied, for the solution. We do not endorse or recommend any products, services, or vendors that may be mentioned or linked in the document.

By using the solution, you agree to abide by the terms and conditions of this disclaimer. If you do not agree with the disclaimer, do not use the solution.

THE SOLUTIONS PROVIDED IS PROVIDED ON AN "AS IS" BASIS, WITHOUT ANY WARRANTIES OR REPRESENTATIONS EXPRESS, IMPLIED OR STATUTORY, INCLUDING, WITHOUT LIMITATION WARRANTIES OF QUALITY, PERFORMANCE, NONINFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE. NOR ARE THERE ANY WARRANTIES CREATED BY A COURSE OR DEALING, COURSE OF PERFORMANCE OR TRADE USAGE. FURTHERMORE, THERE ARE NO WARRANTIES THAT THE SOFTWARE WILL MEET YOUR NEEDS OR BE FREE FROM ERRORS, OR THAT THE OPERATION OF THE SOFTWARE WILL BE UNINTERRUPTED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

## Legal and Licensing

**Windows kaleidoscope** is licensed under the [MIT license](./license 'MIT license').

The information and data of this repository and its contents are subject to change at any time without notice to you. This repository and its contents are provided AS IS without warranty of any kind and should not be interpreted as an offer or commitment on the part of the author(s). The descriptions are intended as brief highlights to aid understanding, rather than as thorough coverage.

- You should never assign these policies outside your pilot group.
- You should never import these policies using automatic assignment.
- You should never assign these policies without thoroughly test and validation.

This project is intended to serve as a foundation or starting point and should not be considered 'complete'. It has been made available to facilitate learning, development, and knowledge-sharing among communities. Please note that no liability is assumed for the usage or application of the settings within this project in production tenants.
