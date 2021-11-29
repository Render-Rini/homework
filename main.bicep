///////////////////////////////// Parameters //////////////////////////////////////////////////////////////

@description('Specifies the location for all resources.')
param location string = resourceGroup().location

@description('The name of the environment. This must be dev, test, or prod.')
@allowed([
  'dev'
  'test'
  'prod'
])
param environmentName string

@description('Tags for the resources')
param resourceTags object

@description('Specifies the administrator username for the Virtual Machine.')
@secure()
param adminUsername string

@description('Specifies the administrator password for the Virtual Machine.')
@secure()
param adminPassword string

@description('Virtual machine size.')
param vmSize string

@description('Specifies the Windows version for the VM. This will pick a fully patched image of this given Windows version.')
@allowed([
  '2016-Datacenter'
  '2019-Datacenter'
])
param windowsOSVersion string

@description('Name of the external data disk')
param ext_disk_name string

/// Automation Account Variables ///
var accountname = 'SnapshotMgmt'
var runbookname = 'CreateSnapshot'
var schedulename = 'SnapshotHourly'
var jobschedulename = guid('anyvH07')

/// VM and Related resources variables ///
var storageAccountName = '${environmentName}${uniqueString(resourceGroup().id)}vm'
var bck_storageAccountName = '${environmentName}${uniqueString(resourceGroup().id)}bck'
var storageAccountSkuName = (environmentName == 'prod') ? 'Standard_GRS' : 'Standard_LRS'
var networkInterfaceName = '${environmentName}-nic'
var vNetAddressPrefix = '10.0.0.0/16'
var vNetSubnetName = 'default'
var vNetSubnetAddressPrefix = '10.0.0.0/24'
var publicIPAddressName = '${environmentName}-pip'
var vmName = '${environmentName}-vm'
var vNetName = '${environmentName}-vnet'
var networkSecurityGroupName = '${environmentName}-NSG'

////////////////////////////// Automation Account resources ////////////////////////////////////

resource autaccount_resource 'Microsoft.Automation/automationAccounts@2021-06-22' = {
  name: accountname
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    disableLocalAuth: false
    sku: {
      name: 'Basic'
    }
    encryption: {
      identity: {}
      keySource: 'Microsoft.Automation'
    }
  }
}

resource autaccount_Azure 'Microsoft.Automation/automationAccounts/connectionTypes@2020-01-13-preview' = {
  parent: autaccount_resource
  name: 'Azure_975'
  properties: {
    isGlobal: false
    fieldDefinitions: {
      AutomationCertificateName: {
        isEncrypted: false
        isOptional: false
        type: 'System.String'
      }
      SubscriptionID: {
        isEncrypted: false
        isOptional: false
        type: 'System.String'
      }
    }
  }
}

resource autaccount_AzureClassicCertificate 'Microsoft.Automation/automationAccounts/connectionTypes@2020-01-13-preview' = {
  parent: autaccount_resource
  name: 'AzureClassicCertificate_975'
  properties: {
    isGlobal: false
    fieldDefinitions: {
      SubscriptionName: {
        isEncrypted: false
        isOptional: false
        type: 'System.String'
      }
      SubscriptionId: {
        isEncrypted: false
        isOptional: false
        type: 'System.String'
      }
      CertificateAssetName: {
        isEncrypted: false
        isOptional: false
        type: 'System.String'
      }
    }
  }
}

resource autaccount_AzureServicePrincipal 'Microsoft.Automation/automationAccounts/connectionTypes@2020-01-13-preview' = {
  parent: autaccount_resource
  name: 'AzureServicePrincipal_975'
  properties: {
    isGlobal: false
    fieldDefinitions: {
      ApplicationId: {
        isEncrypted: false
        isOptional: false
        type: 'System.String'
      }
      TenantId: {
        isEncrypted: false
        isOptional: false
        type: 'System.String'
      }
      CertificateThumbprint: {
        isEncrypted: false
        isOptional: false
        type: 'System.String'
      }
      SubscriptionId: {
        isEncrypted: false
        isOptional: false
        type: 'System.String'
      }
    }
  }
}

resource runbook1 'Microsoft.Automation/automationAccounts/runbooks@2019-06-01' = {
  parent: autaccount_resource
  name: runbookname
  location: location
  properties: {
    runbookType: 'PowerShell'
    logVerbose: false
    logProgress: false
    logActivityTrace: 0
    publishContentLink: {
      uri: 'https://raw.githubusercontent.com/Render-Rini/homework/main/runbook.ps1'
    }
  }
}

