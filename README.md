# Introduction
This project creates some Azure resources according with the following requirements:
-           A simple Windows VM is deployed and have external File Storage (external mounted Data Disk) mapped,
-           Azure Blob Storage should be setup in different Azure Region (here VM Snaphots will be backed up),
-           Regular VM backup routine (Runbook in Azure Automation Account) is deployed - the routine should be scheduled to run every hour, take the snapshot of running VM and  store it into Blob.

# # Get Started
To create this networking environment in your Azure subscription, please follow the steps below. 
