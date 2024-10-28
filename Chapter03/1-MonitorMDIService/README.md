Monitor the MDI service within Windows with Azure Arc, Azure Monitor Agent, and Data Collection Rules (VM Insight) 

This folder contains the necessary files to monitor the MDI (Microsoft Defender for Identity) service.

## Table of Contents

- [Introduction](#introduction)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Usage](#usage)
- [Contributing](#contributing)
- [License](#license)

## Introduction

The MonitorMDIService folder is part of the Microsoft Defender for Identity in Depth book. It provides the necessary files and instructions to deploy the necessary Azure resources to monitor the MDI service effectively through Azure Monitor (with the Change Tracking and Inventory solution).

## Prerequisites

Before you can start monitoring the MDI service, make sure you have the following prerequisites:

- Microsoft Defender for Identity subscription
- Deployed the MDI sensor to appropriate servers (domain controllers, AD FS, and/or AD CS)
- Access to the MDI portal
- Access to an Azure Subscription

## Installation

To install the solution for monitoring the MDI service, follow these steps:

1. Press the Deploy to Azure button and sign in to Azure with an account that has appropriate permissions to create new resources.

    [![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FPacktPublishing%2FMicrosoft-Defender-for-Identity-in-Depth%2Fmain%2FChapter02%2F1-MonitorMDIService%2Fmain.json)

2. Verify that the deployment was successful and that you can see all of the resources in your resource group.

## Usage

To start monitoring the MDI service via *Change Tracking and Inventory* solution, follow these steps:

1. Make sure that the Change Tracking and Inventory solution is installed on the Log Analytic workspace and that the Data Collection Rule is applied to the servers you listed in the array during the deployment.
2. Wait a few "Microsoft moments".
3. Log in to one of the servers that has the MDI sensor installed, and then stop the MDI service (Azure Advanced Threat Protection Sensor).
 - Start PowerShell as an administrator
 - Type the following in the PowerShell window

```powershell
Stop-Service -Name AATPSensor
```

4. Go back to the Azure portal and to the Log Analytics workspace you deployed earlier.
5. Run the following KQL:

```kql
ConfigurationChange
| where SvcName =~ 'AATPSensor'
```

6. Adjust the query to your needs and then click on **+ New Alert** rule within the Log Analytics pane.
7. Follow the steps on the page to create your own custom alert and be notified when the service stops.

## Contributing

Contributions are welcome! If you have any improvements or bug fixes, feel free to submit a pull request.

## License

This project is licensed under the [MIT License](LICENSE).
