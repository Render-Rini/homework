### Runbook to create snapshot from OS Disk and copy it to Storage account ###

$method = "SA"
$resourceGroupName = "homew"
$UAMI = "xxx007"
$StorageAccountContainerName = "archive"

# Ensures you do not inherit an AzContext in your runbook
Disable-AzContextAutosave -Scope Process | Out-Null

# Connect using a Managed Service Identity
try {
        $AzureContext = (Connect-AzAccount -Identity).context
    }
catch{
        Write-Output "There is no system-assigned user identity. Aborting."; 
        exit
    }

    # set and store context
$AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription `
    -DefaultProfile $AzureContext

if ($method -eq "SA")
    {
        Write-Output "Using system-assigned managed identity"
    }
elseif ($method -eq "UA")
    {
        Write-Output "Using user-assigned managed identity"

        # Connects using the Managed Service Identity of the named user-assigned managed identity
        $identity = Get-AzUserAssignedIdentity -ResourceGroupName $resourceGroupName `
            -Name $UAMI -DefaultProfile $AzureContext

        # validates assignment only, not perms
        if ((Get-AzAutomationAccount -ResourceGroupName $resourceGroupName `
                -Name $automationAccount `
                -DefaultProfile $AzureContext).Identity.UserAssignedIdentities.Values.PrincipalId.Contains($identity.PrincipalId))
            {
                $AzureContext = (Connect-AzAccount -Identity -AccountId $identity.ClientId).context

                # set and store context
                $AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription -DefaultProfile $AzureContext
            }
        else {
                Write-Output "Invalid or unassigned user-assigned managed identity"
                exit
            }
    }
else {
        Write-Output "Invalid method. Choose UA or SA."
        exit
     }


$location = Get-AzResourceGroup -Name $resourceGroupName  | select-object -expandproperty location
$vminfo = Get-AzVM  | where {$_.Tags['Snapshot'] -eq "True"}
$vmName = $vminfo.Name
$timestamp = Get-Date -f MM-dd-yyyy_HH_mm_ss
$snapshotName = "$vmName$timestamp"

$vm = Get-AzVM `
    -ResourceGroupName $resourceGroupName `
    -Name $vmName

$snapshot =  New-AzSnapshotConfig `
    -SourceUri $vm.StorageProfile.OsDisk.ManagedDisk.Id `
    -Location $location `
    -CreateOption copy

New-AzSnapshot `
    -Snapshot $snapshot `
    -SnapshotName $snapshotName `
    -ResourceGroupName $resourceGroupName

# DESTINATION
$sainfo = Get-AzStorageAccount -ResourceGroupName $resourceGroupName | where {$_.Tags['Snapshot'] -eq "True"}
$StorageAccount = $sainfo.StorageAccountName
$StorageAccountBlob = $StorageAccountContainerName
$storageaccountResourceGroup = $resourceGroupName
$vhdname = "$snapshotName"

#SA_KEY
$StorageAccountKey = (Get-AzStorageAccountKey -Name $StorageAccount -ResourceGroupName $StorageAccountResourceGroup).value[0]
$snapshot = Get-AzSnapshot -ResourceGroupName $SnapshotResourceGroup -SnapshotName $SnapshotName

#GRANTING ACCESS
$snapshotaccess = Grant-AzSnapshotAccess -ResourceGroupName $resourceGroupName -SnapshotName $SnapshotName -DurationInSecond 3600 -Access Read -ErrorAction stop
$DestStorageContext = New-AzStorageContext ???StorageAccountName $storageaccount -StorageAccountKey $StorageAccountKey -ErrorAction stop

### Copy the blob
Start-AzStorageBlobCopy -AbsoluteUri $snapshotaccess.AccessSAS -DestContainer $StorageAccountBlob -DestContext $DestStorageContext -DestBlob "$($vhdname).vhd" -Force -ErrorAction stop