resource schedule1 'Microsoft.Automation/automationAccounts/schedules@2020-01-13-preview' = {
  parent: autaccount_resource
  name: schedulename
  properties: {
    startTime: '17:30'
    expiryTime: ''
    interval: 1
    frequency: 'Hour'
    timeZone: 'Europe/Riga'
  }
}

resource link 'Microsoft.Automation/automationAccounts/jobSchedules@2020-01-13-preview' = {
  name: jobschedulename
  parent: autaccount_resource
  dependsOn: [
    runbook1
    schedule1
  ]
  properties: {
    parameters: {}
    runbook: {
      name: runbookname
    }
    schedule: {
      name: schedulename
    }
  }
}

@description('A new GUID used to identify the role assignment')
param roleNameGuid string = newGuid()

//var Owner = '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/8e3af657-a8ff-443c-a75c-2fe8c4bcb635'
var Contributor = '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c'
//var Reader = '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7'

resource roleassignment 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: roleNameGuid
  dependsOn: [
    autaccount_resource
  ]
  properties: {
    principalId: autaccount_resource.identity.principalId
    roleDefinitionId: Contributor
    principalType:'ServicePrincipal'
  }
}

//////////////////////////////////////// VM Related Resources ////////////////////////////////////////////////////////

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: storageAccountSkuName
  }
  kind: 'StorageV2'
  properties: {}
}

resource bck_storageAccount 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: bck_storageAccountName
  location: 'westeurope'
  tags: resourceTags
  sku: {
    name: storageAccountSkuName
  }
  kind: 'StorageV2'
  properties: {}
}

resource bck_storageAccount_BlobService 'Microsoft.Storage/storageAccounts/blobServices@2021-06-01' = {
  parent: bck_storageAccount
  name: 'default'
}

resource archiveContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-06-01' = {
  parent: bck_storageAccount_BlobService
  name: 'archive' 
}

resource publicIPAddress 'Microsoft.Network/publicIPAddresses@2020-06-01' = {
  name: publicIPAddressName
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: [
      {
        name: 'default-allow-3389'
        properties: {
          priority: 1000
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '3389'
          protocol: 'Tcp'
          sourceAddressPrefix: '1.1.1.1'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource vNet 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: vNetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vNetAddressPrefix
      ]
    }
    subnets: [
      {
        name: vNetSubnetName
        properties: {
          addressPrefix: vNetSubnetAddressPrefix
          networkSecurityGroup: {
            id: networkSecurityGroup.id
          }
        }
      }
    ]
  }
}

resource networkInterface 'Microsoft.Network/networkInterfaces@2020-06-01' = {
  name: networkInterfaceName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddress.id
          }
          subnet: {
            id: '${vNet.id}/subnets/${vNetSubnetName}'
          }
        }
      }
    ]
  }
}

resource ext_disk_resource 'Microsoft.Compute/disks@2021-04-01' = {
  name: ext_disk_name
  location: location
  sku: {
    name: 'Premium_LRS'
  }
  properties: {
    creationData: {
      createOption: 'Empty'
    }
    diskSizeGB: 25
    diskIOPSReadWrite: 120
    diskMBpsReadWrite: 25
    encryption: {
      type: 'EncryptionAtRestWithPlatformKey'
    }
    networkAccessPolicy: 'AllowAll'
    tier: 'P4'
  }
}

resource virtualMachine 'Microsoft.Compute/virtualMachines@2020-06-01' = {
  name: vmName
  location: location
  tags: resourceTags
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: windowsOSVersion
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
      dataDisks: [
        {
          lun: 0
          name: ext_disk_name
          createOption: 'Attach'
          caching: 'None'
          writeAcceleratorEnabled: false
          managedDisk: {
            storageAccountType: 'Premium_LRS'
            id: ext_disk_resource.id
          }
          diskSizeGB: 25
          toBeDetached: false
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: storageAccount.properties.primaryEndpoints.blob
      }
    }
  }
}

resource virtualMachine_Powershell_DSC 'Microsoft.Compute/virtualMachines/extensions@2021-07-01' = {
  parent: virtualMachine
  name: 'Microsoft.Powershell.DSC'
  location: location
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.76'
    autoUpgradeMinorVersion: true
    settings: {
      configuration: {
        url: 'https://github.com/Render-Rini/homework/raw/main/DiskMgmt.zip'
        script: 'DiskMgmt.ps1'
        function: 'DiskMgmt'
      }
    }
    protectedSettings: {
      Items: {
        registrationKeyPrivate: listKeys(autaccount_resource.id, '2020-01-13-preview').Keys[0].value
      }
    }
  }
}
