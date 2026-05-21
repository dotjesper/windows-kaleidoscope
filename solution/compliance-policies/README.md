---
Title: README
Date: May 20, 2026
Author: dotjesper
Status: In development
---

# Microsoft Intune compliance policies

Compliance policies are a key component of Microsoft Intune that allow you to define the rules and settings that devices must meet to be considered compliant with your organization's standards and regulations.

Microsoft Intune compliance policies are made up of rules and conditions that check the configuration of managed devices. By requiring compliance, you can prevent organizational data and resources from being accessed by devices that fail to meet the specified standards. You can use compliance policies to monitor and report on the compliance state of your devices and to take actions to remediate any non-compliance issues.

By implementing compliance policies, you can benefit from the following advantages:

- Gain better insight into the security and health of your Windows devices and identify potential risks or vulnerabilities.
- Enforce your organization's policies and requirements for device configuration, encryption, password, firewall, antivirus, and other settings.
- Protect organizational data and resources from devices that do not meet the specified requirements.
- Use compliance signals as a factor for your Conditional Access policies, which control who can access your organization's resources and under what conditions.

By integrating the compliance results from your policies with Microsoft Entra Conditional Access, you benefit from an extra layer of security. Conditional Access can enforce Microsoft Entra access controls based on a device's current compliance status to help ensure that only compliant devices are permitted to access corporate resources.

> [!CAUTION]
> If you use Microsoft Entra Conditional Access, your Conditional Access policies can use the device compliance results to block access to resources from noncompliant devices.

