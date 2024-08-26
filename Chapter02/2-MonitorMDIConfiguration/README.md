


[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FPacktPublishing%2FMicrosoft-Defender-for-Identity-in-Depth%2Fmain%2FChapter02%2F2-MonitorMDIConfiguration%2Fmain.json)



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