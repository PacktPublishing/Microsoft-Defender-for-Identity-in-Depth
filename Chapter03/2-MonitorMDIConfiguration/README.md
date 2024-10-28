Monitor the MDI configuration report with Azure Monitor Agent, Data Collection Rules (DCR), Data Collection Endpoint (DCE), and cutom table in Log Analytics.

This folder contains the necessary files to monitor the MDI (Microsoft Defender for Identity) configuration.

## Table of Contents

- [Installation](#installation)
- [Usage](#usage)
    - [KQL parser](#kql-parser)
- [Contributing](#contributing)
- [License](#license)

## Installation

To install the solution for monitoring the MDI service, follow these steps:

1. Press the Deploy to Azure button and sign in to Azure with an account that has appropriate permissions to create new resources.

    [![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FPacktPublishing%2FMicrosoft-Defender-for-Identity-in-Depth%2Fmain%2FChapter02%2F2-MonitorMDIConfiguration%2Fmain.json)

2. Verify that the deployment was successful and that you can see all of the resources in your resource group.

## Usage

1. On one of your MDI sensor servers (DC, AD FS, AD CS or Entra Connect) run the [New-MDIConfigCheck.ps1](New-MDIConfigCheck.ps1) script to generate the JSON file that will be sent to Log Analytics.

2. Wait to see if the logs are ingested.

3. Use the KQL parser below to extract the RawData column.

### KQL parser

```kql
MDIConfig_CL
| mv-expand ConfigItem = todynamic(RawData)
| project Configuration = ConfigItem.Configuration,
                    Mode = ConfigItem.Mode,
                    Status = ConfigItem.Status,
                    DisplayName = tostring(ConfigItem.Details.DisplayName),
                    Id = tostring(ConfigItem.Details.Id),
                    GpoStatus = toint(ConfigItem.Details.GpoStatus),
                    RegistryValue = ConfigItem.Details.RegistryValue.value,
                    AuditSettings = ConfigItem.Details.AuditSettings.value,
                    DetailsString = tostring(ConfigItem.Details)
| mv-expand RegistryItem = RegistryValue to typeof(dynamic)
| project Configuration, Mode, Status, DisplayName, Id, GpoStatus, AuditSettings,
                    RegistryKeyName = tostring(RegistryItem.KeyName),
                    RegistryValueName = tostring(RegistryItem.valueName),
                    RegistryValue = tostring(RegistryItem.Value),
                    RegistryValueDisplay = tostring(RegistryItem.valueDisplay),
                    ExpectedRegistryValue = tostring(RegistryItem.ExpectedValue)
| mv-expand AuditItem = todynamic(AuditSettings)
| project Configuration, Mode, Status, DisplayName, Id, GpoStatus,
                    PolicyTarget = tostring(AuditItem.PolicyTarget),
                    SubcategoryName = tostring(AuditItem.SubcategoryName),
                    SettingValue = tostring(AuditItem.SettingValue),
                    ExpectedValue = tostring(AuditItem.ExpectedValue)
```

## Contributing

Contributions are welcome! If you have any improvements or bug fixes, feel free to submit a pull request.

## License

This project is licensed under the [MIT License](LICENSE).
