Configuration DiskMgmt5
{

    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'

    ### Node localhost


Script Initialize_Disk
    {
        SetScript =
        {
            $disks = Get-Disk | Where-Object partitionstyle -eq 'raw' | Sort-Object number
            $letters = 70..89 | ForEach-Object { [char]$_ }
            $count = 0
            $labels = "data1","data2"
 
            "Formatting disks.."
            foreach ($disk in $disks) {
            $driveLetter = $letters[$count].ToString()
            $disk |
            Initialize-Disk -PartitionStyle MBR -PassThru |
            New-Partition -UseMaximumSize -DriveLetter $driveLetter |
            Format-Volume -FileSystem NTFS -NewFileSystemLabel $labels[$count] -Confirm:$false -Force
            $count++
        }
                                                            
 
            
 
        }
 
 
        
    TestScript =
    { 
        try 
                {
                    Write-Verbose "Testing if any Raw disks are left"
                    # $Validate = New-Object -ComObject 'AgentConfigManager.MgmtSvcCfg' -ErrorAction SilentlyContinue
                    $Validate = Get-Disk | Where-Object partitionstyle -eq 'raw'
                }
                catch 
                {
                    $ErrorMessage = $_.Exception.Message
                    $ErrorMessage
                }
 
            If (!($Validate -eq $null)) 
            {
                   Write-Verbose "Disks are not initialized"     
                    return $False 
            }
                Else
            {
                    Write-Verbose "Disks are initialized"
                    Return $True
                
            }
    }
 
 
        GetScript = { @{ Result = Get-Disk | Where-Object partitionstyle -eq 'raw' } }
                
    }
}