To manage your Windows compliance policy settings, sign in to [Microsoft Intune admin center](https://go.microsoft.com/fwlink/?linkid=2109431 "Microsoft Intune admin center") and go to Devices > Windows > Compliance policies.

For more information, see [Use compliance policies to set rules for devices you manage with Intune](https://learn.microsoft.com/mem/intune/protect/device-compliance-get-started "Use compliance policies to set rules for devices you manage with Intune").

## Folder structure

The compliance policies folder is organized as follows:

```text
 📂 compliance-policies/
  ├─ 📝 README.md
  ├─ 📂 compliance-policies/
  |   ├─ 📋 WSR-C-Windows Compliance - Antivirus and Antispyware settings.json
  |   ├─ 📋 WSR-C-Windows Compliance - Device Health Attestation settings.json
  |   ├─ 📋 WSR-C-Windows Compliance - Microsoft Configuration Manager compliance settings.json
  |   ├─ 📋 WSR-C-Windows Compliance - Microsoft Defender Antimalware settings.json
  |   ├─ 📋 WSR-C-Windows Compliance - Microsoft Defender BitLocker settings.json
  |   ├─ 📋 WSR-C-Windows Compliance - Microsoft Defender Firewall settings.json
  |   ├─ 📋 WSR-C-Windows Compliance - Microsoft Defender for Endpoint Risk settings.json
  |   ├─ 📋 WSR-C-Windows Compliance - Microsoft Defender Secure Boot settings.json
  |   ├─ 📋 WSR-C-Windows Compliance - Trusted Platform Module (TPM) settings.json
  |   ├─ 📋 WSR-C-Windows Compliance - Windows 10 21H2+.json
  |   ├─ 📋 WSR-C-Windows Compliance - Windows 10 22H2+.json
  |   ├─ 📋 WSR-C-Windows Compliance - Windows 11 21H2+.json
  |   ├─ 📋 WSR-C-Windows Compliance - Windows 11 22H2+.json
  |   ├─ 📋 WSR-C-Windows Compliance - Windows 11 23H2+.json
  |   ├─ 📋 WSR-C-Windows Compliance - Windows 11 24H2+.json
  |   └─ 📋 WSR-C-Windows Compliance - Windows 11 25H2+.json
  └─ 📂 custom-script-packages/
      ├─ 📝 README.md
      ├─ 📁 sample/
      ├─ 📁 windows-config-refresh/
      ├─ 📁 windows-edition/
      ├─ 📁 windows-encryption/
      └─ 📁 windows-hypervisor/
```

## Baseline compliance policies

The `compliance-policies/` subfolder contains pre-built Microsoft Graph API policy exports that serve as a baseline for Windows device compliance. Each policy covers a single, focused compliance area and can be imported directly into a Microsoft Intune tenant.

The following baseline policies are included:

| Policy | Description | Key settings |
|:-------|:------------|:-------------|
| Antivirus and Antispyware | Windows Security Center antivirus and antispyware requirements | `antivirusRequired`, `antiSpywareRequired` |
| Device Health Attestation | Device health attestation validation | `bitLockerEnabled`, `secureBootEnabled`, `codeIntegrityEnabled` |
| Microsoft Configuration Manager compliance | Requires device compliance from Microsoft Configuration Manager | `configurationManagerComplianceRequired` |
| Microsoft Defender Antimalware | Microsoft Defender Antivirus protection requirements | `defenderEnabled`, `signatureOutOfDate`, `rtpEnabled` |
| Microsoft Defender BitLocker | BitLocker Drive Encryption requirement | `bitLockerEnabled` |
| Microsoft Defender Firewall | Microsoft Defender Firewall requirements | `activeFirewallRequired` |
| Microsoft Defender for Endpoint Risk | Microsoft Defender for Endpoint threat protection | `deviceThreatProtectionEnabled` |
| Microsoft Defender Secure Boot | Secure Boot validation | `secureBootEnabled` |
| Trusted Platform Module (TPM) | TPM chip requirement | `tpmRequired` |
| Windows 10 21H2+ | Minimum OS version 10.0.19044.0 | `osMinimumVersion` |
| Windows 10 22H2+ | Minimum OS version 10.0.19045.0 | `osMinimumVersion` |
| Windows 11 21H2+ | Minimum OS version 10.0.22000.0 | `osMinimumVersion` |
| Windows 11 22H2+ | Minimum OS version 10.0.22621.0 | `osMinimumVersion` |
| Windows 11 23H2+ | Minimum OS version 10.0.22631.0 | `osMinimumVersion` |
| Windows 11 24H2+ | Minimum OS version 10.0.26100.0 | `osMinimumVersion` |
| Windows 11 25H2+ | Minimum OS version 10.0.26200.0 | `osMinimumVersion` |

## Custom compliance script packages

The `custom-script-packages/` subfolder contains custom compliance discovery scripts that extend Microsoft Intune compliance policies with custom detection logic. Each package includes a PowerShell discovery script and a `settings.json` file that defines the compliance rules evaluated against the script output.

For more information about the available packages, see the [custom-script-packages README](custom-script-packages/README.md).

## Recommendations

One recommendation for creating and managing compliance policies is to use multiple policies that each cover a specific aspect of compliance, rather than using fewer policies that include all the settings.

This approach has several benefits:

- It allows you to include and exclude policies based on different criteria, such as device type, platform, group, or location. For example, you might want to exclude Windows 365 Cloud PC devices from the disk encryption compliance policy. By having a separate policy for disk encryption compliance, you can easily exclude those devices without affecting other compliance settings.
- It makes it easier to troubleshoot and resolve compliance issues, since you can identify which policy is causing non-compliance and take the appropriate action.
- It reduces the complexity and confusion of managing compliance policies, since you can name and describe each policy according to its purpose and scope.

Another recommendation for compliance policies is to assign them to devices rather than users. Compliance policies are meant to evaluate the security and health of the device itself, regardless of who is using it. By assigning policies to devices, you can ensure that every device that accesses your organization's resources meets the same standards and expectations. Assigning policies to users can create inconsistencies and gaps in compliance, since users might use different devices with different configurations and settings.

## Importing and exporting compliance policies

To help you get started with compliance policies, this repository includes pre-built compliance policy exports as JSON files that contain the settings and rules used on a daily basis. You can download these JSON files and import them into your Microsoft Intune tenant. This way, you can easily deploy and manage compliance policies for your devices without having to configure them from scratch.

There are several tools that can help you with managing compliance policies, depending on your needs and preferences. The [IntuneManagement tool](https://github.com/Micke-K/IntuneManagement/ "IntuneManagement") is a recommended option that can help you apply, manage, and monitor settings and configurations for Microsoft Intune. The tool can be used for importing, exporting, and assignment of policies in bulk. It supports import and export between tenants, creating migration tables during export for importing assignments in other environments, and can create missing groups in the target environment during import.

## Legal and licensing

These compliance policies are intended to serve as a foundation or starting point and should not be considered complete. They have been made available to facilitate learning, development, and knowledge-sharing among communities.
