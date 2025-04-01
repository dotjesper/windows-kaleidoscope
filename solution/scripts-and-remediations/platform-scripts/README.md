# Platform scripts

Platform scripts are scripts that run on devices as part of a device configuration profile. They can be used to perform custom actions, such as configuring settings, installing software, or collecting information.  

I rarely use PowerShell platform scripts on Windows 10/11 devices, which is why this repository is very limited.  

If a PowerShell script is required, I prefer to package PowerShell scripts as Win32 apps, because platform scripts are limited in use and reporting. Some of the reasons are:

- Platform scripts have a maximum size of 200 KB, which can be insufficient for complex or lengthy scripts.
- Platform scripts have a limited ability to handle errors and exceptions, which can cause scripts to fail silently or unpredictably.
- Platform scripts have a limited ability to handle more files, and is restricted to a single PowerShell file, unless you include some download functionality.

By packaging PowerShell scripts as executables, I can overcome these limitations and improve the reliability, usability, and reporting of scripts. I can also leverage the features and benefits of PowerShell, such as the ability to use variables, and error handling, debugging, and logging.

To read more about how to Use PowerShell scripts on Windows 10/11 devices, visit [Use PowerShell scripts on Windows 10/11 devices in Intune](https://learn.microsoft.com/mem/intune/apps/intune-management-extension "Use PowerShell scripts on Windows 10/11 devices in Intune").

For further informarion about creating and assigning PowerShell scripts on Windows 10/11 devices, visit [Create a script policy and assign it](https://learn.microsoft.com/mem/intune/apps/intune-management-extension#create-a-script-policy-and-assign-it "Create a script policy and assign it")

A few words about PowerShell platform scripts on Windows 10/11 devices 

- End users are not required to sign in to the device to execute PowerShell scripts. 
- The Microsoft Intune management extension agent checks after every reboot for any new scripts or changes. If the script fails, the Microsoft Intune management extension agent retries the script three times for the next three consecutive Microsoft Intune management extension agent check-ins.
- For shared devices, the PowerShell script will run for every new user that signs in.
- PowerShell scripts are executed before Win32 apps run. In other words, PowerShell scripts execute first. Then, Win32 apps execute.
- PowerShell scripts time out after 30 minutes.

The Microsoft Intune management extension has the following [prerequisites](https://learn.microsoft.com/mem/intune/apps/intune-management-extension#prerequisites "Prerequisites").
