# Microsoft Intune Compliance Policies 

Compliance policies are a key component of Microsoft Intune.

Compliance policies allow you to define the rules and settings that your devices must meet to be considered compliant with your organization's standards and regulations. 

Microsoft Intune compliance policies are important for keeping your organization’s resources safe. These policies are made up of rules and conditions that check the setup of managed devices. By requiring compliance, you can prevent organizational data and resources from being accessed by devices that fail to meet the specified standards.

You can use compliance policies to monitor and report on the compliance state of your devices, and to take actions to remediate any non-compliance issues. 

By implementing compliance policies, you can benefit from the following advantages: 

- You can gain better insight into the security and health of your Windows devices and identify any potential risks or vulnerabilities. 
- You can enforce your organization's policies and requirements for device configuration, encryption, password, firewall, antivirus, and other settings. 
- By enforcing compliance policies, you can protect organizational data and resources from devices that don’t meet the specified requirements
- You can use compliance signals as a factor for your conditional access policies, which control who can access your organization's resources and under what conditions.

By enforcing compliance policies, you can integrate the compliance results from your policies with Microsoft Entra Conditional Access, you can benefit from an extra layer of security. Conditional Access can enforce Microsoft Entra access controls based on a devices current compliance status to help ensure that only devices that are compliant are permitted to access corporate resources.

> [!CAUTION]
> If you use Microsoft Entra Conditional Access, your Conditional Access policies can use the device compliance results to block access to resources from noncompliant devices.

To manage your Windows compliance policy settings, sign in to [Microsoft Intune admin center](https://go.microsoft.com/fwlink/?linkid=2109431 "Microsoft Intune admin center") and go to Devices > Windows > Compliance policies.

Read more [Use compliance policies to set rules for devices you manage with Intune](https://learn.microsoft.com/mem/intune/protect/device-compliance-get-started "Use compliance policies to set rules for devices you manage with Intune").

## Recommendations

One of my recommendations, call it my Best Practices, for creating and managing compliance policies is to use multiple policies that each cover a specific aspect of compliance, rather than using fewer policies that include all the settings.

This approach has several benefits, such as: 

- It allows you to include and exclude policies based on different criteria, such as device type, platform, group, or location. For example, you might want to exclude Windows 365 devices from the disk encryption compliance or similar. By having a separate policy for disk encryption compliance, you can easily exclude those devices without affecting other compliance settings. 
- It makes it easier to troubleshoot and resolve compliance issues, since you can identify which policy is causing non-compliance and take the appropriate action. 
- It reduces the complexity and confusion of managing compliance policies, since you can name and describe each policy according to its purpose and scope. 

Another Best Practice for compliance policies is to assign them to devices rather than users. This is because compliance policies are meant to evaluate the security and health of the device itself, regardless of who is using it. By assigning policies to devices, you can ensure that every device that accesses your organization's resources meets the same standards and expectations. Assigning policies to users can create inconsistencies and gaps in compliance, since users might use different devices with different configurations and settings. 

## Importing and exporting Compliance policies

To help you get started with compliance policies, I have collected the Compliance Polcies I use on a daily basis, these json files that contain the settings and rules for my BEst Practice Compliance Policies. You can download these json files from our GitHub repository and import them into your Intune tenant. This way, you can easily deploy and manage compliance policies for your devices without having to configure them from scratch.

There are several tools that can help you with managing Compliance policies, depending on your needs and preferences. I highly recommend using the [IntuneManagement tool](https://github.com/Micke-K/IntuneManagement/ "IntuneManagement"), a tool that can help you to apply, manage, and monitor a heap of settings and configurations and settings for Microsoft Intune. The tool can be used for importing, exporting, and assignment of policies in bulk. The tool can export and import objects including assignments and support import/export between tenants, creating migration tables during export and use that for importing assignments in other environments. It can create missing groups in the target environment during import.

## Legal and Licensing

This Compliance Policies is intended to serve as a foundation or starting point, and should not be considered 'complete'. It has been made available to facilitate learning, development, and knowledge-sharing among communities.
