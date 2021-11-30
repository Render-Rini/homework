# Introduction
This project creates some Azure resources according with the following requirements:
- A simple Windows VM is deployed and have external File Storage (external mounted Data Disk) mapped. Powershell DSC should be used for VM configuration,
- Azure Blob Storage should be setup in different Azure Region (here VM Snaphots will be backed up),
- Regular VM backup routine (Runbook in Azure Automation Account) is deployed - the routine should be scheduled to run every hour, take the snapshot of running VM and  store it into Blob.

# Get Started
To create those resources in your Azure subscription, please follow the steps below.
- Download the files " main.bicep" and " main.parameters.json" to your work directory.
- Login to your Azure subscription. Use command: ``` Az Login ```
- Create the Resource Group for the deployment. Use command: ``` az group create -l northeurope -n homew ``` This command will create Resource Group "homew" in the NorthEurope Azure region. Please be informed that the Resource Group name "homew" is also used in the Runbook which creates and and copies the snapshots from VM. If you would like to change it this value also should be changed in the Runbook.
- Set the default resource group for the deployment. Use Command: ``` az configure --defaults group=homew ```
- From your working directory run the followinfg command: ``` az deployment group create --template-file main.bicep --parameters main.parameters.json ```
- After a while the resources will be deployed to your Azure Subscription.

# Notes
- There are two external links in the Bicep template. One for the Runbook and the second for the Powershell DSC configuration script. Both are published in this repo.
- You can check if the disk is properly provisioned to the OS of the VM by running Powershell command ``` Get-Disk ``` from the Run Command tile. See image below:
 
 ![RunCommand Image](https://github.com/Render-Rini/homework/blob/main/RunCommand.JPG)
